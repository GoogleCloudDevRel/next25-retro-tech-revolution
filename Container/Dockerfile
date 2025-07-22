FROM alpine-nginx-aarch64

#####################################Env preparation


#nginx setup
COPY nginx.conf /etc/nginx/nginx.conf

#install python
ENV PYTHONUNBUFFERED=1

RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools
RUN apk add --update --no-cache python3 py3-pip

#install necessary python libs
RUN pip3 install --upgrade google-genai
RUN pip3 install google-cloud-pubsub
RUN pip3 install --upgrade google-cloud-aiplatform
RUN pip3 install pillow
RUN pip3 install google-cloud-storage
RUN pip3 install flask



RUN ulimit -n 4096




#####################################copy game & WSIG server


#create folders
RUN mkdir -p ~/home/rtr-admin/RTR/gcp/

#create screenshots folder
RUN mkdir -p /home/rtr-admin/.local/share/godot/app_userdata/Retro\ Tech\ Revolution/screenshots/ /home/rtr-admin/RTR/screenshots

#install fonts
#COPY fonts 
#RUN mkdir -p /usr/share/fonts/truetype/google-fonts
#RUN find $PWD/fonts-master/ -name "*.ttf" -exec install -m644 {} /usr/share/fonts/truetype/google-fonts/ \; || return 1


##### add & register JWT certtificate & env settings





#JWT
COPY ../../../gcp-service-accounts/data-cloud-interactive-demo-e9d0901373bb.json /home/rtr-admin/RTR/gcp/
RUN export GOOGLE_APPLICATION_CREDENTIALS="/home/rtr-admin/RTR/gcp/data-cloud-interactive-demo-e9d0901373bb.json"


#run WSIGserver
COPY ../Backend/WSIGserver/wsigserver_pubsub.py /home/RTR/next25-retro-tech-revolution / Backend / WSIGserver /  wsigserver_pubub.py
RUN python3 -m wsigserver_pubsub



####game data
COPY  ../build/web_based/ /usr/share/nginx/html






COPY static-html-directory /usr/share/nginx/html


