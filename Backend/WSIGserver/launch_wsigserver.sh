cd /home/
sudo python3 -m venv .venv
source .venv/bin/activate 
export GOOGLE_APPLICATION_CREDENTIALS="/home/rtr-admin/RTR/gcp/data-cloud-interactive-demo-e9d0901373bb.json"
#export GOOGLE_APPLICATION_CREDENTIALS="../../../../../../gcp-service-accounts/data-cloud-interactive-demo-e9d0901373bb.json"
#gcloud config set account game-client@data-cloud-interactive-demo.iam.gserviceaccount.com
cd /home/rtr/next25-retro-tech-revolution/Backend/WSIGserver/
python3 -m wsigserver_pubsub