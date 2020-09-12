#!/bin/bash
# Check if /config/NZBGet exists, if not make the directory
if [[ ! -e /config/NZBGet ]]; then
	mkdir -p /config/NZBGet
fi
# Set the correct rights accordingly to the PUID and PGID on /config/NZBGet
chown -R ${PUID}:${PGID} /config/NZBGet

# Set the rights on the /downloads folder
chown -R ${PUID}:${PGID} /downloads

# Check if nzbget.conf exists, if not, copy the template over
if [ ! -e /config/NZBGet/nzbget.conf ]; then
	echo "[WARNING] nzbget.conf is missing, this is normal for the first launch! Copying template." | ts '%Y-%m-%d %H:%M:%.S'
	cp /etc/nzbget/nzbget.conf /config/NZBGet/nzbget.conf
	chmod 755 /config/NZBGet/nzbget.conf
	chown ${PUID}:${PGID} /config/NZBGet/nzbget.conf
fi

# Check if the PGID exists, if not create the group with the name 'nzbget'
grep $"${PGID}:" /etc/group > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "[INFO] A group with PGID $PGID already exists in /etc/group, nothing to do." | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[INFO] A group with PGID $PGID does not exist, adding a group called 'nzbget' with PGID $PGID" | ts '%Y-%m-%d %H:%M:%.S'
	groupadd -g $PGID nzbget
fi

# Check if the PUID exists, if not create the user with the name 'nzbget', with the correct group
grep $"${PUID}:" /etc/passwd > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "[INFO] An user with PUID $PUID already exists in /etc/passwd, nothing to do." | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[INFO] An user with PUID $PUID does not exist, adding an user called 'nzbget user' with PUID $PUID" | ts '%Y-%m-%d %H:%M:%.S'
	useradd -c "nzbget user" -g $PGID -u $PUID nzbget
fi

# Set the umask
if [[ ! -z "${UMASK}" ]]; then
	echo "[INFO] UMASK defined as '${UMASK}'" | ts '%Y-%m-%d %H:%M:%.S'
	export UMASK=$(echo "${UMASK}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
else
	echo "[WARNING] UMASK not defined (via -e UMASK), defaulting to '002'" | ts '%Y-%m-%d %H:%M:%.S'
	export UMASK="002"
fi

CURRENT_WEBUI_USERNAME=$(awk -F "[=]+" '/^ControlUsername/{print $NF}' /config/NZBGet/nzbget.conf)

if [ ! ${WEBUI_USERNAME} == ${CURRENT_WEBUI_USERNAME} ]; then
	echo "[INFO] WEBUI_USERNAME defined as '${WEBUI_USERNAME}'" | ts '%Y-%m-%d %H:%M:%.S'
	echo "[INFO] Current config username defined as '${CURRENT_WEBUI_USERNAME}'" | ts '%Y-%m-%d %H:%M:%.S'
	echo "[INFO] Changing login name from '${CURRENT_WEBUI_USERNAME}' to ${WEBUI_USERNAME}" | ts '%Y-%m-%d %H:%M:%.S'
	sed -i -e "s#^ControlUsername=.*#ControlUsername=${WEBUI_USERNAME}#g" /config/NZBGet/nzbget.conf
fi

CURRENT_WEBUI_PASSWORD=$(awk -F "[=]+" '/^ControlPassword/{print $NF}' /config/NZBGet/nzbget.conf)

if [ ! ${WEBUI_PASSWORD} == ${CURRENT_WEBUI_PASSWORD} ]; then
	echo "[INFO] WEBUI_PASSWORD defined as '${WEBUI_PASSWORD}'" | ts '%Y-%m-%d %H:%M:%.S'
	echo "[INFO] Current config username defined as '${CURRENT_WEBUI_PASSWORD}'" | ts '%Y-%m-%d %H:%M:%.S'
	echo "[INFO] Changing login name from '${CURRENT_WEBUI_PASSWORD}' to ${WEBUI_PASSWORD}" | ts '%Y-%m-%d %H:%M:%.S'
	sed -i -e "s#^ControlPassword=.*#ControlPassword=${WEBUI_PASSWORD}#g" /config/NZBGet/nzbget.conf
fi

# The mess down here checks if SSL is enabled.
export ENABLE_SSL=$(echo "${ENABLE_SSL,,}")
if [[ ${ENABLE_SSL} == 'yes' ]]; then
	sed -i -e "s#^SecureControl=.*#SecureControl=yes#g" /config/NZBGet/nzbget.conf
	echo "[INFO] ENABLE_SSL is set to ${ENABLE_SSL}" | ts '%Y-%m-%d %H:%M:%.S'
	if [[ ${HOST_OS,,} == 'unraid' ]]; then
		echo "[SYSTEM] If you use Unraid, and get something like a 'ERR_EMPTY_RESPONSE' in your browser, add https:// to the front of the IP, and/or do this:" | ts '%Y-%m-%d %H:%M:%.S'
		echo "[SYSTEM] Edit this Docker, change the slider in the top right to 'advanced view' and change http to https at the WebUI setting." | ts '%Y-%m-%d %H:%M:%.S'
	fi
	if [ ! -e /config/NZBGet/WebUICertificate.crt ]; then
		echo "[WARNING] WebUI Certificate is missing, generating a new Certificate and Key" | ts '%Y-%m-%d %H:%M:%.S'
		openssl req -new -x509 -nodes -out /config/NZBGet/WebUICertificate.crt -keyout /config/NZBGet/WebUIKey.key -subj "/C=NL/ST=localhost/L=localhost/O=/OU=/CN="
		chown -R ${PUID}:${PGID} /config/NZBGet
	elif [ ! -e /config/NZBGet/WebUICertificate.key ]; then
		echo "[WARNING] WebUI Key is missing, generating a new Certificate and Key" | ts '%Y-%m-%d %H:%M:%.S'
		openssl req -new -x509 -nodes -out /config/NZBGet/WebUICertificate.crt -keyout /config/NZBGet/WebUIKey.key -subj "/C=NL/ST=localhost/L=localhost/O=/OU=/CN="
		chown -R ${PUID}:${PGID} /config/NZBGet
	fi
	sed -i -e "s#^SecureCert=.*#SecureCert=/config/NZBGet/WebUICertificate.crt#g" /config/NZBGet/nzbget.conf
	sed -i -e "s#^SecureKey=.*#SecureKey=/config/NZBGet/WebUIKey.key#g" /config/NZBGet/nzbget.conf
else
	echo "[WARNING] ENABLE_SSL is set to ${ENABLE_SSL}, SSL is not enabled." | ts '%Y-%m-%d %H:%M:%.S'
	echo "[WARNING] If you manage the SSL config yourself, you can ignore this." | ts '%Y-%m-%d %H:%M:%.S'
fi

# Start NZBGet
echo "[INFO] Starting NZBGet daemon..." | ts '%Y-%m-%d %H:%M:%.S'
/bin/bash /etc/nzbget/nzbget.init start &
chmod -R 755 /config/NZBGet

# Wait a second for it to start up and get the process id
sleep 1
nzbgetpid=$(pgrep -o -x nzbget) 
echo "[INFO] NZBGet PID: $nzbgetpid" | ts '%Y-%m-%d %H:%M:%.S'

# If the process exists, make sure that the log file has the proper rights and start the health check
if [ -e /proc/$nzbgetpid ]; then
	if [[ -e /config/NZBGet/logs/nzbget.log ]]; then
		chmod 775 /config/NZBGet/logs/nzbget.log
	fi
	
	# Set some variables that are used
	HOST=${HEALTH_CHECK_HOST}
	DEFAULT_HOST="one.one.one.one"
	INTERVAL=${HEALTH_CHECK_INTERVAL}
	DEFAULT_INTERVAL=300
	
	# If host is zero (not set) default it to the DEFAULT_HOST variable
	if [[ -z "${HOST}" ]]; then
		echo "[INFO] HEALTH_CHECK_HOST is not set. For now using default host ${DEFAULT_HOST}" | ts '%Y-%m-%d %H:%M:%.S'
		HOST=${DEFAULT_HOST}
	fi

	# If HEALTH_CHECK_INTERVAL is zero (not set) default it to DEFAULT_INTERVAL
	if [[ -z "${HEALTH_CHECK_INTERVAL}" ]]; then
		echo "[INFO] HEALTH_CHECK_INTERVAL is not set. For now using default interval of ${DEFAULT_INTERVAL}" | ts '%Y-%m-%d %H:%M:%.S'
		INTERVAL=${DEFAULT_INTERVAL}
	fi
	
	# If HEALTH_CHECK_SILENT is zero (not set) default it to supression
	if [[ -z "${HEALTH_CHECK_SILENT}" ]]; then
		echo "[INFO] HEALTH_CHECK_SILENT is not set. Because this variable is not set, it will be supressed by default" | ts '%Y-%m-%d %H:%M:%.S'
		HEALTH_CHECK_SILENT=1
	fi

	while true; do
		# Ping uses both exit codes 1 and 2. Exit code 2 cannot be used for docker health checks, therefore we use this script to catch error code 2
		ping -c 1 $HOST > /dev/null 2>&1
		STATUS=$?
		if [[ "${STATUS}" -ne 0 ]]; then
			echo "[ERROR] Network is down, exiting this Docker" | ts '%Y-%m-%d %H:%M:%.S'
			exit 1
		fi
		if [ ! "${HEALTH_CHECK_SILENT}" -eq 1 ]; then
			echo "[INFO] Network is up" | ts '%Y-%m-%d %H:%M:%.S'
		fi
		sleep ${INTERVAL}
	done
else
	echo "[ERROR] NZBGet failed to start!" | ts '%Y-%m-%d %H:%M:%.S'
fi
