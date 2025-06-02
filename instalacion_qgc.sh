#!/bin/bash

set -e  # Detener en caso de error

echo "==> Actualizando el sistema..."
sudo apt update && sudo apt upgrade -y

echo "==> Instalando Flatpak..."
sudo apt install -y flatpak

echo "==> Agregando repositorio Flathub..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "==> Instalando QGroundControl desde Flathub..."
flatpak install -y flathub org.mavlink.qgroundcontrol

echo "==> Instalando entorno gráfico mínimo..."
sudo apt install -y xorg openbox unclutter xterm xdotool wmctrl \
libxcb-xinerama0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
libxcb-render-util0 libxcb-shape0 libxkbcommon-x11-0

echo "==> Configurando Openbox..."
mkdir -p ~/.config/openbox

cat <<EOF > ~/.config/openbox/autostart
#!/bin/bash

export DISPLAY=:0
xset -dpms
xset s off
unclutter &

sleep 3

flatpak run --env=QT_QPA_PLATFORM=xcb org.mavlink.qgroundcontrol &

sleep 5

WINDOW_ID=""
MAX_ATTEMPTS=10
ATTEMPTS=0
while [ -z "\$WINDOW_ID" ] && [ \$ATTEMPTS -lt \$MAX_ATTEMPTS ]; do
    WINDOW_ID=\$(xdotool search --name "QGroundControl")
    if [ -z "\$WINDOW_ID" ]; then
        sleep 1
        ATTEMPTS=\$((ATTEMPTS+1))
    fi
done

if [ -n "\$WINDOW_ID" ]; then
    xdotool windowactivate "\$WINDOW_ID" windowfullscreen "\$WINDOW_ID"
fi
EOF

chmod +x ~/.config/openbox/autostart

echo "==> Creando .xinitrc..."
cat <<EOF > ~/.xinitrc
exec openbox-session
EOF

echo "==> Configurando auto-login para el usuario 'rpi'..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin rpi --noclear %I \$TERM
EOF

echo "==> Configurando inicio automático del entorno gráfico..."
cat <<EOF > ~/.bash_profile
if [[ -z \$DISPLAY ]] && [[ \$(tty) = /dev/tty1 ]]; then
    exec startx
fi
EOF

echo "==> Recargando systemd..."
sudo systemctl daemon-reload

echo "==> Instalación y configuración completadas."
echo "Puedes reiniciar el sistema con: sudo reboot"