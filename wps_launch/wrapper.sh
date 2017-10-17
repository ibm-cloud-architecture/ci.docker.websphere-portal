#!/bin/bash
opt/IBM/WebSphere/wp_profile/bin/startServer.sh WebSphere_Portal &
tail -f /opt/IBM/WebSphere/wp_profile/logs/WebSphere_Portal/SystemOut.log

