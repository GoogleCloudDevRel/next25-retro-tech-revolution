# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
####################################################################################


####################################################################################
# Bridge to connect to the different GCP services from our Game
#
# Flask server will run on host='127.0.0.1' and port=5055
#
# Author: Damien Contreras cdamien@google.com
####################################################################################


from flask import Flask, jsonify, request, abort
import os
import io
import json
import time
from google.api_core.exceptions import NotFound
from google.cloud.pubsub import PublisherClient
from google.pubsub_v1.types import Encoding

from google.cloud import pubsub_v1
#from google.api_core.gapic_v1 import client_options
from google.oauth2 import service_account
from google.cloud import storage

#imagen
import base64
from PIL import Image as PIL_Image
from PIL import ImageOps as PIL_ImageOps
import vertexai
from vertexai.preview.vision_models import ImageGenerationModel
from google.api_core.exceptions import InvalidArgument


#bigquery
from google.cloud import bigquery

#ADK / gemini
import asyncio
from google.adk.agents import Agent
#from google.adk.agents.llm_agent import LlmAgent
#from google.adk.models.lite_llm import LiteLlm # For multi-model support
from google.adk.sessions import InMemorySessionService
from google.adk.planners import BuiltInPlanner
from google.adk.tools.mcp_tool.mcp_toolset import (
    MCPToolset,
    SseServerParams,
)
from google.adk.runners import Runner
from google import genai
from google.genai import types # For creating message Content/Parts
from google.genai.types import HttpOptions

from google.adk.agents.callback_context import CallbackContext
from google.adk.models.llm_request import LlmRequest


from google.oauth2 import service_account

#prerequisite:
#increase ulimit -n
#ulimit -n 4096
# add export GOOGLE_APPLICATION_CREDENTIALS
#%pip install --upgrade --quiet google-genai
#pip install --upgrade --user google-cloud-aiplatform
#pip install pillow
#pip install google-cloud-pubsub
#pip install google-cloud-storage
#pip3 install asyncio


##imagen & bigquery
max_imagen_retries = 3
max_bigquery_retries = 6
backoff_factor=2


TOPIC_ID = 'game_signals'
PROJECT_ID = 'data-cloud-interactive-demo'
SERVICE_ACCOUNT_FILE = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')

IMAGE_GENERATION_MODEL = " imagen-4.0-fast-generate-preview-06-06" #"imagen-3.0-fast-generate-001"
BACKSTORY_GENERATION_MODEL = "gemini-2.0-flash-lite-001" #"gemini-2.5-flash-lite-preview-06-17"

#GCS 
SCREENSHOT_BUCKET = "rtr_screenshots"
BACKSTORY_BUCKET="rtr_backstories"

#Agent ADK
AGENT_MODEL = "gemini-2.5-flash"
APP_NAME = "rtr_agent"

#os.environ["GOOGLE_CLOUD_QUOTA_PROJECT"] = PROJECT_ID
os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = 'TRUE'
os.environ["GOOGLE_CLOUD_PROJECT"] = PROJECT_ID
os.environ["GOOGLE_CLOUD_LOCATION"] = "us-central1"

USER_ID = "DEFAULT_USER"
SESSION_ID = "DEFAULT_SESSION"


######
#credentials = ""
#if SERVICE_ACCOUNT_FILE and os.path.exists(SERVICE_ACCOUNT_FILE):
#		credentials = service_account.Credentials.from_service_account_file(
#		SERVICE_ACCOUNT_FILE
#	)

try:
		credentials = service_account.Credentials.from_service_account_file(SERVICE_ACCOUNT_FILE)
		if credentials.service_account_email:
			print(f"Connected as Service Account: {credentials.service_account_email}")
		elif credentials.universe_domain:  # For user accounts
			print(f"Connected as User Account (possibly via gcloud auth login): {credentials.email}")
		else:
			print("Could not determine the specific user or service account from credentials.")
except FileNotFoundError:
		print("error SA file not found")
		raise FileNotFoundError(f"Service account file not found: {SERVICE_ACCOUNT_FILE}")
except Exception as e:
		raise RuntimeError(f"Error loading credentials from {SERVICE_ACCOUNT_FILE}: {e}")
		print("error loading SA file")


######


###########################Pub/Sub###################
def get_publisher_client():
	#credentials = ""
	#if SERVICE_ACCOUNT_FILE and os.path.exists(SERVICE_ACCOUNT_FILE):
	#	credentials = service_account.Credentials.from_service_account_file(
	#	SERVICE_ACCOUNT_FILE
	#)
	#options = client_options.ClientOptions(
	#	api_endpoint='pubsub.googleapis.com:443',
	#	channel_args=(('grpc.max_concurrent_streams', 100),)
	#)
	batch_settings = pubsub_v1.types.BatchSettings(
	max_messages=100,  # Maximum messages per batch
	max_bytes=1024 * 1024,  # Maximum batch size in bytes
	max_latency=10,  # Maximum batch latency in seconds
	)
	return pubsub_v1.PublisherClient(credentials=credentials, batch_settings=batch_settings)


# generate messages
def publishMessage(publisher_client, content):
	try:
		# Get the topic encoding type.
		topic_path = publisher_client.topic_path(PROJECT_ID, TOPIC_ID)

		#topic = publisher_client.get_topic(request={"topic": topic_path})
		message_data = json.dumps(content).encode("utf-8") 
		future = publisher_client.publish(topic_path,data=message_data)
		print(f"Published message ID: {future.result()}")
		return future.result()
	except NotFound:
		print(f"{TOPIC_ID} not found.")

#####pub/sub
publisher_client = get_publisher_client()



###########################BigQuery###################

#bigquery get summary
def get_gemini_summary(session_id):
	query ="""SELECT summary_text 
	FROM `data-cloud-interactive-demo.retro_tech_revolution.game_play_summaries`
	WHERE session_id= '"""+session_id+"""'
	LIMIT 1
	"""

	client = bigquery.Client()
	attempt = 0
	while attempt < max_bigquery_retries:
		query_job = client.query(query)
		results = query_job.result()
		for row in results:
			return str(row['summary_text']) #expect one record only
		attempt +=1
		sleep_time = backoff_factor ** attempt
		time.sleep(sleep_time)
	return "Gemini is gone on vacation! Come back later"

#bigquery get ranking
def get_rank(session_id):
	query = """
				WITH RAW_DATA AS(
			 SELECT 
			    JSON_VALUE(data, '$.session_id') As session_id,
			    JSON_VALUE(data, '$.score') AS score,
			    JSON_VALUE(data, '$.stopwatch') AS stopwatch
			  FROM  `data-cloud-interactive-demo.retro_tech_revolution.raw_game_signals` 
			),
			PlayerMaxScores AS (
			  SELECT 
			    session_id,
			    MAX(score) AS max_score,
			    -- Max sore --> timestamp
			     MAX(CASE WHEN score = (SELECT MAX(score) FROM RAW_DATA t2 
			              WHERE t2.session_id = t1.session_id) 
			        THEN stopwatch
			        END) AS max_score_time
			  FROM 
			    RAW_DATA As t1
			  GROUP BY 
			    session_id
			),
			RankedPlayers AS (
			  SELECT 
			    session_id,
			    max_score,
			    max_score_time,
			    -- Rank players first by max score (descending), then by time (ascending)
			    DENSE_RANK() OVER (
			      ORDER BY 
			        max_score DESC,  -- Higher max score ranks higher
			        max_score_time ASC  -- If max scores are equal, earlier time ranks higher
			    ) AS player_rank
			  FROM 
			    PlayerMaxScores
			)

			SELECT 
			  player_rank
			FROM 
			  RankedPlayers
			WHERE session_id = '"""+session_id+"""'
			ORDER BY 
			  player_rank ASC,
			  max_score DESC,
			  max_score_time ASC LIMIT 1;
	"""
	client = bigquery.Client()
	i = 0
	while i < 6:
		query_job = client.query(query)
		results = query_job.result()
		for row in results:
			return str(row['player_rank']) #expect one record only
		time.sleep(2 * i)
		i += 1
	return "0"


###########################Gemini & Imagen3 to generate the Backstory ###################


#keep the aspect ratio but reduce image to 
def resize_image_maintain_aspect(image_bytes, max_width, max_height):
    # Create an image object from bytes
    image = PIL_Image.open(io.BytesIO(image_bytes))
    
    # Calculate aspect ratio
    original_width, original_height = image.size
    aspect_ratio = original_width / original_height
    
    # Determine new dimensions while maintaining aspect ratio
    if original_width > original_height:
        # Width is the limiting factor
        new_width = max_width
        new_height = int(new_width / aspect_ratio)
    else:
        # Height is the limiting factor
        new_height = max_height
        new_width = int(new_height * aspect_ratio)
    
    # Resize the image
    resized_image = image.resize((new_width, new_height), PIL_Image.LANCZOS)
    
    # Convert to bytes
    output_buffer = io.BytesIO()
    resized_image.save(output_buffer, format=image.format or 'PNG')
    resized_bytes = output_buffer.getvalue()
    
    return resized_image, resized_bytes


#ask Imagen to generate the backstory image
def generate_backstory_image(prompt, session_id):
	#prompt = """
	#16 bits version with tron like neon of a datacenter in the 80s
	#"""
	print("---Calling Imagen3---")

	vertexai.init(project=PROJECT_ID, location="us-central1")
	model = ImageGenerationModel.from_pretrained(IMAGE_GENERATION_MODEL) 
	

	attempt = 0
	while attempt < max_imagen_retries:

			images = model.generate_images(
				prompt=prompt,
				# Optional parameters
				number_of_images=1,
				language="en",
				# You can't use a seed value and watermark at the same time.
				# add_watermark=False,
				#seed=42,
				aspect_ratio="9:16",
				#output_mime_type="image/png",
				safety_filter_level="block_few",
				person_generation="dont_allow"
			)
			print("Received imagen backstory")
			resized_image, resized_bytes = resize_image_maintain_aspect(images[0]._image_bytes, 600, 800)

			base64_bytes = base64.b64encode(resized_bytes)
			base64_encoded = base64_bytes.decode('utf-8')
	
			print(f"Base64 encoded image: {base64_encoded[:100]}...")
	
			## upload to GCS
			upload_backstory_to_gcs(base64_encoded, session_id)

			return base64_encoded


#ask Imagen to generate the backstory story itself
def generate_backstory_story(prompt):
	client = genai.Client(http_options=HttpOptions(api_version="v1"))
	response = client.models.generate_content(
		model=BACKSTORY_GENERATION_MODEL,
		contents=prompt,
	)
	return response.text


###########################Agent: ADK+Gemini###################

class rtr_agent:
    session_service = None
    session = None
    root_agent = None
    runner = None

    def __init__(self):
        asyncio.run(self.async_agent_main())

    async def get_agent_async(self):
        #print(f"Fetched {len(tools)} tools from MCP server.")
        root_agent = Agent(
          model=AGENT_MODEL, # Adjust model name if needed based on availability
          name=APP_NAME,
         instruction=
			"You are a gamer's best friend assisting him in playing a top down video game that takes place in an old datacenter where old technologies like CRTs and Printers have taken over and the player is tasked to first find 2 tools to clean  the datacenter and defeat the final boss."
			"The game is composed of a single level and the user starts without any tool in his posession. Most parties are short 1 to 3 mins"
			"Based on the information provided, give short and concise instructions to the user so that he knows what to do next but without giving away too much and spoil the game:"
			
			"Prepare your answer with a textual help for the first field, a second field that represents the difficulty level of the game from 0 to 2 with 0 being easy and 2 being hard."
			"If you consider that the gamer is not doing well lower the difficulty level, if the gamer is too strong highten the difficulty level." 
			"the last field is the reason why you adjusted the difficulty a certain way, please follow this JSON format {\"help\":\"\", \"difficulty_level\":0, \"reason\":\"\"}"

	
            ,
          #tools=[], # Provide the MCP tools to the ADK agent
          #before_model_callback=clean_image_history,
        )
        return root_agent


    async def call_rtr_agent_async(self, query: str, base64_image, user_id, session_id):
        print("Running agent...")
        content = types.Content(role='user', parts=[types.Part(inline_data=base64_image), types.Part(text=query)])

        final_response_text = "Agent did not produce a final response." # Default

        async for event in self.runner.run_async(user_id=self.session.user_id, session_id=self.session.id, new_message=content):
            # print(f"  [Event] Author: {event.author}, Type: {type(event).__name__}, Final: {event.is_final_response()}, Content: {event.content}")

            # Key Concept: is_final_response() marks the concluding message for the turn.
            if event.is_final_response():
              if event.content and event.content.parts:
                 final_response_text = event.content.parts[0].text
              elif event.actions and event.actions.escalate: # Handle potential errors/escalations
                 final_response_text = f"Agent escalated: {event.error_message or 'No specific message.'}"
              break # Stop processing events once the final response is found
  
        return(f"{final_response_text}")


    def __del__(self):
        print("destroying object")
       # await exit_stack.aclose()





## setup
    async def async_agent_main(self):
        self.session_service = InMemorySessionService()
        # Artifact service might not be needed for this example
        #artifacts_service = InMemoryArtifactService()

        self.session =  await self.session_service.create_session(
                state={},
                app_name=APP_NAME,
                user_id=USER_ID,
                session_id=SESSION_ID
            )
        print(f"Session created: App='{APP_NAME}', User='{USER_ID}', Session='{SESSION_ID}'")
            # Prepare the user's message in ADK format

        self.root_agent = await self.get_agent_async()

        self.runner = Runner(
              app_name=APP_NAME,
              agent=self.root_agent,
             # artifact_service=artifacts_service, # Optional
              session_service=self.session_service,
            )
        print(f"Runner created for agent '{self.runner.agent.name}'.")

##agent instance
my_agent = rtr_agent()


## call to agent
def get_adk_agent_help(user_input, base64_image, user_id, session_id):
     return  asyncio.run( my_agent.call_rtr_agent_async(user_input, base64_image, user_id, session_id) )


###########################GCS###########################


#upload screenshots image to GCP
def upload_screenshot_to_gcs(base64_image, session_id, timestamp_seconds):
	image_data = base64.b64decode(base64_image)
	#timestamp_seconds = int(time.time())
	destination_blob_name = "{}/{}_screenshot_{}.png".format(session_id, session_id, timestamp_seconds) 

	storage_client = storage.Client()
	bucket = storage_client.bucket(SCREENSHOT_BUCKET)
	blob = bucket.blob(destination_blob_name)
	blob.upload_from_string(image_data, content_type="image/png")


#upload backstory to GCP
def upload_backstory_to_gcs(base64_image, session_id):
	image_data = base64.b64decode(base64_image)
	#timestamp_seconds = int(time.time())
	destination_blob_name = "{}_backstory.png".format(session_id) 
	storage_client = storage.Client()
	bucket = storage_client.bucket(BACKSTORY_BUCKET)
	blob = bucket.blob(destination_blob_name)
	blob.upload_from_string(image_data, content_type="image/png")


###########################WSIG Flask Server###########################G
app = Flask(__name__)
@app.route('/backendcomm', methods=['POST'])
def publish_messages():
	#send a msg
	try:
		content = request.get_json()
		if not content:
			return jsonify({"error": "No JSON data provided"}), 400
		#publisher_client = get_publisher_client()
		result = publishMessage(publisher_client, content)
		return jsonify("Sent:" + result)
	except Exception as e:
		return jsonify({
			"success": False,
			"error": str(e)
		}), 500


@app.route('/get_agent_help', methods=['POST'])
def get_agent_help():
		print("Calling ADK")

		data = request.get_json()
		#prompt =  data.get('prompt')
		session_id  = data.get('session_id')
		img_base64 = request.form.get('img_base64')

		
		stopwatch = request.form.get('stopwatch')
		health = request.form.get('health')
		hit_count = request.form.get('hit_count')
		score = request.form.get('score')
		game_difficulty = request.form.get('game_difficulty')

		has_blaster = request.form.get('has_weapon1')
		has_gauntlet = request.form.get('has_weapon2')

		language = str(request.form.get('language'))

		prompt_text = ""
		#user has 2 weapons
		if has_blaster and has_gauntlet:
			#You know that the boss is located on the top right side of the level.
			prompt_text += "The player has both tools and is ready to go meet his destiny\n"
			prompt_text += "Give instructions to the player on how to get to the large room located on the top right where the final boss is located.\n"
			prompt_text += "explain that to defeat the final boss you should use the gauntlet 2000 to create a barrier and therefore avoid being hit by floppy disks.\n"
			prompt_text += "3.5 floppy disks are faster but inflict less damage, larger 5.25 are slower but inflict more damage"
			prompt_text += "moving around would give him enough time to use the blaster  cleaner 80 to shoot at the boss. The boss has 200 of health and can be identified by a blue square"
		elif has_blaster:
			#user has the blaster only
			prompt_text += "The player already has the blaster cleaner 80 but will need to protect himself more if he wants to defeat the final boss.\n"
			prompt_text += "Recommend to the player to go fetch the weapon on the very far right represented by a yellow square. \n"
		elif has_gauntlet:
			#user has the gauntlet
			prompt_text += "The player already has the gauntlet 2000 a power protective tool against various tech notably floppy disks.\n"
			prompt_text += "Recommend to the player to also retrieve a tool for the offense, the mighty blaster 80.\n" 
		else:
			#user has no weapon
			prompt_text += "The player does not currently have any tools to defend itself or get rid of the old techs \n"
			prompt_text += "Recommend to the player to go fetch the weapon closest to where the player started the level which is where the blaster cleaner 80 is located, on the map represented by a yellow square. \n"

		#build prompt from stats of the game
		prompt_text += "Player has been playing for "+str(stopwatch)+"\n" 
		prompt_text += "Player health level is "+str(health)+" out of 200 \n"
		prompt_text += "Player has been hit "+str(hit_count)+" times.\n" 
		prompt_text += "Player score is "+str(score)+".\n"
		prompt_text += "Player current difficulty level is "+str(game_difficulty)+" from 0 to 2 with 0 being easy and 2 being hard \n"
		prompt_text += "Give your answer writting in the following language: "+language

		print("Calling ADK Agent")
		result = get_adk_agent_help(prompt_text, img_base64, "rtr", session_id)
		result = result.replace("```json", "").replace("```", "")
		return result


@app.route('/get_backstory_story', methods=['POST'])
def get_backstory_story():
	print("Generating backstory text")
	data = request.get_json()
	prompt =  data.get('prompt')
	result = generate_backstory_story(prompt)
	print(result)
	return result

@app.route('/get_backstory_image', methods=['POST'])
def get_backstory_image():
	#try:
		print("Generating backstory image")
		data = request.get_json()
		prompt =  data.get('prompt')
		session_id  = data.get('session_id')
		#img_base64 = request.form.get('img_base64')
		result = generate_backstory_image(prompt, session_id)
		return result

@app.route('/get_rank', methods=['POST'])
def get_rank_from_bq():
		print("Fetching rank")
		data = request.get_json()
		session_id  = data.get('session_id')
		return get_rank(session_id)

@app.route('/get_gemini_summary', methods=['POST'])
def get_summary_from_bq():
		print("Fetching summary from BigQuery")
		data = request.get_json()
		session_id  = data.get('session_id')
		return get_gemini_summary(session_id)

@app.route('/publish_screenshot_image', methods=['POST'])
def publish_screenshot():
			print("uploading screenshot to GCS")
			#try:
			data = request.get_json()
			base64_image = data.get('image')
			session_id  = data.get('session_id')
			timestamp_seconds = data.get('timestamp_seconds')
			print("session_id:" + str(session_id))

			if not base64_image:
				return jsonify({'error': 'No image data provided'}), 400

			if ',' in base64_image:
				base64_image = base64_image.split(',')[1]
			
			upload_screenshot_to_gcs(base64_image, session_id, timestamp_seconds)
			return jsonify("Sent")

		#except Exception as e:
		#	return jsonify({'error': str(e)}), 500



	#except Exception as e:
	#	return jsonify({
	#		"success": False,
	#		"error": str(e)
	#	}), 500

#@app.teardown_appcontext
#def shutdown_pubsub_client(error):
#	if hasattr(g, 'publisher'):
#		# Close the publisher client if it exists
#		g.publisher.close()

if __name__ == '__main__':
	app.run(host='127.0.0.1', port=5055, debug=False)
	#app.run(host='0.0.0.0', port=5055, debug=False)
