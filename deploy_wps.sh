./create_namespace.sh wps

helm delete --purge wps
helm install --name wps ./wps
