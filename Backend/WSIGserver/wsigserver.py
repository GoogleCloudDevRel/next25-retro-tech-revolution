#pip install flask
#pip install kafka-python # local
#pip install google-cloud-managedkafka #gcp
#pip install qrcode

###for gcp
#pip install confluent-kafka google-auth urllib3 packaging

from flask import Flask, jsonify, request

import json

import google.auth
import google.auth.transport.urllib3
import urllib3
import confluent_kafka

from kafka import KafkaConsumer, KafkaProducer

####Kafka
KAFKA_SERVER_IP = "bootstrap.game-kafka.us-central1.managedkafka.data-cloud-interactive-demo.cloud.goog"
KAFKA_SERVER_PORT = "9092"

def __init__(self, **config):
    self.credentials, _project = google.auth.default()
    self.http_client = urllib3.PoolManager()
    self.HEADER = json.dumps(dict(typ='JWT', alg='GOOG_OAUTH2_TOKEN'))

def valid_credentials(self):
    if not self.credentials.valid:
      self.credentials.refresh(google.auth.transport.urllib3.Request(self.http_client))
    return self.credentials

def get_jwt(self, creds):
    return json.dumps(
        dict(
            exp=creds.expiry.timestamp(),
            iss='Google',
            iat=datetime.datetime.now(datetime.timezone.utc).timestamp(),
            scope='kafka',
            sub=creds.service_account_email,
        )
    )

def b64_encode(self, source):
    return (
        base64.urlsafe_b64encode(source.encode('utf-8'))
        .decode('utf-8')
        .rstrip('=')
    )

def get_kafka_access_token(self, creds):
    return '.'.join([
      self.b64_encode(self.HEADER),
      self.b64_encode(self.get_jwt(creds)),
      self.b64_encode(creds.token)
    ])

def token(self):
    creds = self.valid_credentials()
    return self.get_kafka_access_token(creds)

def confluent_token(self):
    creds = self.valid_credentials()

    utc_expiry = creds.expiry.replace(tzinfo=datetime.timezone.utc)
    expiry_seconds = (utc_expiry - datetime.datetime.now(datetime.timezone.utc)).total_seconds()

    return self.get_kafka_access_token(creds), time.time() + expiry_seconds

# Confluent does not use a TokenProvider object
# It calls a method
def make_token(args):
  """Method to get the Token"""
  t = TokenProvider()
  token = t.confluent_token()
  return token

kafka_cluster_name ='game-kafka' 
region = 'us-central1'
project_id = 'data-cloud-interactive-demo'
port = '9092'


config = {
    'bootstrap.servers': f'bootstrap.{kafka_cluster_name}.{region}.managedkafka.{project_id}.cloud.goog:{port}',
    'security.protocol': 'SASL_SSL',
    'sasl.mechanisms': 'OAUTHBEARER',
    'oauth_cb': make_token,
}

producer = confluent_kafka.Producer(config)

#send msg to topic
#producer = KafkaProducer(
#    bootstrap_servers=[KAFKA_SERVER_IP + ':'+KAFKA_SERVER_PORT],
#    value_serializer=lambda x: json.dumps(x).encode('utf-8'),
#    security_protocol='SASL_SSL',
#    sasl_oauthbearer_token_endpoint_url=""
#)

#consume msg from a topic
#consumer = KafkaConsumer(
#    #topic,
#    bootstrap_servers=[KAFKA_SERVER_IP + ':'+KAFKA_SERVER_PORT],
#    auto_offset_reset='earliest',
#    value_deserializer=lambda x: json.loads(x.decode('utf-8'))
#)

####Flask
app = Flask(__name__)

@app.route('/kafka', methods=['GET', 'POST'])
def messages():
    #send a msg
    if request.method == 'POST':
        topic = request.form.get('topic')
        content = request.form.get('msg_content')
        print(topic)
        print(content)
        producer.produce(topic, content)
        producer.flush()
        #producer.send(topic, content)
        #producer.flush()
        return jsonify("Sent")

    #retrieve msgs
    #if request.method == 'GET':
    #    topic = request.args.get('topic', default="", type=str)
    #    consumer = KafkaConsumer(topic, auto_offset_reset='earliest',
    #                         bootstrap_servers=[KAFKA_SERVER_IP + ':'+KAFKA_SERVER_PORT], api_version=(0, 10), consumer_timeout_ms=1000)
    #    parsed_records = []
    #    for msg in consumer:
    #        print(msg.value.decode('utf-8'))
    #        parsed_records.append(msg.value.decode('utf-8'))
    #    consumer.close()
    #    return jsonify(parsed_records)

#@app.route('/qrcode', methods=['GET', 'POST'])
#def messages():
#        if request.method == 'GET':
#            return jsonify("myQRCode")

if __name__ == '__main__':
    app.run(debug=False)




##test GET:
#http://127.0.0.1:5000/kafka?topic=retro-attack 

#### test POST
"""
curl -H 'Content-Type: application/x-www-form-urlencoded' \
      -d 'topic=game_signals&msg_content={"topic":"retro-attack"}' \
      -X POST \
      http://127.0.0.1:5000/kafka
"""

"""curl -H 'Content-Type: application/json' \
      -d 'topic=retro-attack&msg_content={ "topic":"retro-attack"}' \
      -X POST \
      http://127.0.0.1:5000/kafka"""


