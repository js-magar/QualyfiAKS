# azure-devops-track-aks-exercise-jash
git clone https://github.com/Azure-Samples/azure-voting-app-redis.git
RGName="azure-devops-track-aks-exercise-jash1"
ACRNAME="aksacrjash"
AKSCLUSTERNAME="aksclusterjash"
ID=$(az ad group list --display-name 'AKS EID Admin Group' --query "[].{id:id}" --output tsv)
ACRROLEDEF=$(az role definition list --name 'AcrPull' --query "[].{name:name}" --output tsv)
READERROLEDEF=$(az role definition list --name 'Reader' --query "[].{name:name}" --output tsv)
CONTRIBUTORROLEDEF=$(az role definition list --name 'Contributor' --query "[].{name:name}" --output tsv)
NETCONTRIBUTORROLEDEF=$(az role definition list --name 'Network Contributor' --query "[].{name:name}" --output tsv)
az group create --name $RGName --location uksouth
#run main
az deployment group create --resource-group $RGName --template-file main.bicep \
 --parameters entraGroupID=$ID acrRoleDefName=$ACRROLEDEF readerRoleDefName=$READERROLEDEF \
 contributorRoleDefName=$CONTRIBUTORROLEDEF netContributorRoleDefName=$NETCONTRIBUTORROLEDEF
#az aks install-cli
# Clone app
#docker compose -f azure-voting-app-redis/docker-compose.yaml up -d   
#docker images
#docker ps
#docker compose down
sleep 5 
az acr show -n $ACRNAME  
az acr list -o table 
az acr login --name 'aksacrjash'
az acr build --registry $ACRNAME --image mcr.microsoft.com/azuredocs/azure-vote-front:v1 ./azure-voting-app-redis/azure-vote
az acr build --registry $ACRNAME --image mcr.microsoft.com/oss/bitnami/redis ./azure-voting-app-redis/azure-vote
az aks get-credentials --resource-group $RGName --name $AKSCLUSTERNAME
kubectl get nodes
az acr list --resource-group $RGName --query "[].{acrLoginServer:loginServer}" --output table
kubectl create namespace production
kubectl apply -f azure-vote.yaml --namespace production
kubectl get service azure-vote-front --watch
