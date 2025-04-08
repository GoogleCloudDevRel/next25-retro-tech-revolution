cd /home/
sudo python3 -m venv .venv
source .venv/bin/activate 
export GOOGLE_APPLICATION_CREDENTIALS="/home/rtr-admin/RTR/gcp/data-cloud-interactive-demo-e9d0901373bb.json"
cd /home/rtr/next25-retro-tech-revolution/Backend/WSIGserver/
python3 -m wsigserver_pubsub