# Prompt the user for their username
read -p "Enter your DockerHub username: " dockerhub_username

# Export the username as an environment variable
export DOCKERHUB_USERNAME=$dockerhub_username

# Display a message to the user
echo "Your username '$DOCKERHUB_USERNAME' has been saved as an environment variable."