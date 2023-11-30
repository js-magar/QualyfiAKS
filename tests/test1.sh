#1. Connect to the application front end via the App Gateway public ip
export MSYS_NO_PATHCONV=1
RGName=$1
AppGatewayName=$2

publicIp=$(az network public-ip show -g $RGName -n "pip-$AppGatewayName" --query "ipAddress" --output tsv)
echo $publicIp
openPage=$(start "http://$publicIp/")
$openPage
# ./tests/test1.sh $RGName $AppGatewayName