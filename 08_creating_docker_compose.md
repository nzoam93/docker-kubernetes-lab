## Step 6: Docker-Compose

In the previous step, we built our Docker images and stored them on Dockerhub. Our next step is to create Docker containers, which is what will actually run our database, backend, and frontend services that we made in the first couple steps of this tutorial! We will create the containers using a *docker-compose.yaml* file that will link the three Docker images together and allow us to run Docker with a single, simple command!

First, we need to install docker-compose itself, which we can do by running the following command. 

```bash
sudo apt install docker-compose -y
```

Now that docker-compose is installed, let's utilize it! We will create a file in our root directory called *docker-compose.yaml*. This file accomplishes several tasks, including:

- linking our three services together (note that all three services are on the *my-network* network)
- utilizing each of our images that we just created
- incorporating environment variables like the postgres environment variable POSTGRES_USER that we configured in step 4
- specifiying the correct ports for our application. Note that the services have a section that looks like *ports -8080:80*. The first number is the port on which we will ultimately access the application (i.e. ETILabs....eticloud.io:**8080**). The second number is the port of the container itself. Since our frontend *nginx.conf* file is configured to listen on port 80, we use 80 as our second number here in the docker-compose file.


```bash
cd ~
dockerhub_username="$DOCKERHUB_USERNAME" #used to store dockerhub_username env variable
cat > docker-compose.yaml <<EOF
version: '3'
services:
  backend:
    image: $dockerhub_username/example-app-backend:latest
    ports:
      - "8081:5000" #This makes the backend container running on port 5000 accessible to the outside world on port 8081
    networks:
      - my-network
    depends_on:
      - db
    restart: on-failure
    # Specify that the backend container depends on the Postgres container
    # This ensures that the Postgres container is built and running before Python tries to access it
    
  frontend:
    image: $dockerhub_username/example-app-frontend:latest 
    ports: 
      - "8080:80" #This makes the frontend container running on port 80 accessible to the outside world on port 8081
    networks:
      - my-network
    depends_on:
      - backend #this ensures that the backend is running before the frontend attempts to use it
    restart: on-failure

  db:
    image: $dockerhub_username/example-app-db:latest
    environment:
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
      POSTGRES_DB: mydb
    #note: the ports section we did for frontend and backend is not necessary here since you are not trying to make the db itself accessible to the outside world
    networks:
      - my-network

networks:
  my-network: #create a network that is shared between the frontend, backend, and database so that they can communicate with one another
EOF
```

With our docker-compose.yaml file built, we can now pull our images from DockerHub and then start all three containers simultaneously with the command "docker-compose up". 

```bash
cd ~
docker-compose pull #pulls the most recently available image from DockerHub
docker-compose up #starts all the services defined in the docker-compose file
```

This starts your Docker containers and you should see a flurry of output from the backend, frontend, and db containers in the terminal! If, in the future you do not want to see this flurry of output, you can run the command "docker-compose up -d" instead and it runs it in the background. 

Now let's see the fruits of our labor. Click [this link](http://location.hostname:8080) and view your application. Congratulations, you have successfully deployed your application on Docker!

In order to stop the Docker containers, press *ctrl+c* to stop the process. Then, run the following command, which will remove the containers. 

```bash
docker-compose down
```

If you wanted to run the containers again, simply run the *docker-compose up* command from before. In the meantime, let's leave the containers in a stopped-and-removed state and begin our foray into Kubernetes!