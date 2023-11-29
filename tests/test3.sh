#3. SSH to a node via the Bastion and the SSH keys
export MSYS_NO_PATHCONV=1
RGName=$1
BastionName=$2
UserName=$3
echo "Testing Bastion use CTRL-D to exit"
vmssID=$(az vmss list --resource-group "MC-$RGName" --query "[0].id" -o tsv)
az network bastion ssh --name $BastionName --resource-group $RGName --target-resource-id "$vmssID/virtualMachines/0" \
 --auth-type ssh-key --username $UserName --ssh-key ./keys/keys
