## Step 12 (optional): Combining K8s Files Into Single Manifest

If desired, it is possible to combine all of the K8s manifest files into a single file. This has the drawback of creating a somewhat unwieldly file, but the benefit of creating a simple interface since you only have to run a single command in order to get your K8s environment running. 

In order to switch to this single manifest file, we simply create a new file, which we will call *k8s_single_file.yaml* and incorporate all of our previous K8s yaml files into it. Each previously separate yaml file will now be separated by a line containing the characters "---"

```bash
cd ~
dockerhub_username="$DOCKERHUB_USERNAME" #used to store dockerhub_username env variable
cat > k8s_single_file.yaml <<EOF
#db-deployment
apiVersion: apps/v1 
kind: Deployment
metadata:
  name: db-deployment 
spec: 
  replicas: 1
  template: 
    metadata:
      name: db-pod
      labels:
        tier: db 
    spec: 
      containers:
      - name: db-container 
        image: $dockerhub_username/example-app-db
        env: 
        - name: POSTGRES_USER
          value: "myuser"
        - name: POSTGRES_PASSWORD
          value: "mypassword"
        - name: POSTGRES_DB
          value: "mydb" 
        ports: 
        - containerPort: 5432 
  selector: 
    matchLabels:
      tier: db

--- 

#db-service
apiVersion: v1 
kind: Service 
metadata: 
  name: db #the name is called 'db' here in order to match the name specified as the 'host' earlier when we first made our python-api.py file in step 2. These names NEED to match in order for the service to work properly.
spec: 
  type: ClusterIP
  ports: # incoming traffic on this port will be forwarded to the same port on the pods
  - port: 5432 
    targetPort: 5432 
  selector: #the key-value pairs here match the labels from the db-deployment.yaml file
    tier: db 

---

#backend-deployment
apiVersion: apps/v1 
kind: Deployment
metadata:
  name: backend-deployment 
spec: 
  replicas: 1 
  template: 
    metadata:
      name: backend-pod
      labels:
        tier: backend 
    spec: 
      containers:
      - name: backend-container 
        image: $dockerhub_username/example-app-backend 
        ports:
        - containerPort: 5000 
  selector: 
    matchLabels:
      tier: backend

--- 

#backend-service
apiVersion: v1 
kind: Service 
metadata: 
  name: backend #note: our frontend application expects this to be exactly "backend" as we defined in the nginx.conf file.
spec: 
  type: ClusterIP
  ports: 
  - port: 5000
    targetPort: 5000
  selector: #the key-value pairs here match the labels from the backend-deployment.yaml file
    tier: backend 

---

#frontend-deployment
apiVersion: apps/v1 
kind: Deployment
metadata:
  name: frontend-deployment 
spec: 
  replicas: 1
  template: 
    metadata:
      name: frontend-pod
      labels:
        tier: frontend 
    spec: 
      containers:
        - name: frontend-container 
          image: $dockerhub_username/example-app-frontend
          ports:
          - containerPort: 80 
  selector: 
    matchLabels:
      tier: frontend

--- 
#frontend-service
apiVersion: v1 
kind: Service 
metadata: 
  name: frontend
spec: 
  #gives an external IP that is accessible on the internet
  type: LoadBalancer
  ports: 
  - port: 80 
    targetPort: 80
  selector: #the key-value pairs here match the labels from the frontend-deployment.yaml file
    tier: frontend
EOF
```

Now that this file is created, let's use it! First, let's remove the previous deployments, pods, and services so that we can ensure that we are starting fresh with this new single-file deployment.

```bash
cd ~
kubectl delete deployments --all 
kubectl delete svc frontend backend db 
```

After running the previous command, we can ensure that our app is no longer running by going to the quiz application page and refreshing. We should get an error saying *This page isn't working*.

Now let's actually deploy our new K8s manifest file with a single command.

```bash
kubectl create -f k8s_single_file.yaml
```

You should now be able to refresh the quiz page from earlier and see the quiz working as before!
