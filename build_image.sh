cd IBMWebSpherePortalServerV9.0
docker build --build-arg URL=ftp://anonymous@linux -t portal:v90 . 2>&1 | tee /tmp/build.log
