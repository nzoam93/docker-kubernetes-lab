# Prompt the user for their username
read -p "Enter your frontend external IP address: " external_address

# Export the username as an environment variable
export EXTERNAL_ADDRESS=$external_address

# Display a message to the user
echo "Your external IP address '$EXTERNAL_ADDRESS' has been saved as an environment variable."