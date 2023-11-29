export MSYS_NO_PATHCONV=1

VALUE=demovalue
SECRET=demosecret
KVName="kv-jash-uksouth-1"
AKSCLUSTERNAME="aksclusterjash"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
az aks get-credentials --resource-group $RGName --name $AKSCLUSTERNAME
az acr list --resource-group $RGName --query "[].{acrLoginServer:loginServer}" --output table
az keyvault secret set --vault-name $KVName --name $SECRET --value $VALUE

AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
CLIENT_ID=$(az aks show -g $RGName -n $AKSCLUSTERNAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)

export yamlSecretProviderClassName='jashspc'
export yamlClientId=$CLIENT_ID
export yamlKeyVaultName=$KVName
export yamlTenantId=$AZURE_TENANT_ID
export yamlKvSecretName=$SECRET
 
kubectl create namespace production
envsubst < yaml/azure-vote.yaml | kubectl apply -f - --namespace production
kubectl apply -f ./yaml/container-azm-ms-agentconfig.yaml
kubectl autoscale deployment azure-vote-front --namespace production --cpu-percent=50 --min=1 --max=10
kubectl get pods --namespace production
#kubectl describe pods --namespace production