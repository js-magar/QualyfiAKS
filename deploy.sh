# azure-devops-track-aks-exercise-jash
ssh-keygen -m PEM -t rsa -b 4096 -f ./keys/keys
sshKey=$(awk '{print $2}' ./keys/keys.pub)
userName="jashusername"

RGName="azure-devops-track-aks-exercise-jash"
ACRNAME="aksacrjash"
AKSCLUSTERNAME="aksclusterjash"
LOCATION="uksouth"
ID=$(az ad group list --display-name 'AKS EID Admin Group' --query "[].{id:id}" --output tsv)
ACRROLEDEF=$(az role definition list --name 'AcrPull' --query "[].{name:name}" --output tsv)
READERROLEDEF=$(az role definition list --name 'Reader' --query "[].{name:name}" --output tsv)
CONTRIBUTORROLEDEF=$(az role definition list --name 'Contributor' --query "[].{name:name}" --output tsv)
NETCONTRIBUTORROLEDEF=$(az role definition list --name 'Network Contributor' --query "[].{name:name}" --output tsv)

az group create --name $RGName --location uksouth
az deployment group create --resource-group $RGName --template-file ./bicep/main.bicep \
 --parameters entraGroupID=$ID acrRoleDefName=$ACRROLEDEF readerRoleDefName=$READERROLEDEF \
 contributorRoleDefName=$CONTRIBUTORROLEDEF netContributorRoleDefName=$NETCONTRIBUTORROLEDEF \
 adminUsername=$userName adminPasOrKey=$sshKey aksClusterName=$AKSCLUSTERNAME acrName=$ACRNAME location=$LOCATION

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
kubectl apply -f ./yaml/azure-vote.yaml --namespace production
kubectl apply -f ./yaml/container-azm-ms-agentconfig.yaml
kubectl autoscale deployment azure-vote-front --namespace production --cpu-percent=50 --min=1 --max=10
