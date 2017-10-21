#!/bin/bash
/opt/IBM/WebSphere/wp_profile/bin/startServer.sh WebSphere_Portal &
echo Sleeping 2 minutes
sleep 120
tail -f /opt/IBM/WebSphere/wp_profile/logs/WebSphere_Portal/SystemOut.log

