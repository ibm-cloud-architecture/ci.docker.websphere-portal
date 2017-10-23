./create_namespace.sh wps

#helm delete --purge wps
#helm install --name wps ./wps

helm delete --purge nginx
helm install --name nginx ./wps/charts/nginx
