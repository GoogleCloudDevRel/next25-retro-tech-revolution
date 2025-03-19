from flask import Flask, jsonify, request, abort
import os
import io
import json
from google.api_core.exceptions import NotFound
from google.cloud.pubsub import PublisherClient
from google.pubsub_v1.types import Encoding

from google.cloud import pubsub_v1
#from google.api_core.gapic_v1 import client_options
from google.oauth2 import service_account


#imagen3
import base64
from PIL import Image as PIL_Image
from PIL import ImageOps as PIL_ImageOps
import vertexai
from vertexai.preview.vision_models import ImageGenerationModel


#prerequisite:
#increase ulimit -n
#ulimit -n 4096
# add export GOOGLE_APPLICATION_CREDENTIALS
#%pip install --upgrade --quiet google-genai
#pip install --upgrade --user google-cloud-aiplatform
#pip install pillow


topic_id = 'game_signals'
project_id = 'data-cloud-interactive-demo'
SERVICE_ACCOUNT_FILE = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')

generation_model = "imagen-3.0-generate-002"
generation_model_fast = "imagen-3.0-fast-generate-001"



def get_publisher_client():
	credentials = ""
	if SERVICE_ACCOUNT_FILE and os.path.exists(SERVICE_ACCOUNT_FILE):
		credentials = service_account.Credentials.from_service_account_file(
		SERVICE_ACCOUNT_FILE
	)
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
		topic_path = publisher_client.topic_path(project_id, topic_id)

		#topic = publisher_client.get_topic(request={"topic": topic_path})
		message_data = json.dumps(content).encode("utf-8") 
		future = publisher_client.publish(topic_path,data=message_data)
		print(f"Published message ID: {future.result()}")
		return future.result()
	except NotFound:
		print(f"{topic_id} not found.")

#####pub/sub
publisher_client = get_publisher_client()


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



def generate_backstory_image(prompt, image=None):
	prompt = """
	16 bits version with tron like neon of a datacenter in the 80s
	"""
	print("---Calling Imagen3---")

	vertexai.init(project=project_id, location="us-central1")
	model = ImageGenerationModel.from_pretrained("imagen-3.0-fast-generate-001")
	images = model.generate_images(
    	prompt=prompt,
    	# Optional parameters
    	number_of_images=1,
    	language="en",
    	# You can't use a seed value and watermark at the same time.
    	# add_watermark=False,
    	# seed=100,
    	aspect_ratio="9:16",
    	#output_mime_type="image/png",
    	safety_filter_level="block_few",
    	person_generation="dont_allow"

	)
	print("got results")
	#images[0].save("../../retroAttack/Game/backstory-images/image.png")
	
	resized_image, resized_bytes = resize_image_maintain_aspect(images[0]._image_bytes, 600, 800)

	base64_bytes = base64.b64encode(resized_bytes)
	base64_encoded = base64_bytes.decode('utf-8')
	
	print(f"Base64 encoded image: {base64_encoded[:100]}...")
	return base64_encoded




####Flask
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


@app.route('/get_backstory_image', methods=['POST'])
def get_backstory_image():
	#try:
		 prompt = request.form.get('prompt')
		 #img_base64 = request.form.get('img_base64')
		 result = generate_backstory_image(prompt)
		 return result
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
	app.run(host='0.0.0.0', port=5055, debug=False)
"""
curl --header 'Content-Type: application/json' \
	--request POST \
	--data '{"topic":"retro-attack"}' \
	http://localhost:5000/backendcomm
"""