# azure-devops-track-aks-exercise-jash
RGName='azure-devops-track-aks-exercise-jash2'
ACRNAME='aksacrjash'
ID=(az ad group list --display-name 'AKS EID Admin Group' --query "[].{id:id}" --output tsv)
az group create --name $RGName --location eastus
#run main
az deployment group create --resource-group $RGName --template-file main.bicep --entraGroupID $ID
# Clone app
#docker compose -f azure-voting-app-redis/docker-compose.yaml up -d   
#docker images
#docker ps
#docker compose down
az acr list -o table 
az acr build --registry 'aksacrjash' --image mcr.microsoft.com/azuredocs/azure-vote-front:v1 ./azure-voting-app-redis/azure-vote
#az acr build --registry 'aksacrjash' --image mcr.microsoft.com/oss/bitnami/redis ./azure-voting-app-redis/azure-vote
#az deployment group create --resource-group $RGName --template-file main.bicep


