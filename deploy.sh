# azure-devops-track-aks-exercise-jash
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
#az acr build --registry $ACRNAME --image mcr.microsoft.com/oss/bitnami/redis ./azure-voting-app-redis/azure-vote
az aks get-credentials --resource-group $RGName --name $AKSCLUSTERNAME
kubectl get nodes
az acr list --resource-group $RGName --query "[].{acrLoginServer:loginServer}" --output table
kubectl create namespace production
kubectl apply -f azure-vote.yaml 
kubectl get service azure-vote-front --watch

#az rest --method GET --url "https://management.azure.com/subscriptions/a4c81412-9cb9-4d76-aaa7-14f85696678a/resourceGroups/azure-devops-track-aks-exercise-jash/providers/Microsoft.ContainerRegistry/registries/aksacrjash?api-version=2023-07-01"
#az rest --method GET --url "https://management.azure.com/subscriptions/a4c81412-9cb9-4d76-aaa7-14f85696678a/resourceGroups/azure-devops-track-aks-exercise-abdellah/providers/Microsoft.ContainerRegistry/registries/acrabdellah?api-version=2023-07-01"
#az rest --method GET --url "https://management.azure.com/subscriptions/a4c81412-9cb9-4d76-aaa7-14f85696678a/resourceGroups/azure-devops-track-aks-exercise-sandy/providers/Microsoft.ContainerRegistry/registries/aksacrsandy?api-version=2023-07-01"

# Export your variables
#export rgName="jash-dev"
#export aksName="devaksjash"
#export pipName="dev-pip-jash"
#export appgwVnetName="dev-appgw-vnet-jash"
#export appgwSnetName="dev-appgw-snet-01"
#export location="uksouth" 
#export appgwName="dev-appgw"
#export wafPolicyName="dev-waf-policy"
#export aksVnetName="dev-vnet-jash"
#az network public-ip create -n $pipName -g $rgName -l $location --allocation-method Static --sku Standard
#az network vnet create -n $appgwVnetName -g $rgName -l $location --address-prefix 10.0.0.0/16 --subnet-name $appgwSnetName --subnet-prefix 10.0.0.0/24
#az network application-gateway waf-policy create --name $wafPolicyName --resource-group $rgName
#az network application-gateway create -n $appgwName -l uksouth -g $rgName --sku WAF_v2 --public-ip-address $pipName --vnet-name $appgwVnetName --subnet $appgwSnetName --priority 100 --waf-policy $wafPolicyName
#appgwId=$(az network application-gateway show -n $appgwName -g $rgName -o tsv --query "id")
#az aks enable-addons -n $aksName -g $rgName -a ingress-appgw --appgw-id $appgwId
#aksVnetId=$(az network vnet show -n $aksVnetName -g $rgName -o tsv --query "id")
#az network vnet peering create -n AppGWtoAKSVnetPeering -g $rgName --vnet-name $appgwVnetName --remote-vnet $aksVnetId --allow-vnet-access
#appGWVnetId=$(az network vnet show -n $appgwVnetName -g $rgName -o tsv --query "id")
#az network vnet peering create -n AKStoAppGWVnetPeering -g $rgName --vnet-name $aksVnetName --remote-vnet $appGWVnetId --allow-vnet-access

#appGatewayId=$(az aks show -n $myCluster -g $myResourceGroup -o tsv --query "addonProfiles.ingressApplicationGateway.config.effectiveApplicationGatewayId")
#appGatewaySubnetId=$(az network application-gateway show --ids $appGatewayId -o tsv --query "gatewayIPConfigurations[0].subnet.id")
#agicAddonIdentity=$(az aks show -n $myCluster -g $myResourceGroup -o tsv --query "addonProfiles.ingressApplicationGateway.identity.clientId")
#az role assignment create --assignee $agicAddonIdentity --scope "subscriptions/a4c81412-9cb9-4d76-aaa7-14f85696678a/resourceGroups/azure-devops-track-aks-exercise-jash2/providers/Microsoft.Network/applicationGateways/appGateway-jash-uksouth-001" --role "Network Contributor"
