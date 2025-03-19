#start stop cluster
minikube start
minikube pause
minikube unpause
minikube stop




#get list of pods
kubectl get po -A



#deploy kafka
kubectl create deployment kafka-cluster --image=apache/kafka:latest


#open port ssh
kubectl expose deployment kafka-cluster --type=NodePort --port=22

#open port kafka
kubectl expose deployment kafka-cluster --type=NodePort --port=9092
kubectl expose pod kafka-cluster-64b7c47bff-plwb5  --port=9092 --target-port=9092

#checkservices
kubectl get services kafka-cluster


#expose port
kubectl port-forward service/kafka-cluster 7022:22

#connect on ssh


#check that pod is running
kubectl get pod kafka-cluster-64b7c47bff-plwb5


#get shell on the container (check name from the list of pods)
kubectl exec --stdin --tty kafka-cluster-64b7c47bff-plwb5 -- /bin/bash


#launch pod
kubectl apply -f kafka-cluster.yaml

#get list of services of a pod
kubectl describe pod kafka-cluster-64b7c47bff-plwb5

########## kafka

#
cd /opt/kafka/bin/

#create topic
./kafka-topics.sh --bootstrap-server localhost:9092 --create --topic retro-attack 

#create test msg
./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic retro-attack 

#read from topic
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic retro-attack --from-beginning



