## Step 11 (optional): Using NodePort instead of LoadBalancer

In the previous section, we utilized a LoadBalancer service to connect our frontend to the outside world. This is perhaps the most common way to achieve this goal and is conveninent since it automatically handles load balancing for you. However, it's also possible to utilize a NodePort service, which is what we will look at in this section. 

A NodePort makes your application that's running on a node (virtual machine in your K8s cluster) accessible on the Internet on a specifed port. As a reminder, you can see the nodes in your cluster by running the following command. You should see that there are 5 nodes (virtual machines) that are ready to serve you. 

```bash
kubectl get nodes -o wide
```

Currently, these nodes are only accessbile internally and do not have a way to communicate with the outside world. When we create a NodePort service, we allow it to be accessible on the Internet on a specified port. You may use any port you would like in the range of 30000-32767. In this example, we will arbitrarily use port 30004. 

First, let's review our current K8s setup. We can run the *kubectl get* command in order to see our services

```bash
kubectl get services -o wide
```

Now, let's edit our frontend service and change it to a NodePort service. To edit a file, we can make use of *vim*. This will open up our file in an editing mode. You will notice that by default you cannot type anything in vim. To enable editing, press the "a" key on your keyboard and you will be able to type! 

```bash
vim frontend-service.yaml
```

We will be changing two main things in our file to make it a NodePort service. The first is that we will change our service type from *LoadBalancer* to *NodePort*. The second change is that we will add another port to the ports array called *nodePort* with a value of 30004. 

The resulting file should look like the example below. When it does, you can save your work by pressing the *esc* key to exit out of editing mode, and then type *:wq* followed by *enter* on the keyboard. The ":" lets you type a command, the "w" is for write so it saves the changes, and the "q" is to quit out of vim.

```
apiVersion: v1 
kind: Service 
metadata: 
  name: frontend 
  labels:
    name: frontend-service 
    app: example-quiz-app
spec: 
  type: NodePort #changed from LoadBalancer
  ports: 
  - port: 80 
    targetPort: 80
    nodePort: 30004 #added this nodeport
  selector:
    app: example-quiz-app 
    tier: frontend 
```

To apply these changes, let's run the kubectl apply command.

```bash
kubectl apply -f frontend-service.yaml
```

Let's take a look at the service we just created. We should see that our frontend service is now a NodePort service that forwards requests from its interal port 80 (which we configured nginx to run on ealier) to port 30004 (which we ust configured it to forward to in the updated service file).

```bash
kubectl get services -o wide 
```

Now let's actually use our NodePort! Let's first refresh ourselves with the information from our nodes. Take note of the IP addresses of the nodes.

```bash
kubectl get nodes -o wide
```

Enter any of the nodes' IP addresses in the following prompt

```bash
cd $HOME/lab
chmod +x node_ip_prompt.sh
source ./node_ip_prompt.sh
```

Let's run a similar Caddy command as earlier to actually connect the URLs. Note now that we are forwarding from the NODE_ADDRESS rather than the external ip address. Also note taht we are using port 30004 since that was the NodePort we defined in our updated service file.

```bash
caddy reverse-proxy --from :8080 --to $NODE_ADDRESS:30004 > /dev/null 2>&1 &
```

Now we can actually go see the result of our work! Click [this link](http://location.hostname:8080) and view your application. Congratulations, you have successfully deployed your application on Kubernetes using NodePort!

