#!/usr/bin/env bash
########################################################################
## Following parameters are used:
## $1 --> Database type ("db2")
## $2 --> Number of instances
########################################################################
echo "Parameter \$1 is: ${1}"
echo "Parameter \$2 is: ${2}"
xxDBTYPE=
xxJMSHOST=
xxJMSPORT=
xxLDAPTYPE=
xxCLONEID=
xxLDAPSUFFIX="dc=docker,dc=container"
xxLDAPPORT=389
xxUSELDAPS="false"
xxLDAPHOST="tds.docker.container"
xxDB2HOST="db2.docker.container"
xxISSHAREDFARM="false"
xxISFARMMASTER="false"
xxISFARMWORKER="false"
xxISFARMSUPPORTER="false"
xxNUMDBINSTANCES=1
xxEXITONPORTALSTOP="true"
xxPORTPREFIX=300
xxJMSNODENAME="wpNode"
xxNOPORTALSTART="false"
xxLDAPWAITINTERVALS=30
xxDB2WAITINTERVALS=30

xxProfileDir="/opt/IBM/WebSphere/wp_profile"
xxSYSTEMPDIR=${xxProfileDir}
xxStatusFile="${xxProfileDir}/customizations/customization_status.txt"
xxCellName="wpCell"
xxDefaultPassword="start123."
xxLdapWasAdminId="wasadmin"
xxLdapWpAdminId="wpadmin"
xxLdapWasAdmins="wasadmins"
xxLdapWpAdmins="wpadmins"
xxFileWasAdminId="wpsadmin"
xxFileWpAdminId="wpsadmin"
xxCurMsgType=
xxStatusVal=
#############################################
## This script becomes /bin/startContainer.sh
#############################################
if [[ -f ${xxProfileDir}/logs/debugStartup ]] ; then
	set -x
fi
################################################################################################
## Print an error message ......
################################################################################################
__errorMsg()
{
	if [[ ! -n ${xxCurMsgType} || ${xxCurMsgType} != "E" ]] ; then
		__printErrorHeader
		echo "Host: $(hostname)"
		xxCurMsgType="E"
	fi
	echo "ERROR: $(date +"%Y:%m:%d %T %Z"): ${1}"
	## __printErrorHeader
}
################################################################################################
## Print an informational message ......
################################################################################################
__infoMsg()
{
	if [[ ! -n ${xxCurMsgType} || ${xxCurMsgType} != "I" ]] ; then
		__printHeaderSeperator
		echo "Host: $(hostname)"
		xxCurMsgType="I"
	fi
	echo "INFO: $(date +"%Y:%m:%d %T %Z"): ${1}"

}
################################################################################################
## Print a header for an error Message ......
################################################################################################
__printErrorHeader()
{
	echo "========= E R R O R ================== E R R O R ================== E R R O R ========="
}
################################################################################################
## Print a header for an error Message ......
################################################################################################
__printHeaderSeperator()
{
	echo "======================================================================================="
}
################################################################################################
## Print a debug message ......
################################################################################################
__debugMsg()
{
	if [[ ! -n ${xxCurMsgType} || ${xxCurMsgType} != "D" ]] ; then
		__printHeaderSeperator
		echo "Host: $(hostname)"
		xxCurMsgType="D"
	fi
	echo "DEBUG: $(date +"%Y:%m:%d %T %Z"): ${1}"

}
################################################################################################
## Assign parameter values to the script variables ....
################################################################################################
__processArg ()
{
  terminate=
  extraShift=

  case ${1} in
     -dbType)                 	xxDBTYPE=${2} ; extraShift=1 ;;
     -numInstances)             xxNUMDBINSTANCES=${2} ; extraShift=1  ;;
     -exitOnPortalStop)         xxEXITONPORTALSTOP=$(echo ${2} | tr [:upper:] [:lower:]) ; extraShift=1  ;;
		 -db2host)									xxDB2HOST=${2} ; extraShift=1  ;;
     -farmMaster)								xxISFARMMASTER=$(echo ${2} | tr [:upper:] [:lower:]) ; extraShift=1  ;;
     -sharedFarm)								xxISSHAREDFARM=$(echo ${2} | tr [:upper:] [:lower:]) ; extraShift=1  ;;
     -farmWorker)								xxISFARMWORKER=$(echo ${2} | tr [:upper:] [:lower:]) ; extraShift=1  ;;
     -farmSupporter)						xxISFARMSUPPORTER=$(echo ${2} | tr [:upper:] [:lower:]) ; extraShift=1  ;;
     -sysTempDir)								xxSYSTEMPDIR=${2} ; extraShift=1  ;;
     -jmsHost)               		xxJMSHOST=${2} ; extraShift=1  ;;
     -jmsPort)               		xxJMSPORT=$(echo ${2} | sed 's/[^0-9]*//g') ; extraShift=1  ;;
		 -portPrefix)               xxPORTPREFIX=$(echo ${2} | sed 's/[^0-9]*//g') ; extraShift=1  ;;
     -noPortalStart)						xxNOPORTALSTART=$(echo ${2} | tr [:upper:] [:lower:]) ; extraShift=1  ;;
     -ldapType)									xxLDAPTYPE=$(echo ${2} | tr [:lower:] [:upper:]) ; extraShift=1  ;;
		 -ldapSuffix)								xxLDAPSUFFIX=${2} ; extraShift=1  ;;
		 -ldapPort)									xxLDAPPORT=$(echo ${2} | sed 's/[^0-9]*//g') ; extraShift=1  ;;
		 -ldapSsl)									xxUSELDAPS=$(echo ${2} | tr [:upper:] [:lower:]) ; extraShift=1  ;;
		 -ldapHost)									xxLDAPHOST=${2} ; extraShift=1  ;;
		 -ldapWaitIntervals)				xxLDAPWAITINTERVALS=$(echo ${2} | sed 's/[^0-9]*//g') ; extraShift=1  ;;
		 -db2WaitIntervals)					xxDB2WAITINTERVALS=$(echo ${2} | sed 's/[^0-9]*//g') ; extraShift=1  ;;
     -cloneId)									xxCLONEID=${2} ; extraShift=1  ;;
     *)                         __errorMsg "Unsupported parameter \"${1}\" passed. Exiting ..."
                                terminate=1
																;;
  esac
}
################################################################################################
## Initiailization tasks ......
##
## Note: This include requires the function __processArg in the including script
################################################################################################
__init()
{

  while [[ $# -gt 0 ]]
  do
    __processArg $1 $2
    if [[ -n "$terminate" ]] ; then
      return 1
    fi

    shift
    if [[ -n "$extraShift" ]] ; then
      if [[ $# -gt 0 ]] ; then shift ; fi
    fi
  done
}
################################################################################################
## Update the status of the customization progress for a status literal to true
## $1 --> status literal to set
## $2 --> value to set. If "" --> "true"
## NOTE: Any changes here --> Update custom_wp85_Setup.sh as well!!
################################################################################################
__setStepStatus()
{
	local statusVar=${1}
	local statusVal=${2:-true}
	## Create the directory of the status file if needed
	mkdir -p $(dirname ${xxStatusFile})
	## Create the file if it does not exist
	if [[ ! -f ${xxStatusFile} ]] ; then
		touch ${xxStatusFile}
  fi
  ##
  ## Add status as false if not yet in the file
  cat ${xxStatusFile} | grep -v ^# | grep -v ^$ | grep ${statusVar} || echo "${statusVar}=false" >> ${xxStatusFile}
  sed -i s#${statusVar}=.*#${statusVar}=${statusVal}#g ${xxStatusFile}
}
################################################################################################
## Checks the status for a specific literal. Returns 0 if the status is true; 1 otherwise
## $1 --> status literal to check
## NOTE: Any changes here --> Update custom_wp85_Setup.sh as well!!
################################################################################################
__stepIsSet()
{
	local statusVar=${1}
	local tmpVar
	## Create the file if it does not exist
	if [[ ! -f ${xxStatusFile} ]] ; then
		mkdir -p $(dirname ${xxStatusFile})
		touch ${xxStatusFile}
  fi
  ##
  ## Check the status file if the value is true
  tmpVar=$(cat ${xxStatusFile} | grep -v ^# | grep -v ^$ | grep ${statusVar} | cut -d= -f2-)
  if [[ "${tmpVar}." == "true." ]] ; then
  	return 0
  else
  	return 1
  fi
}
################################################################################################
## Retrieves the status value and sets the Variable "xxStatusVal" with the value
## $1 --> status literal to retrieve
## NOTE: Any changes here --> Update custom_wp85_Setup.sh as well!!
################################################################################################
__setStepVal()
{
	local statusVar=${1}
	##
	xxStatusVal=
	## Create the file if it does not exist
	if [[ ! -f ${xxStatusFile} ]] ; then
		mkdir -p $(dirname ${xxStatusFile})
		touch ${xxStatusFile}
	else
	  ##
	  ## Check the status file set the variable xxStatusVal to the property value
	  xxStatusVal=$(cat ${xxStatusFile} | grep -v ^# | grep -v ^$ | grep ${statusVar} | cut -d= -f2-)
  fi
}
################################################################
## Wait fot DB2 to become active
##
## This functionm waits max. a limited number of seconds for DB2
## to become active (-db2WaitIntervals * 6 seconds)
#################################################################
__waitForDb2()
{
	local MAXRETRY=${xxDB2WAITINTERVALS}
	local WAITTIME=6
	local TGTDOMAIN=$(hostname | sed "s/^[^\.][^\.]*\.//")
	local TGTPORT=60${xxPortNum}00

  local i=0
  local rc

  while [[ ${i} -lt ${MAXRETRY} ]] ; do
    nc -4 -c "cat /etc/hosts" ${xxDB2HOST} ${TGTPORT} > /dev/null 2>&1
    rc=$?
    if [[ ${rc} -eq 0 ]] ; then
      return 0
    else
      sleep ${WAITTIME}
      let "i=i+1"
      __infoMsg "Retry #${i} to wait for the database"
    fi
  done
  __errorMsg "Stopped waiting for the database to become active ..."

  return 1
}
################################################################
## Wait fot LDAP Server to become active
##
## This functionm waits max. 180 seconds for LDAP to become active
#################################################################
__waitForLDAP()
{
	local MAXRETRY=${xxLDAPWAITINTERVALS}
	local WAITTIME=6

  local i=0
  local rc

  while [[ ${i} -lt ${MAXRETRY} ]] ; do
		##
		## Check for LDAP Server's availability
		nc -4 -c "cat /etc/hosts" ${xxLDAPHOST} ${xxLDAPPORT} > /dev/null 2>&1
		rc=$?
    if [[ ${rc} -eq 0 ]] ; then
      return 0
    else
      sleep ${WAITTIME}
      let "i=i+1"
      __infoMsg "Retry #${i} to wait for the LDAP Server ${xxLDAPHOST}:${xxLDAPPORT}"
    fi
  done
  __errorMsg "Stopped waiting for the database to become active ..."

  return 1
}
####################################################################################
## Check if required and run the DB2 database transfer
####################################################################################
__checkRunDB2Transfer()
{
	if [[ "${xxDBTYPE}." == "db2." && ! -f ${xxProfileDir}/properties/.dbxfer_done ]] ; then
	  __infoMsg "db2 database transfer was not yet done ... doing it now"
 	  __infoMsg "Unpacking setup scripts"
		cd /tmp/dbxfer && \
  	unzip -o ./docker_db_transfer_WorkflowInstanceScriptsAll.zip && \
  	find . -name "*.sh" -exec chmod +x {} \; &&\
	  __infoMsg "Setting hostname ${xxDB2HOST} for DB2 server" && \
		sed -i s#db2.docker.container#${xxDB2HOST}#g *.wfi && \
		sed -i s#db2.docker.container#${xxDB2HOST}#g properties/*.properties && \
		__setStepStatus "db2.host.name" ${xxDB2HOST} && \
	  __infoMsg "Starting database transfer to host ${xxDB2HOST} ..." && \
		sh -x ./scripts/SetupDatabase.sh && \
		sh -x ./scripts/StopPortalServer.sh && \
		sh -x ./scripts/ValidateDatabase.sh && \
		sh -x ./scripts/DatabaseTransfer.sh && \
		sh -x ./scripts/GrantRuntimeUserPrivs.sh  && \
		sh -x ./scripts/ConfigureDb2ForLargeFileHandling.sh && \
		sed -i s#ReplaceWithYourPassword#${xxDefaultPassword}#g ${xxProfileDir}/ConfigEngine/properties/wkplc_dbdomain.properties && \
		sed -i s#"^\(.*\)\.DbPassword=.*"#\\1\.DbPassword=${xxDefaultPassword}#g ${xxProfileDir}/ConfigEngine/properties/wkplc_dbdomain.properties && \
		sed -i s#"^\(.*\)\.DbRuntimePassword=.*"#\\1\.DbRuntimePassword=${xxDefaultPassword}#g ${xxProfileDir}/ConfigEngine/properties/wkplc_dbdomain.properties && \
		sed -i s#"^\(.*\)\.DBA\.DbPassword=.*"#\\1\.DBA\.DbPassword=${xxDefaultPassword}#g ${xxProfileDir}/ConfigEngine/properties/wkplc_dbdomain.properties && \
		sh -x ./scripts/StartPortalServer.sh && \
		${xxProfileDir}/ConfigEngine/ConfigEngine.sh action-clean-scheduled-tasks && \
		${xxProfileDir}/ConfigEngine/ConfigEngine.sh stop-portal-server && \
		touch ${xxProfileDir}/properties/.dbxfer_done || return 1
	fi
}
####################################################################################
## Check if required and run the setup of LDAP user registry
####################################################################################
__checkRunLDAPRegistry()
{
	if [[ "${xxLDAPTYPE}." == "TDS." && ! -f ${xxProfileDir}/properties/.tds_setup_done ]] ; then
	  __infoMsg "Setup of TDS-LDAP user registry was not yet done ... doing it now"
 	  __infoMsg "Unpacking setup scripts"
		cd /tmp/tdsxfer && \
  	unzip -o ./docker_TDS_Setup_LDAP_WorkflowInstanceScriptsAll.zip && \
  	find . -name "*.sh" -exec chmod +x {} \; &&\
	  __infoMsg "Replacing variables in setup scripts and property files ..." && \
		cd /tmp/tdsxfer && \
		sed -i s#@@LDAPHOST@@#${xxLDAPHOST}#g properties/*.properties && \
		sed -i s#@@LDAPHOST@@#${xxLDAPHOST}#g scripts/*.sh && \
		sed -i s#@@PASSWORD@@#${xxDefaultPassword}#g properties/*.properties && \
		sed -i s#@@PASSWORD@@#${xxDefaultPassword}#g scripts/*.sh && \
		sed -i s#@@SUFFIX@@#${xxLDAPSUFFIX}#g properties/*.properties && \
		sed -i s#@@SUFFIX@@#${xxLDAPSUFFIX}#g scripts/*.sh && \
		sed -i s#@@WPADMINID@@#${xxFileWpAdminId}#g properties/*.properties && \
		sed -i s#@@WPADMINID@@#${xxFileWpAdminId}#g scripts/*.sh && \
		sed -i s#@@WASADMINID@@#${xxFileWasAdminId}#g properties/*.properties && \
		sed -i s#@@WASADMINID@@#${xxFileWasAdminId}#g scripts/*.sh && \
		sed -i s#@@LDAPWPADMINS@@#${xxLdapWpAdmins}#g properties/*.properties && \
		sed -i s#@@LDAPWASADMINS@@#${xxLdapWasAdmins}#g properties/*.properties && \
		sed -i s#@@LDAPWPADMINID@@#${xxLdapWpAdminId}#g properties/*.properties && \
		sed -i s#@@LDAPWPADMINID@@#${xxLdapWpAdminId}#g scripts/*.sh && \
		sed -i s#@@LDAPWASADMINID@@#${xxLdapWasAdminId}#g properties/*.properties && \
		sed -i s#@@LDAPWASADMINID@@#${xxLdapWasAdminId}#g scripts/*.sh && \
		sed -i s#@@LDAPPORT@@#${xxLDAPPORT}#g properties/*.properties && \
		sed -i s#@@LDAPPORT@@#${xxLDAPPORT}#g scripts/*.sh && \
		sed -i s#@@LDAPTYPE@@#${xxLDAPTYPE}#g properties/*.properties && \
		sed -i s#@@LDAPTYPE@@#${xxLDAPTYPE}#g scripts/*.sh && \
		sed -i s#@@LDAPS@@#${xxUSELDAPS}#g properties/*.properties && \
		sed -i s#@@LDAPS@@#${xxUSELDAPS}#g scripts/*.sh && \
	  __infoMsg "Starting setup of LDAP user registry with host ${xxLDAPHOST} ..." && \
		sh -x ./scripts/ValidateFederatedLDAP.sh && \
		sh -x ./scripts/EnableFederatedLDAPSecurity.sh && \
		sh -x ./scripts/ReregisterSchedulerTasks.sh && \
		sh -x ./scripts/ChangeWPAdminUser.sh && \
		sh -x ./scripts/ChangeWASAdminUser.sh && \
		sh -x ./scripts/SetEntityTypes.sh  && \
		sh -x ./scripts/RecycleAfterSecurityChangeFirst.sh && \
		sh -x ./scripts/UpdateSearchAdminUser.sh && \
		sh -x ./scripts/RecycleAfterSecurityChange.sh && \
		sh -x ./scripts/ValidateFederatedLDAPAttributes.sh && \
		sh -x ./scripts/RunWcmAdminTaskMemberFixer.sh && \
		sh -x ./scripts/StopPortalServer.sh && \
		sed -i s#ReplaceWithYourPassword#${xxDefaultPassword}#g ${xxProfileDir}/ConfigEngine/properties/wkplc_dbdomain.properties && \
		sed -i s#"^WasUserid=.*"#WasUserid=${xxLdapWasAdminId}#g ${xxProfileDir}/ConfigEngine/properties/wkplc.properties && \
		sed -i s#"^WasPassword=.*"#WasPassword=${xxDefaultPassword}#g ${xxProfileDir}/ConfigEngine/properties/wkplc.properties && \
		sed -i s#"^PortalAdminId=.*"#PortalAdminId=${xxLdapWpAdminId}#g ${xxProfileDir}/ConfigEngine/properties/wkplc.properties && \
		sed -i s#"^PortalAdminPwd=.*"#PortalAdminPwd=${xxDefaultPassword}#g ${xxProfileDir}/ConfigEngine/properties/wkplc.properties && \
		sed -i s#"^com.ibm.SOAP.loginUserid=.*"#com.ibm.SOAP.loginUserid=${xxLdapWasAdminId}#g ${xxProfileDir}/properties/soap.client.props && \
		sed -i s#"^com.ibm.SOAP.loginPassword=.*"#com.ibm.SOAP.loginPassword=${xxDefaultPassword}#g ${xxProfileDir}/properties/soap.client.props && \
		__setStepStatus "tds.host.name" ${xxLDAPHOST} && \
		__setStepStatus "tds.port" ${xxLDAPPORT} && \
		touch ${xxProfileDir}/properties/.tds_setup_done || return 1
	fi
}
#####################################################################################
## Run a CF apply if required. Only need to do that if it is NOT a shared farm or if
## it is a shared farm and the master setup
######################################################################################
__checkCFApply()
{
	if [[ "${xxISSHAREDFARM}." != "true." || "${xxISFARMMASTER}." == "true." && "${xxISSHAREDFARM}." == "true."   ]] ; then
		productFixLevel=$(grep fixlevel  /opt/IBM/WebSphere/PortalServer/wps.properties | cut -d= -f2 | tr -d [:alpha:])
		profileFixLevel=$(grep fixlevel  ${xxProfileDir}/PortalServer/wps.properties | cut -d= -f2 | tr -d [:alpha:])
		__infoMsg "----------------------------------------------------------------------------"
		__infoMsg "productFixLevel=CF${productFixLevel} ; profileFixLevel=CF${profileFixLevel}"
		__infoMsg "----------------------------------------------------------------------------"
		if [[ "${productFixLevel}" -gt "${profileFixLevel}" ]] ; then
			__infoMsg "==============================================================================================="
			__infoMsg "Different fix levels between product and profile --> applying ${productFixLevel} to the profile"
			__infoMsg "==============================================================================================="
			sh ${xxProfileDir}/PortalServer/bin/applyCF.sh || return 1
			sh ${xxProfileDir}/ConfigEngine/ConfigEngine.sh stop-portal-server
		else
			if [[ "${productFixLevel}" -lt "${profileFixLevel}" ]] ; then
				__errorMsg "Portal profile is at CF${profileFixLevel} while the product is on CF${productFixLevel} only"
				__errorMsg "Terminating ..."
				return 1
			fi
		fi
	fi
}
################################################################################################
## Get the file which need to be copied to the <portal_home>/shared/app directory
## NOTE: Any changes here --> Update custom_wp85_Setup.sh as well!!
################################################################################################
__getSharedAppFiles()
{
	local rc

	sh -x ${xxProfileDir}/customizations/updateSharedAppJars.sh
	rc=$?
	return ${rc}
}
################################################################################################
## Creates the ports file to modify the server ports if needed.
## $1 --> 3 digit port prefix
## $2 --> outfile
################################################################################################
__createPortsFile()
{
	local portPrefix=${1}
	local outFile=${2}

	cat << EOPF > ${outFile}
BOOTSTRAP_ADDRESS=${portPrefix}32
SOAP_CONNECTOR_ADDRESS=${portPrefix}33
ORB_LISTENER_ADDRESS=${portPrefix}34
SAS_SSL_SERVERAUTH_LISTENER_ADDRESS=${portPrefix}35
CSIV2_SSL_SERVERAUTH_LISTENER_ADDRESS=${portPrefix}36
CSIV2_SSL_MUTUALAUTH_LISTENER_ADDRESS=${portPrefix}37
WC_adminhost=${portPrefix}38
WC_defaulthost=${portPrefix}39
DCS_UNICAST_ADDRESS=${portPrefix}40
WC_adminhost_secure=${portPrefix}41
WC_defaulthost_secure=${portPrefix}42
SIP_DEFAULTHOST=${portPrefix}43
SIP_DEFAULTHOST_SECURE=${portPrefix}44
OVERLAY_UDP_LISTENER_ADDRESS=${portPrefix}45
OVERLAY_TCP_LISTENER_ADDRESS=${portPrefix}46
IPC_CONNECTOR_ADDRESS=${portPrefix}47
SIB_ENDPOINT_ADDRESS=${portPrefix}48
SIB_ENDPOINT_SECURE_ADDRESS=${portPrefix}49
SIB_MQ_ENDPOINT_ADDRESS=${portPrefix}50
SIB_MQ_ENDPOINT_SECURE_ADDRESS=${portPrefix}51
EOPF

}
################################################################################################
## Check whatever can be checked .....
################################################################################################
__check()
{
	local rc
	##
	## Expand the port prefix for the WAS container to 3 digits
	if [[ ${xxPORTPREFIX} -lt 10 ]] ; then
		((xxPORTPREFIX = xxPORTPREFIX*10))
	fi
	if [[ ${xxPORTPREFIX} -lt 100 ]] ; then
		((xxPORTPREFIX = xxPORTPREFIX*10))
	fi
	if [[ ${xxPORTPREFIX} -gt 640 ]] ; then
	  __errorMsg "The port number prefix for the Portal server ${xxPORTPREFIX} is too big. Must be <= 640"
	  return 1
	fi
	##
	## FarmMaster requires a JMS-Host + JMS Port
	if [[ "${xxISFARMMASTER}." == "true." ]] ; then
		if [[ "${xxJMSHOST}." == "." ]] ; then
			__errorMsg "JMS hostname must be provided when running as farm master"
			return 1
		fi
		if [[ "${xxJMSPORT}." == "." ]] ; then
			__errorMsg "JMS bootstrap port must be provided when running as farm master"
			return 1
		fi
	fi
	##
	## Setup LDAP security?
	if [[ "${xxLDAPTYPE}." != "." ]] ; then
		if [[ "${xxLDAPTYPE}." != "TDS." ]] ; then
			__errorMsg "Unsupported LDAP Type specified"
			return 1
		fi
	fi

	return 0
}
################################################################################################
## Run a ConfigEngine task to modify the ports of the server + manual fix. We don't change ports
## if this is a shared farm setup and it's not the master
################################################################################################
__setWpPorts()
{
	local currentPort=
	local targetPort=${xxPORTPREFIX}
	local TMPDIR2=/tmp/XXX-$(od -N8 -tu /dev/urandom | awk 'NR==1 {print $2} {}')

	if [[ "${xxISSHAREDFARM}." != "true." || "${xxISFARMMASTER}." == "true." && "${xxISSHAREDFARM}." == "true."   ]] ; then
		__setStepVal "portal.server.port.prefix"
		if [[ -n  ${xxStatusVal} ]] ; then
			currentPort=$(echo ${xxStatusVal} | sed 's/[^0-9]*//g')
		else
			currentPort=0
		fi

		if [[ ${currentPort} -ne ${targetPort} ]] ; then
			##
			## Create the target ports file
			__createPortsFile ${targetPort} ${TMPDIR2}
			##
			## Run ConfigEngine task to modify the ports
			__infoMsg "Modifying server ports to start with ${targetPort} ..."
			${xxProfileDir}/ConfigEngine/ConfigEngine.sh modify-ports-by-portsfile -DPortsFile=${TMPDIR2} -DModifyPortsServer=WebSphere_Portal || return 1
			##
			## Need to clean scheduled tasks as otherwise wrong ports are used and the reregister-scheduler-tasks
			## which is executed during LDAP setup fails due to incorrect port number beeing used (still 10036)
			${xxProfileDir}/ConfigEngine/ConfigEngine.sh action-clean-scheduled-tasks || return 1
			__setStepStatus "portal.server.port.prefix" ${targetPort} || return 1
		fi
	fi

	return 0
}
######################################################################################
## Set the hostname for the current node to the local hostname. If it's a shared farm
## and NOT the master setup we don't have to change anything
######################################################################################
__setNodeHostName()
{
	local currentHost
	local hostNameToBeSet=$(hostname)

	##
	## If we are in a shared farm setup we need to set the hostname to localhost
	if [[ "${xxISSHAREDFARM}." == "true." ]] ; then
		hostNameToBeSet="localhost"
	fi

	if [[ "${xxISSHAREDFARM}." != "true." || "${xxISFARMMASTER}." == "true." && "${xxISSHAREDFARM}." == "true."   ]] ; then
		__setStepVal "portal.server.node.host"
		if [[ -n  ${xxStatusVal} ]] ; then
			currentHost=${xxStatusVal}
		else
			currentHost=""
		fi

		if [[ "${currentHost}." != "${hostNameToBeSet}." ]] ; then
			##
			## If we had a previous host name we add it to 127.0.0.1 for the time being
			if [[ "${currentHost}." != "." ]] ; then
				echo "127.0.0.1 ${currentHost}" >> /etc/hosts
			fi

			${xxProfileDir}/bin/wsadmin.sh -lang jython -connType NONE -c "AdminTask.changeHostName(['-hostName', '${hostNameToBeSet}', '-nodeName', 'wpNode']) ; AdminConfig.save()" || {
				__errorMsg "Error while running AdminTask.changeHostName. Terminating ..."
				return 1
			}
			${xxProfileDir}/ConfigEngine/ConfigEngine.sh localize-clone || {
				__errorMsg "Error while running ConfigEngine.sh localize-clone. Terminating ..."
				return 1
			}

			${xxProfileDir}/ConfigEngine/ConfigEngine.sh stop-portal-server || {
				__errorMsg "Error while running ConfigEngine.sh stop-portal-server. Terminating ..."
				return 1
			}

			${xxProfileDir}/ConfigEngine/ConfigEngine.sh action-clean-scheduled-tasks || {
				__errorMsg "Error while running ConfigEngine.sh action-clean-scheduled-tasks. Terminating ..."
				return 1
			}
			${xxProfileDir}/ConfigEngine/ConfigEngine.sh stop-portal-server
			sed -i s#WasRemoteHostName=.*#WasRemoteHostName=${hostNameToBeSet}#g ${xxProfileDir}/ConfigEngine/properties/wkplc.properties || return 1
			sed -i s#WpsHostName=.*#WpsHostName=${hostNameToBeSet}#g ${xxProfileDir}/ConfigEngine/properties/wkplc.properties || return 1
			__setStepStatus "portal.server.node.host" ${hostNameToBeSet}
			return $?
		fi
	fi

	return 0
}
######################################################################################
## Finish the setup as farm master
######################################################################################
__setFarmMaster()
{
	local isFarmMaster

	if [[ "${xxISFARMMASTER}." == "true." ]] ; then
		__setStepVal "$(hostname).farm.master"
		if [[ -n  ${xxStatusVal} ]] ; then
			isFarmMaster=${xxStatusVal}
		else
			isFarmMaster=""
		fi
		##
		## Farm master setup not yet done
		if [[ "${isFarmMaster}." != "true." ]] ; then
			cp -p ${xxProfileDir}/PortalServer/wcm/config/properties/prereq.wcm.properties ${xxProfileDir}/PortalServer/wcm/config/properties/prereq.wcm.properties_$(date +"%Y%m%d_%H%M%S")
			sed -i s#remoteJMSHost=.*#remoteJMSHost=${xxJMSHOST}#g ${xxProfileDir}/PortalServer/wcm/config/properties/prereq.wcm.properties || return 1
			sed -i s#remoteJMSBootstrapPort=.*#remoteJMSBootstrapPort=${xxJMSPORT}#g ${xxProfileDir}/PortalServer/wcm/config/properties/prereq.wcm.properties || return 1
			sed -i s#remoteJMSNodeName=.*#remoteJMSNodeName=${xxJMSNODENAME}#g ${xxProfileDir}/PortalServer/wcm/config/properties/prereq.wcm.properties  || return 1
			##
			## Create the remote messaging bus configuration
			${xxProfileDir}/ConfigEngine/ConfigEngine.sh create-wcm-jms-resources-remote || return 1
			if [[ ! -d ${xxSYSTEMPDIR} ]] ; then
				mkdir -p ${xxSYSTEMPDIR}
			fi
			${xxProfileDir}/ConfigEngine/ConfigEngine.sh enable-farm-mode -DsystemTemp=${xxSYSTEMPDIR} || return 1

			__setStepStatus "$(hostname).farm.master" ${xxISFARMMASTER}
			return $?
		fi
	fi

	return 0
}
######################################################################################
## Finish the setup as farm support server
######################################################################################
__setFarmSupportServer()
{
	local isFarmSuportServer

	if [[ "${xxISFARMSUPPORTER}." == "true." ]] ; then
		__setStepVal "$(hostname).farm.supporter"
		if [[ -n  ${xxStatusVal} ]] ; then
			isFarmSuportServer=${xxStatusVal}
		else
			isFarmSuportServer=""
		fi
		##
		## Farm master setup not yet done
		if [[ "${isFarmSuportServer}." != "true." ]] ; then
			##
			## Localice the clone and clean scheduled tasks
			${xxProfileDir}/ConfigEngine/ConfigEngine.sh localize-clone action-clean-scheduled-tasks || return 1
			##
			## Create the remote messaging bus configuration
			${xxProfileDir}/ConfigEngine/ConfigEngine.sh create-wcm-jms-resources || return 1

			__setStepStatus "$(hostname).farm.supporter" ${xxISFARMSUPPORTER}
			return $?
##### Obsolete as we are modifying /opt/IBM/WebSphere/PortalServer/wcm/prereq.wcm/config/includes/prereq.wcm_cfg.xml to deploy to the
##### profiles directory!
##### 		else
##### 			## The EJB is deployed to /opt/IBM/WebSphere/PortalServer/wcm/prereq.wcm/wcm/installedApps which is not in the volume
##### 			## hence needs might need to be redeployed after restart
##### 			__infoMsg "Redeploying wcm-monitor-bean"
##### 			${xxProfileDir}/ConfigEngine/ConfigEngine.sh remove-wcm-monitor-bean > /dev/null 2>&1
##### 			${xxProfileDir}/ConfigEngine/ConfigEngine.sh deploy-wcm-monitor-bean > /dev/null 2>&1
		fi
	fi

	return 0
}
######################################################################################
## Finish the setup as farm worker server
######################################################################################
__setFarmWorker()
{
	local isFarmWorkerServer

	if [[ "${xxISFARMWORKER}." == "true." && "${xxISSHAREDFARM}." != "true." ]] ; then
		__setStepVal "$(hostname).farm.worker"
		if [[ -n  ${xxStatusVal} ]] ; then
			isFarmWorkerServer=${xxStatusVal}
		else
			isFarmWorkerServer=""
		fi
		##
		## Farm master setup not yet done
		if [[ "${isFarmWorkerServer}." != "true." ]] ; then
			##
			## Localice the clone and clean scheduled tasks
			${xxProfileDir}/ConfigEngine/ConfigEngine.sh localize-clone action-clean-scheduled-tasks || return 1
			##
			## Set the CLOND_ID variable for the worker node
			if [[ "${xxCLONEID}." != "."  ]] ; then
				sed s#"^\(.*\)CLONE_ID.*"#"\\1CLONE_ID value=\"${xxCLONEID}\" \/\>"#g ${xxProfileDir}/config/cells/${xxCellName}/variables.xml
			fi

			__setStepStatus "$(hostname).farm.worker" ${xxISFARMWORKER}
			return $?
##### Obsolete as we are modifying /opt/IBM/WebSphere/PortalServer/wcm/prereq.wcm/config/includes/prereq.wcm_cfg.xml to deploy to the
##### profiles directory!
##### 		else
##### 			## The EJB is deployed to /opt/IBM/WebSphere/PortalServer/wcm/prereq.wcm/wcm/installedApps which is not in the volume
##### 			## hence needs might need to be redeployed after restart
##### 			__infoMsg "Redeploying wcm-monitor-bean"
##### 			${xxProfileDir}/ConfigEngine/ConfigEngine.sh remove-wcm-monitor-bean > /dev/null 2>&1
##### 			${xxProfileDir}/ConfigEngine/ConfigEngine.sh deploy-wcm-monitor-bean > /dev/null 2>&1
		fi
	fi

	return 0
}
######################################################################################
## Fix the profil directory if needed. For example if the profile directory is
## overmounted by a container
######################################################################################
__fixProfileDirIfNeeded()
{
	local curDir=$(pwd)
	cd ${xxProfileDir}/.. || return 1
	local parentDir=$(pwd)
	cd ${curDir} || return 1
	##
	## If the wp_profile was overmounted but is still empty --> copy from ${${parentDir}/_int_wp_profile
	if [[ -d ${parentDir}/_ext_wp_profile ]] ; then
		if [[ ! -d ${parentDir}/_ext_wp_profile/bin ]] ; then
			__infoMsg "Profile ${parentDir}/_ext_wp_profile/bin does not exist --> copying content from ${parentDir}/_int__wp_profile"
			if [[ -d ${parentDir}/_int__wp_profile ]] ; then
				cd ${parentDir}/_int__wp_profile || return 2
				__infoMsg "Please wait for the copy of the profile to complete ..."
				tar -cf - . | tar -C ${parentDir}/_ext_wp_profile -xf - || return 3
				__infoMsg "Profile copying completed successfully ..."
			else
				__errorMsg "wp_profile link can't be created as the source directroy ${xxProfileDir}/../_int__wp_profile does not exist"
				return 1
			fi
		fi
		##
		## Safety catch .. in case the container was recreated we still use the external mount
    cd ${parentDir} || return 4
    rm -f wp_profile
    ln -sf ${parentDir}/_ext_wp_profile ${xxProfileDir}
    cd ${curDir}
	fi

	return 0
}
######################################################################################
## Terminate the container
######################################################################################
__termAll()
{
	local waitPid=$(ps -ef | grep infinity | grep -v grep | awk '{print $2}')
	${xxProfileDir}/bin/stopServer.sh WebSphere_Portal

	exit 0
}
##################################################################################
## MAIN Script
##################################################################################
# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container
trap "echo '**CAUGHT TRAP**' ; __termAll" HUP INT QUIT TERM
##
## Assign parameters
__init  $@ || exit 1
##
## Perform some checks
__check || exit 2
##
## Do we have to fix the wp_profile link? This is needed in case the
## profile directory is is overmounted via compose
__fixProfileDirIfNeeded || {
	__errorMsg "Failed to fix the wp_profile directory. Terminating ..."
	exit 15
}
##
## Make sure we use the correct host name
__setNodeHostName || {
	__errorMsg "Failed to set hostname for node wpNode. Terminating ..."
	exit 3
}
##
## Set the port number for the server
__setWpPorts || {
	__errorMsg "Failed to set server ports. Terminating ..."
	exit 4
}
##
## Portnumber for DB2 (60000, 60100)
xxPortNum=$(($xxNUMDBINSTANCES - 1))
##
## WP is installed using hostname wp85.docker.container --> need to make sure we can resolve the host
## Using aliases in the docker files is not sufficient as the derby containers use wp85-derby as hostname
thisHostIp=$(grep $(hostname) /etc/hosts | awk '{print $1}') && \
echo "${thisHostIp} $(hostname -s | cut -d- -f1 | cut -d_ -f1).docker.container $(hostname -s | cut -d- -f1 | cut -d_ -f1)" >> /etc/hosts || {
	echo "ERROR: Could not create /etc/hosts entry for host name $(hostname -s).docker.container"
	exit 5
}
##
## Maybe we can use the time to pull files to shared/app directory while DB2 starts
__stepIsSet "customization.wp.shared.app.files"
rc=$?
if [[ ${rc} -ne 0 ]] ; then
	__getSharedAppFiles
	__setStepStatus "customization.wp.shared.app.files"
fi
##
## Wait for DB2 to come up if we are using DB2
if [[ "${xxDBTYPE}." == "db2." ]] ; then
	__waitForDb2 || exit 6
fi
##
## Wait for LDAP to come up if we are using LDAP
if [[ "${xxLDAPTYPE}." == "TDS." ]] ; then
	__waitForLDAP || exit 7
fi
##
## is a CF level upgrade required?
__checkCFApply || exit 8
##
## DB2 Transfer required?
__checkRunDB2Transfer || exit 9
##
## Do we need to connect to an LDAP registry?
__checkRunLDAPRegistry || exit 10
##
## Do we have to complete Farm-Master setup?
__setFarmMaster || {
	__errorMsg "Failed to complete farm-master setup. Terminating ..."
	exit 12
}
##
## Do we have to complete Farm-Support Server setup?
__setFarmSupportServer || {
	__errorMsg "Failed to complete farm-support-server setup. Terminating ..."
	exit 13
}
##
## Do we have to complete Farm Worker Server setup?
__setFarmWorker || {
	__errorMsg "Failed to complete farm-worker setup. Terminating ..."
	exit 14
}

if [[ "${xxNOPORTALSTART}." != "true." ]] ; then
	##
	## Recreate the startup script to ensure the latest config parameters are used
	rm -rf ${xxProfileDir}/bin/wp85up.sh
	${xxProfileDir}/bin/startServer.sh WebSphere_Portal -script ${xxProfileDir}/bin/wp85up.sh
	chmod +x ${xxProfileDir}/bin/wp85up.sh
	##
	## start service in background here
	${xxProfileDir}/bin/wp85up.sh &
	WPPID=$!
	__infoMsg "Background PID for WebSphere_Portal=${WPPID}"

	if [[ "${xxEXITONPORTALSTOP}." != "true." ]] ; then
		sleep infinity &
		WPPID=$!
	fi

	wait ${WPPID}
	rc=$?
	__infoMsg "rc=${rc}"
	exit ${rc}
fi
