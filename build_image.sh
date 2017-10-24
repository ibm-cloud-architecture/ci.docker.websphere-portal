#cd IBMWebSpherePortalServerV9.0
#docker build --build-arg URL=http://docker/wps_install -t portal:v90.1 . 2>&1 | tee /tmp/build.log

cd wps_launch
docker build -t patrocinio/portal:v90 .
docker push patrocinio/portal:v90