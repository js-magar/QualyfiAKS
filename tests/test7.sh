#7. Connect to a Pod using kubectl bash command
echo "Testing Node use CTRL-D to exit"
names=$(kubectl get pods --namespace production -o name)
first_name=$(echo "$names" | head -n1)
kubectl exec -it $first_name --namespace production -- bash


#Connect to a Node using kubectl bash command
#echo "Testing Node use CTRL-D to exit"
#names=$(kubectl get nodes -o name)
#first_name=$(echo "$names" | head -n1)
#kubectl debug $first_name -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0