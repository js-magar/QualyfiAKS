loadTestResource="jashaksloadtester"
Name="jash"
resourceGroup="azure-devops-track-aks-exercise-$Name-2"
location="uksouth"
testId="jashaksloadtest"
az config set extension.use_dynamic_install=yes_without_prompt
az load create --name $loadTestResource --resource-group $resourceGroup --location $location
az load show --name $loadTestResource --resource-group $resourceGroup

# Create a test
#testPlan="sample.jmx"
#az load test create --load-test-resource  $loadTestResource --test-id $testId  --display-name "My CLI Load Test" --description "Created using Az CLI" --test-plan $testPlan --engine-instances 1 --resource-group $resourceGroup

# Run the test
#testRunId="run_"`date +"%Y%m%d%_H%M%S"`
#displayName="Run"`date +"%Y/%m/%d_%H:%M:%S"`
#az load test-run create --load-test-resource $loadTestResource --test-id $testId --test-run-id $testRunId --display-name $displayName --description "Test run from CLI"

# Get test run client-side metrics
#az load test-run metrics list --load-test-resource $loadTestResource --test-run-id $testRunId --metric-namespace LoadTestRunMetrics
#https://learn.microsoft.com/en-us/azure/load-testing/quickstart-create-and-run-load-test?tabs=azure-cli