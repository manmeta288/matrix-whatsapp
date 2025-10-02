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

# MEGABRIDGE FORMAT (not legacy format)
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
