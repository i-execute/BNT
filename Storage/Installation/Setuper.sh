#!/bin/bash

set -e

SERVICE_NAME="BNT"
REPO_URL="https://github.com/i-execute/BNT.git"
PYTHON_BIN="$(command -v python3)"

if [ "$(id -u)" -eq 0 ]; then
    IS_ROOT=1
    REAL_USER="${SUDO_USER:-root}"
    INSTALL_DIR="/opt/BNT"
    RUN_USER="$REAL_USER"
    VENV_DIR="$INSTALL_DIR/venv"
    ENV_FILE="$INSTALL_DIR/.env"
    UNIT_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
else
    IS_ROOT=0
    REAL_USER="$USER"
    RUN_USER="$USER"
    INSTALL_DIR="$HOME/BNT"
    VENV_DIR="$INSTALL_DIR/venv"
    ENV_FILE="$INSTALL_DIR/.env"
    UNIT_DIR="$HOME/.config/systemd/user"
    UNIT_FILE="$UNIT_DIR/${SERVICE_NAME}.service"
fi

if [ -z "$PYTHON_BIN" ]; then
    echo "ERROR: python3 not found"
    exit 1
fi

systemd_cmd() {
    if [ "$IS_ROOT" -eq 1 ]; then
        systemctl "$@"
    else
        systemctl --user "$@"
    fi
}

env_is_valid() {
    [ -f "$ENV_FILE" ] || return 1

    local v_api_id v_api_hash v_bot_token v_owner_id
    v_api_id="$(grep -E '^API_ID='    "$ENV_FILE" | cut -d'=' -f2-)"
    v_api_hash="$(grep -E '^API_HASH=' "$ENV_FILE" | cut -d'=' -f2-)"
    v_bot_token="$(grep -E '^BOT_TOKEN=' "$ENV_FILE" | cut -d'=' -f2-)"
    v_owner_id="$(grep -E '^OWNER_ID=' "$ENV_FILE" | cut -d'=' -f2-)"

    [ -n "$v_api_id" ] && [ -n "$v_api_hash" ] && \
    [ -n "$v_bot_token" ] && [ -n "$v_owner_id" ]
}

write_env_file() {
    cat > "$ENV_FILE" <<EOF
API_ID=$API_ID
API_HASH=$API_HASH
BOT_TOKEN=$BOT_TOKEN
OWNER_ID=$OWNER_ID
EOF
    chmod 600 "$ENV_FILE"
    if [ "$IS_ROOT" -eq 1 ] && [ "$RUN_USER" != "root" ]; then
        chown "$RUN_USER":"$RUN_USER" "$ENV_FILE"
    fi
}

prompt_credentials() {
    read -rp "BOT_TOKEN : " BOT_TOKEN < /dev/tty
    if [ -z "$BOT_TOKEN" ]; then
        echo "Enter token next time"
        exit 1
    fi

    read -rp "OWNER_ID  : " OWNER_ID < /dev/tty
    if ! [[ "$OWNER_ID" =~ ^[0-9]+$ ]]; then
        echo "Enter correct ID next time"
        exit 1
    fi

    read -rp "API_ID    : " API_ID < /dev/tty
    if ! [[ "$API_ID" =~ ^[0-9]+$ ]]; then
        echo "Enter correct API ID next time"
        exit 1
    fi

    read -rp "API_HASH  : " API_HASH < /dev/tty
    if [ -z "$API_HASH" ]; then
        echo "Enter API hash next time"
        exit 1
    fi

    echo ""
}

write_unit_file() {
    if [ "$IS_ROOT" -eq 1 ]; then
        cat > "$UNIT_FILE" <<EOF
[Unit]
Description=BNT
After=network.target

[Service]
User=$RUN_USER
WorkingDirectory=$INSTALL_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$VENV_DIR/bin/python3 $INSTALL_DIR/BNT/core.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    else
        mkdir -p "$UNIT_DIR"
        cat > "$UNIT_FILE" <<EOF
[Unit]
Description=BNT
After=network.target

[Service]
WorkingDirectory=$INSTALL_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$VENV_DIR/bin/python3 $INSTALL_DIR/BNT/core.py
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF
    fi
}

echo "Welcome back $REAL_USER"
echo "Time to do something interesting"
echo "Installation..."
echo ""

if [ "$IS_ROOT" -eq 1 ]; then
    echo "[!] Running as root — using system-wide systemd"
    echo "    Install dir : $INSTALL_DIR"
    echo "    Run as user : $RUN_USER"
    echo ""
fi

ALREADY_INSTALLED=0
if [ -d "$INSTALL_DIR/.git" ]; then
    ALREADY_INSTALLED=1
fi

if [ "$ALREADY_INSTALLED" -eq 1 ]; then
    echo "BNT already installed, checking .env..."

    if env_is_valid; then
        echo ""
        echo "Current config:"
        echo " API_ID    : $(grep -E '^API_ID='    "$ENV_FILE" | cut -d'=' -f2-)"
        echo " API_HASH  : $(grep -E '^API_HASH='  "$ENV_FILE" | cut -d'=' -f2-)"
        echo " BOT_TOKEN : $(grep -E '^BOT_TOKEN=' "$ENV_FILE" | cut -d'=' -f2-)"
        echo " OWNER_ID  : $(grep -E '^OWNER_ID='  "$ENV_FILE" | cut -d'=' -f2-)"
        echo ""

        read -rp "Change config? [y/N]: " CHANGE_ENV < /dev/tty
        if [[ "$CHANGE_ENV" =~ ^[Yy]$ ]]; then
            prompt_credentials
            write_env_file
        fi
    else
        echo ".env missing or incomplete, please fill it in"
        echo ""
        prompt_credentials
        write_env_file
    fi

    echo "Pulling latest changes..."
    cd "$INSTALL_DIR"
    git pull origin main
else
    prompt_credentials

    echo "Cloning repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"

    if [ "$IS_ROOT" -eq 1 ] && [ "$RUN_USER" != "root" ]; then
        chown -R "$RUN_USER":"$RUN_USER" "$INSTALL_DIR"
    fi

    write_env_file

    echo "Building venv..."
    $PYTHON_BIN -m venv "$VENV_DIR"

    echo "Upgrading pip..."
    "$VENV_DIR/bin/pip" install --upgrade pip

    echo "Installing packages..."
    "$VENV_DIR/bin/pip" install telethon aiohttp gitpython
    echo "Successfully installed python packages in venv"

    echo "Building daemon configuration..."
    write_unit_file
    echo "Unit file written to: $UNIT_FILE"
fi

systemd_cmd daemon-reload
systemd_cmd enable "$SERVICE_NAME"
systemd_cmd restart "$SERVICE_NAME"

echo ""
echo "[*] BNT successfully started"
echo "    I_execute.t.me"
echo ""
echo "----------------------------------"
echo " installed in   : $INSTALL_DIR"
echo " venv directory : $VENV_DIR"
echo " config         : $ENV_FILE"
echo " unit file      : $UNIT_FILE"
echo " run as user    : $RUN_USER"
echo "----------------------------------"