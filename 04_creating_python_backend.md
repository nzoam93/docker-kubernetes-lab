## Step 2: Creating the Python backend 

Next up, let's create a Python backend that can utilize the database that we just set up in the previous step. This Python backend will serve as our API for our application and will be used to serve up data from the database to our frontend application.

We will make a new folder called *database* and a file within it called *python-api.py*. This Python file utilizes Flask and creates entrypoints at the root (/) as well as at our API entrypoint that our frontend will utilize (*api/questions*). It utilizes *psycopg2.connect* to connect to the PostgreSQL database that we created in the previous step. Explanations for the different steps in the code are provided as comments inside of the code block. Note that we are assigning the database a name of "mydb", a user of "myuser", a password of "mypassword", and a host of "db".

```bash
cd ~
mkdir backend
cd backend
cat > python-api.py <<EOF
from flask import Flask, request, jsonify
import json  
import psycopg2

app = Flask(__name__)

@app.route('/')
def home_page():
    message = 'You are on the / page. Navigate to a different path like api/questions'
    return message

#route for retrieving all questions from the database
@app.route('/api/questions', methods=['GET'])
def return_questions():
    #establishing the connection to the db. Note that the name of the host here ('db') is important and will be used in the docker-compose file later as well as in K8s.
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

#establishing the app to accept incoming requests from all available network interfaces on the machine (whether from the machine itself or devices on the same network). It will be listening on port 5000.
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
EOF
```

