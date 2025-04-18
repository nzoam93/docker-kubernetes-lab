## Step 8: Using Persistent Volumes 

So far in our application, we have just read information from the database. But what if we wanted to write information to the database? Currently, any changes we make to our database are stored inside of the database container. Therefore, as soon as the container is deleted, so is any data associated with it. 

Additionally, we have another issue that each container is hosting its own database, which would lead to different data when different people write to the database across different pods. This would mean that our database is not consistent from one user to the next, which is not good.

In order to solve these issue, we can use persistent volumes (PV). A persistent volume stores information on the host machine rather than in the container itself.

In order to create a PV, we start the same way as the other K8s objects we have created so far. 

```bash
cd ~
cat > db-pv.yaml <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: my-storage-class
  hostPath:
    path: /data/postgres
EOF
```

This file makes use of a hostPath of /data/postgres. Let's create this on our host. 

```bash
sudo mkdir -p /data/postgres
```

Now that we have set up a persistent volume, we must next create a persistent volume claim (PVC), which will be used eventually by our database in order to utilize the volume itself. Note that most of the spec matches between the PV and the PVC. This is to associate them with one another so that the PVC can utilize the PV that we just made.

```bash
cd ~
cat > db-pvc.yaml <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: my-storage-class
EOF
```

Let's actually create each of these kubernetes objects by running the *create -f* command. 

```bash
kubectl create -f db-pv.yaml
kubectl create -f db-pvc.yaml
```

Now we should be able to see that the PV and PVC are bound together by running the *kubectl get pv* and *kubectl get pvc* commands. Note the status of "bound".

```bash
kubectl get pv
kubectl get pvc
```

Our final step is to integrate this PVC into our db-deployment.yaml file. Let's overwrite our previous db-deployment file with this new file. In this file, the following changes are made. 

- Added *volumeMounts* under the *db-container* section to specify the mount path for the persistent storage.
- Added a *volumes* section at the pod level to define the volume to be used.
- Under the *volumes* section, specified the *persistentVolumeClaim* and referenced the *claimName* of the PVC (*postgres-pvc* in this example, as defined under the PVC metadata).

```bash
cd ~
dockerhub_username="$DOCKERHUB_USERNAME" #used to store dockerhub_username env variable
cat > db-deployment.yaml <<EOF
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
          image: $dockerhub_username/example-app-db:latest
          env:
            - name: POSTGRES_USER
              value: "myuser"
            - name: POSTGRES_PASSWORD
              value: "mypassword"
            - name: POSTGRES_DB
              value: "mydb"
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: postgres-persistent-storage
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: postgres-persistent-storage
          persistentVolumeClaim:
            claimName: postgres-pvc
  selector:
    matchLabels:
      tier: db
EOF
```

In order for our new deployment to take effect, let's delete our previous db-deployment and create a new one with this modified file

```bash
kubectl delete deployments db-deployment
kubectl create -f db-deployment.yaml
```

Now let's actually put it to the test. First, refresh your quiz application in order for the changes to be reflected. Next, utilize the *Add New Question* feature in order to add a new question. Now, if you refresh your application, you should see this question at the end of the list (once you answer the first 5 questions). Good first step, but the real question is if this persists even after you delete the pod or deployment. Let's give it a shot!

```bash
kubectl delete deployments db-deployment
kubectl create -f db-deployment.yaml
```

Refresh your application and see if the question still appears. Nice, you just made use of a persistent volume and persistent volume claim!