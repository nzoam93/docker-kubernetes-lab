## Step 10: Using K8s Jobs to Start the database

By default, Kubernetes tries to restart containers when one fails. Indeed, the default policy for k8s objects is "Restart: Always". Sometimes, however, you just want a task to complete and for it not to start again. A *job* in Kubernetes is designed for this purpose: to run a process and then terminate upon completion, never restarting. 

In this example, we will look at using a job in order to populate the postgres database. 

Our example will be utilizing the create_tables.sql file that we created at the beginning of the tutorial to populate this database. Previously, in order to make use of the sql file, we had to include it in a Dockerfile. Since we do not want to make a whole new Dockerfile, we can instead utilize a configmap object in order for our K8s file to read in this SQL file. 

First, let's make sure that our script is in the current directory. 

```bash
cd ~
cat > create-tables.sql <<EOF
CREATE TABLE IF NOT EXISTS questions (
    id SERIAL PRIMARY KEY,
    question VARCHAR(255) NOT NULL,
    answerA VARCHAR(255) NOT NULL,
    answerB VARCHAR(255) NOT NULL,
    answerC VARCHAR(255) NOT NULL,
    answerD VARCHAR(255) NOT NULL,
    correctAnswer VARCHAR(255) NOT NULL
);

INSERT INTO questions(question, answerA, answerB, answerC, answerD, correctAnswer)
VALUES
    ('What is the current year?', '2020', '2023', '2024', '2025', '2023'),
    ('Who is the current president?', 'Bush', 'Obama', 'Trump', 'Biden', 'Biden'),
    ('Which is the largest state?', 'Texas', 'Michigan', 'Califorinia', 'Alaska', 'Alaska'),
    ('Which animal has the highest blood pressure?', 'Giraffe', 'Lion', 'Cheetah', 'Elephant', 'Giraffe'),
    ('Which country produces the most coffee?', 'Denmark', 'Brazil', 'Colombia', 'Venezuela', 'Brazil');
EOF
```

Now, let's create a configmap that utilizes this file. 

```bash
cd ~
kubectl create configmap create-tables.sql --from-file=create-tables.sql
```

Now that that is taken care of, let's utilize the configmap in our job file. 

```bash 
cd ~ 
cat > db-job.yaml <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: init-db-job
spec:
  template:
    spec:
      containers:
        - image: "docker.io/bitnami/postgresql:11.5.0-debian-9-r60"
          name: init-db
          command: ["bin/sh", "-c", "PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -a -f /create-tables-path/create-tables.sql"]
          volumeMounts:
            - name: create-tables
              mountPath: /create-tables-path
          env:
            - name: POSTGRES_HOST
              value: "db"
            - name: POSTGRES_PORT
              value: "5432"
            - name: POSTGRES_DB
              value: "mydb"
            - name: POSTGRES_USER
              value: "myuser"
            - name: POSTGRES_PASSWORD
              value: "mypassword"
      volumes:
        - name: create-tables
          configMap:
            name: create-tables.sql
      restartPolicy: Never
EOF
```

Currently, our job will not have any effect since our database is making use of a volume which stores our previous data (and our current Dockerfile creates the database to begin with anyway). Let's start by creating a new Docker image that does not have the database pre-populated. 

```bash
cd ~
mkdir database-not-poulated
cd database-not-populated
cat > Dockerfile <<EOF
# Start off with the official Postgres image
FROM postgres:13-alpine

# PosgreSQL expects you to have defined a POSTGRES_USER and a POSTGRES_PASSWORD. We are setting these up here. We are also defining the name of our database by setting POSTGRES_DB to mydb

#Set the environment variables for PostgreSQL
ENV POSTGRES_USER=myuser
ENV POSTGRES_PASSWORD=mypassword
ENV POSTGRES_DB=mydb

# Expose the default PostgreSQL port

EXPOSE 5432

# Start the PostgreSQL service

CMD ["postgres"]
EOF
```

Go to Dockerhub and create a new repository called "example_app_db_reg_container" 

Then, run the following prompt to make sure that your Dockerhub username is appropriately stored before continuing.

```bash
cd $HOME/lab
chmod +x username_prompt.sh
source ./username_prompt.sh
```

And now let's build our Docker image. 

```bash
cd ~/database-not-poulated
docker buildx build --platform linux/amd64,linux/arm64 -t $DOCKERHUB_USERNAME/example_app_db_reg_container:latest --push .
```

Let's create a deployment file that makes use of this new database image that has nothing prepopulated onto it.

```bash
cd ~
cat > db-deployment-not-populated.yaml <<EOF
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
          image: nzoam93/example_app_db_reg_container
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
EOF
```

Now, let's actually utilize these files and see them in action. First, let's delete our current db-deployment and deploy our new db-deployment-non-populated file that we just created 

```bash
kubectl delete deployment db-deployment
kubectl create -f db-deployment-not-populated.yaml
```

You should be able to go to the quiz website and you will see nothing. The quiz has not yet been populated. 

Let's now create the job, and after a few seconds (once the job has completed), you should be able to see that the database has been populated and that the website now has the quiz content.  

```bash
kubectl create -f db-job.yaml
```

