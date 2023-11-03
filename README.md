# QualyfiAKS
Welcome to my project.
In this project I have created a deployment file for a production ‘voting’ application on an AKS cluster with the following spec/requirements

Spec/Requirements: 
Using Azure CLI and Bicep deploy the following: 
Deploy a ‘free’ sku AKS cluster with a public control plane 
Deploy the voting application: https://github.com/Azure-Samples/azure-voting-app-redis 
Use a ‘basic’ sku ACR to store the application in your subscription and deploy from there 
Use Linux node pools using the Mariner OS (Microsoft Linux) 
Create two node pools, one for system and one for the application – use default sku for node pool vm’s which is ‘Standard_DS2_v2’ 
Use ‘containerd’ for the container runtime 
Set the node pools to auto scale using the cluster autoscaler 
Set the pods to auto scale using the horizontal pod autoscaler 
Use an application namespace called ‘production’ 
Use Azure CNI networking with dynamic allocation of IPs and enhanced subnet support 
Use AKS-managed Microsoft Entra integration, use the existing EID group ‘AKS EID Admin Group’ for Azure Kubernetes Service RBAC Cluster Admin access 
Use Azure role-based access control for Kubernetes Authorization 
Disable local user accounts 
Use an Application Gateway for ingress traffic 
Use a NAT gateway for internet egress traffic 
Use a system assigned managed identity for the cluster 
Use the Azure Key Vault provider to secure Kubernetes secrets in AKS, create an example secret and attach it to the backend pods 
Use a ‘standard’ sku Bastion and public/private keys to SSH to the pods 
Enable IP subnet usage monitoring for the cluster 
Enable Container Insights for the cluster 
Enable Prometheus Monitor Metrics and Grafana for the cluster 

Success Criteria:
- [ ] 1. Connect to the application front end via the App Gateway public ip 
- [ ] 2. User node pool running without error with the front and back-end application 
- [ ] 3. SSH to a node via the Bastion and the SSH keys 
- [ ] 4. From the node load a web page via the NAT Gateway 
- [ ] 5. Check cluster autoscaler logs for correct function of the cluster 
- [ ] 6. Confirm the Pod autoscaler is running  
- [ ] 7. Connect to a pod using kubectl bash command 
- [ ] 8. Display the value of the example secret in the pod bash shell 
- [ ] 9. Check Container Insights is running, via the portal 
- [ ] 10. Check Container Insights is running, via the portal 
- [ ] 11. Use Azure Loading Testing to load the AKS cluster resulting in autoscaling of the nodes and pods 
