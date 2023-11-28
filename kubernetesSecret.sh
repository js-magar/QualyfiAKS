export MSYS_NO_PATHCONV=1

VALUE=demovalue
SECRET=demosecret
KVName="kv-jash-uksouth-1"
AKSCLUSTERNAME="aksclusterjash"
RGName="azure-devops-track-aks-exercise-jash"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
az aks get-credentials --resource-group $RGName --name $AKSCLUSTERNAME
az acr list --resource-group $RGName --query "[].{acrLoginServer:loginServer}" --output table
 
# get your user object id
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
 
# grant yourself access to key vault
az role assignment create --assignee-object-id $USER_OBJECT_ID --role "Key Vault Administrator" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RGName/providers/Microsoft.KeyVault/vaults/$KVName
az keyvault set-policy --name $KVName --object-id $USER_OBJECT_ID --secret-permissions get set delete list backup restore recover purge
ip=$(curl "http://myexternalip.com/raw")
ipaddress=$(echo "$ip" | cut -d '.' -f 1-3)
az keyvault network-rule add --name $KVName --ip-address "$ipaddress.0/24"

# add a secret to the key vault
az keyvault secret set --vault-name $KVName --name $SECRET --value $VALUE

AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
CLIENT_ID=$(az aks show -g $RGName -n $AKSCLUSTERNAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)
 
kubectl create namespace production

cat <<EOF | kubectl apply --namespace production -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: demo-secret
  namespace: production
spec:
  provider: azure
  secretObjects:
  - secretName: demosecret
    type: Opaque
    data:
    - objectName: "demosecret"
      key: demosecret
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: "$CLIENT_ID"
    keyvaultName: "$KVName"
    objects: |
      array:
        - |
          objectName: "demosecret"
          objectType: secret
    tenantId: "$AZURE_TENANT_ID"
EOF

kubectl apply -f ./yaml/azure-vote.yaml --namespace production
kubectl apply -f ./yaml/container-azm-ms-agentconfig.yaml
kubectl autoscale deployment azure-vote-front --namespace production --cpu-percent=50 --min=1 --max=10

#export POD_NAME=$(kubectl get pods -l "app=azure-vote-front" -o jsonpath="{.items[0].metadata.name}")
 
# if this does not work, check the status of the pod
# if still in ContainerCreating there might be an issue
#kubectl exec -it $POD_NAME -- sh
 
#cd /mnt/secret-store
#ls # the file containing the secret is listed
#cat demosecret; echo # demovalue is revealed
 
# echo the value of the environment variable
#echo $demosecret # demovalue is revealed
