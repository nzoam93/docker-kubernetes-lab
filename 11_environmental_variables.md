## Step 9: Using Environmental Variables

Previously, we saw how we could utilize environmental variables that are required by different programs such as the POSTGRES_USER variable that is needed by postgres. But what if we wanted to define these environmental variables ourselves and then use them? This is what we will discuss in this section. 

### Part 1: Frontend configuration

Our frontend has been preconfigured to support a URL ending in the path /backend-statement. The code for what will happen at this path is shown below. As you can see, the frontend expects to grab a statement from the backend at the path */api/backend-statement*, and then print it within a *div* on the page. 

```
import React, { useState, useEffect } from 'react';
import "./BackendStatement.css";

const BackendStatement = () => {
    const [statement, setStatement] = useState("");

    useEffect(() => {
        fetch('/api/backend-statement')
            .then(response => response.json())
            .then(data => setStatement(data))
            .catch(error => console.log(error));
    }, []);

    if(!statement){
        return null;
    }

    return (
        <div>
            {/* note: statement.statement below because statement is an object with a key of statement that I am keying into */}
            <p className='backend-statement'>{statement.statement}</p>
        </div>
    );
};

export default BackendStatement;
```

Normally, this statement would be predefined in the backend and we would have to rebuild the backend Docker image if we wanted to create a new statement. However, in this section, we will utilize environmental variables to create a mutablen statement that we can easily change even AFTER the Docker images have been built. If you do not include environmental variables, then the process to do so is quite long, as you will see since we have to complete this tedious process during the setup for this step.  

Let's get started! First, let's note that our frontend above is fetching to */api/backend-statement*. Since we are using a *"/"* at the beginning of the path, this means that the path is relative, which means it doesn't pull from the backend python file directly. This means we have to proxy to that backend, which we accomplish with our nginx.conf file from earlier. Let's update this file to include our new */api/backend-statement* route. Now it will proxy correctly to our backend service called *backend* at the port 5000, which is the port Python is configured to listen on.

```bash
cd ~/frontend
cat > nginx.conf <<EOF
server {
    listen 80;
    server_name any-name-here;

    location /api/questions {
        proxy_pass http://backend:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /api/backend-statement {
        proxy_pass http://backend:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
    }
}
EOF
```

Since we changed our frontend configuration, we will have to rebuild our frontend Docker image. This is simple to do and we can run the same *docker build* command as before. 

Run the following prompt to make sure that your Dockerhub username is appropriately stored before continuing.

```bash
cd $HOME/lab
chmod +x username_prompt.sh
source ./username_prompt.sh
```

And now let's actually update our frontend Docker image.

```bash
cd ~/frontend
docker buildx build --platform linux/amd64,linux/arm64 -t $DOCKERHUB_USERNAME/example-app-frontend:latest --push .
```

### Part 2: Backend Configuration

Next, we need to update our backend python_api.py file to expect a new route at api/backend-statement. This route does two things. The first line gets the backend statement variable if it exists from an environmental variable set in K8s (otherwise it outputs the second argument of 'Default backend statement'). The second line returns this as a JSON object to the frontend. Note that this process utilizes *os* so we need to include it at the top of the file along with the rest of our inclusions for Python. 

```bash
cd ~/backend
cat > python-api.py <<EOF
from flask import Flask, request, jsonify
import json  
import psycopg2
import os

app = Flask(__name__)

@app.route('/')
def home_page():
    message = 'You are on the / page. Navigate to a different path like api/questions'
    return message

#route for retrieving all questions from the database
@app.route('/api/questions', methods=['GET'])
def return_questions():
    #establishing the connection to the db. Note that the host is 'db' because that will be the name of the service in the docker-compose file
    conn = psycopg2.connect(
        database="mydb", user='myuser', password='mypassword', host='db', port= '5432')
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM questions") #SQL query to get all the questions
    data = cursor.fetchall() #stores the questions in a variable called data
    
    #parsing the data from postgres and returning it as JSON
    columns = ('id', 'question', 'answerA', 'answerB', 'answerC', 'answerD', 'correctAnswer')
    results = {}
    i = 1
    for row in data:
        question = dict(zip(columns, row))
        results[str(i)] = question
        i += 1
    return json.dumps(results, indent=2)

#route for posting a question to the database
@app.route('/api/questions', methods=['POST'])
def create_question():
    # Get the data from the request
    data = request.json

    question_title = data['questionTitle']
    answer_a = data['answerA']
    answer_b = data['answerB']
    answer_c = data['answerC']
    answer_d = data['answerD']
    correct_answer = data['correctAnswer']

    # Connect to the PostgreSQL database
    conn = psycopg2.connect(
        database="mydb", user='myuser', password='mypassword', host='db', port='5432')
    cursor = conn.cursor()

    # Insert the data into the questions table
    cursor.execute(
        "INSERT INTO questions (question, answerA, answerB, answerC, answerD, correctAnswer) "
        "VALUES ( %s, %s, %s, %s, %s, %s)",
        (question_title, answer_a, answer_b, answer_c, answer_d, correct_answer)
    )

    # Commit the transaction and close the database connection
    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({'message': 'Question created successfully'})

#HERE IS THE NEW ROUTE
@app.route('/api/backend-statement')
def get_backend_statement():
    statement = os.environ.get('BACKEND_STATEMENT', 'Default backend statement')
    return jsonify({'statement': statement})

#establishing the app to accept incoming requests from all available network interfaces on the machine (whether from the machine itself or devices on the same network). It will be listening on port 5000.
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
EOF
```

Since we updated our backend, we need to now update our backend Docker image. This is simple to do and we can run the same *docker build* command as before. 

```bash
cd ~/backend
docker buildx build --platform linux/amd64,linux/arm64 -t $DOCKERHUB_USERNAME/example-app-backend:latest --push .
```

### Part 3: Using Environmental Variables in K8s

Now it's time to actually utilize our environmental variables in our K8s file. Let's alter our backend-deployment.yaml file to include these variables in the container section of the file. 

```bash
dockerhub_username="$DOCKERHUB_USERNAME" #used to store dockerhub_username env variable
cat > backend-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  #the name of the deployment
  name: backend-deployment
spec:
  #how many backend pods we want to create
  replicas: 1
  template:
    metadata:
      name: backend-pod
      labels:
        tier: backend
    spec:
      containers:
      - name: backend-container
        image: nzoam93/example-app-backend #the image we created earlier
        ports:
        - containerPort: 5000 #because backend is listening on port 5000
        # THIS PART IS WHAT IS NEW
        env:
        - name: BACKEND_STATEMENT
          value: "Hello, and welcome to the app! This statement is is set by an environment variable"
  selector:
    #needs to match the label from template > metadata > label above
    matchLabels:
      tier: backend
EOF
```

### Part 4: Seeing the Results

Okay, now we can finally see the results of our work. Let's first delete the previous frontend and backend deployments, which were using the outdated Docker images. Then, let's create new deployments, which will automatically pull from the latest version of our Docker images. 

```bash
cd ~
kubectl delete deployments backend-deployment frontend-deployment
kubectl create -f backend-deployment.yaml
kubectl create -f frontend-deployment.yaml
```

Now let’s see the fruits of our labor. Click [this link](http://location.hostname:8080) and view your application. So far, nothing should be different. However, now let's go to our new frontend path at */backend-statement* and you should see the backend statement defined in our environmental variable. (The resulting url should now look something like http://eti-lab-9de5755.demos.eticloud.io:8080/backend-statement).

Now, if we wanted to update this statement, the only thing we would have to update is the backend-deployment.yaml file. We would not need to rebuild any Docker images and the whole process would be much shorter. 


