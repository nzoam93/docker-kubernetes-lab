## Step 1: Creating a PostgreSQL Database

Our first step in the process will be to create a database, which will store our questions and multiple-choice answers for the quiz. We will utilize a postgreSQL database for this project, and will create the database ourselves from scratch. We will make a new folder called *db* and a file within it called *create_tables.sql* with a script to create the database tables, written in sql.

Note that in the following command, as well as most commands in this tutorial, there is a line like "*cat > create_tables.sql <<EOF*". This creates a file called *create_tables.sql* filled with the content of everything between the *EOF*s at the beginning and end of the command. 

```bash
mkdir database
cd database
cat > create_tables.sql <<EOF
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

    