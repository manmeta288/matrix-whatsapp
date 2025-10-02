#!/bin/sh

if [[ -z "$GID" ]]; then
	GID="$UID"
fi

# Define functions.
function fixperms {
	chown -R $UID:$GID /data

	# /opt/mautrix-whatsapp is read-only, so disable file logging if it's pointing there.
	if [[ "$(yq e '.logging.writers[1].filename' /data/config.yaml)" == "./logs/mautrix-whatsapp.log" ]]; then
		yq -I4 e -i 'del(.logging.writers[1])' /data/config.yaml
	fi
}

# Generate config from environment variables if they exist and no config exists
if [[ ! -f /data/config.yaml ]] && [[ -n "$HOMESERVER_DOMAIN" ]]; then
	echo "Generating config.yaml from environment variables..."
	cat > /data/config.yaml << EOF
homeserver:
    address: ${HOMESERVER_ADDRESS:-http://localhost:8008}
    domain: ${HOMESERVER_DOMAIN}

appservice:
    address: ${APPSERVICE_ADDRESS:-http://localhost:29318}
    hostname: ${APPSERVICE_HOSTNAME:-0.0.0.0}
    port: ${APPSERVICE_PORT:-29318}
    
    database:
        type: postgres
        uri: ${DATABASE_URL}
    
    id: whatsapp
    bot_username: whatsappbot
    ephemeral_events: true

# NEW MEGABRIDGE FORMAT
network:
    displayname_template: "{displayname} (WA)"
    username_template: "whatsapp_{userid}"

bridge:
    permissions:
        "*": relay
        "${HOMESERVER_DOMAIN}": user

logging:
    min_level: info
    writers:
    - type: stdout
      format: pretty-colored
EOF
fi

if [[ ! -f /data/config.yaml ]]; then
	/usr/bin/mautrix-whatsapp -c /data/config.yaml -e
	echo "Didn't find a config file."
	echo "Copied default config file to /data/config.yaml"
	echo "Modify that config file to your liking."
	echo "Start the container again after that to generate the registration file."
	exit
fi

if [[ ! -f /data/registration.yaml ]]; then
	/usr/bin/mautrix-whatsapp -g -c /data/config.yaml -r /data/registration.yaml || exit $?
	echo "Didn't find a registration file."
	echo "Generated one for you."
	echo "See https://docs.mau.fi/bridges/general/registering-appservices.html on how to use it."
	exit
fi

cd /data
fixperms
exec su-exec $UID:$GID /usr/bin/mautrix-whatsapp
