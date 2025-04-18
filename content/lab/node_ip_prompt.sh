# Prompt the user for their username
read -p "Enter any of your nodes' IP addresses: " node_address

# Export the username as an environment variable
export NODE_ADDRESS=$node_address

# Display a message to the user
echo "Your node IP address '$NODE_ADDRESS' has been saved as an environment variable."