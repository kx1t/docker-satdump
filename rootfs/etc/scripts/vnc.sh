#!/command/with-contenv bash
# shellcheck shell=bash disable=SC1091,SC2154

source /scripts/common

if ! chk_enabled "$VNC_ENABLED"; then
    "${s6wrap[@]}" echo "VNC not enabled"
    exit 0
fi

if [[ -z "$VNC_PASSWORD" ]]; then 
    "${s6wrap[@]}" echo "[ERROR] VNC_PASSWORD must be set"
    exit 1
fi

export RESOLUTION="${VNC_RESOLUTION:-1920x1080}"
export USER="${USER:-${VNC_USER:-root}}"

if ! which vncserver >/dev/null 2>&1; then
    "${s6wrap[@]}" echo "Initial installation of VNC Server. This may take a while..."
    export DEBIAN_FRONTEND=noninteractive
    "${s6wrap[@]}" apt-get update
    "${s6wrap[@]}" apt-get install -y --no-install-recommends \
        xfce4 \
        xfce4-goodies \
        tightvncserver \
        dbus-x11 \
        xfonts-base
    "${s6wrap[@]}" apt-get clean
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

    HOSTNAME=$(hostname)
    if ! grep -q "127.0.1.1" /etc/hosts; then echo "127.0.1.1 ${HOSTNAME:-satdump}" >> /etc/hosts; fi

    mkdir -p "$HOME/.vnc"
    echo "$VNC_PASSWORD" | vncpasswd -f > "$HOME/.vnc/passwd"
    chmod 600 "$HOME/.vnc/passwd"

    touch "$HOME/.Xauthority"

    mkdir -p "$HOME/Desktop"
    {   echo '#!/command/with-contenv bash'
        echo 'source /scripts/common'
        echo 'pkill satdump >/dev/null 2>&1'
        # shellcheck disable=SC2016
        echo '"${s6wrap[@]}" /usr/bin/satdump-ui'
    } > "$HOME/satdump-vnc"
    chmod +x "$HOME/satdump-vnc"

fi

"${s6wrap[@]}" echo "Starting VNC server at $RESOLUTION..."
vncserver -kill :1 >/dev/null 2>&1 || pkill Xtightvnc >/dev/null 2>&1 || true
"${s6wrap[@]}" "${s6wrap[@]}" vncserver -geometry "$RESOLUTION" &

"${s6wrap[@]}" echo "VNC server started at $RESOLUTION! ^-^"
