#!/bin/bash

# 0) Ask for AirPlay display name (default to hostname)
read -rp "🎛️ Enter AirPlay display name (default: system hostname): " AIRPLAY_NAME
if [ -z "$AIRPLAY_NAME" ]; then
  AIRPLAY_NAME=$(hostname)
fi
AIRPLAY_NAME="${AIRPLAY_NAME//[- ]/_}"
echo "ℹ️ AirPlay display name set to: $AIRPLAY_NAME"

# 1) Check for sudo/root
echo "[1/12] Checking for root permissions..."
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root. Use sudo." >&2
  exit 1
fi
echo "✅ Running as root."

# 2) Update package list
echo "[2/12] Updating package list..."
apt-get update
echo "✅ Package list updated."

# 3) Install uxplay and dependencies
echo "[3/12] Installing uxplay and dependencies..."
apt-get install -y uxplay imagemagick unclutter \
  gstreamer1.0-plugins-bad gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-ugly gstreamer1.0-libav
echo "✅ Packages installed."

# 4) Remove screen blanking tools
echo "[4/12] Removing interfering screensavers..."
apt-get purge -y xscreensaver light-locker || true
rm -f /home/airplay/.config/autostart/xscreensaver.desktop
rm -f /home/airplay/.config/autostart/light-locker.desktop
echo "✅ Removed xscreensaver/light-locker if present."

# 5) Configure uxplay to autostart
echo "[5/12] Creating uxplay autostart entry..."
cat <<EOF > /etc/xdg/autostart/uxplay.desktop
[Desktop Entry]
Type=Application
Exec=/bin/sh -c 'sleep 5 && uxplay -fs -n "$AIRPLAY_NAME" -nh >> /tmp/airplay.log 2>&1'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=UxPlay
Comment=Start UxPlay AirPlay Receiver
EOF
echo "✅ uxplay autostart created."

# 6) Create 'airplay' user
echo "[6/12] Creating user 'airplay'..."
if id "airplay" &>/dev/null; then
  echo "ℹ️ User 'airplay' already exists. Skipping creation."
else
  useradd -m -s /bin/bash airplay
  echo "airplay:airplay" | chpasswd
  echo "✅ User 'airplay' created."
fi

# 7) Setup LightDM autologin
echo "[7/12] Configuring LightDM autologin..."
LIGHTDM_CONF="/etc/lightdm/lightdm.conf.d/50-airplay.conf"
mkdir -p "$(dirname "$LIGHTDM_CONF")"

cat <<EOF > "$LIGHTDM_CONF"
[Seat:*]
autologin-user=airplay
autologin-user-timeout=0
user-session=xubuntu
xserver-command=X -s 0 -dpms
EOF
echo "✅ LightDM autologin and xserver command configured."

# 8) Configure XFCE autostart and no-sleep setup
echo "[8/12] Creating XFCE setup script..."
WALLPAPER_PATH="/home/airplay/Pictures/airplay_wallpaper.png"
sudo -u airplay mkdir -p /home/airplay/.config/autostart
sudo -u airplay mkdir -p /home/airplay/Pictures

cat <<EOF > /home/airplay/airplay-xfce-setup.sh
#!/bin/bash

# Set wallpaper
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$WALLPAPER_PATH"
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-style -s 3

# Hide desktop icons
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-home -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-trash -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-removable -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-volumes -s false

# Disable XFCE power manager actions
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/sleep-display-ac -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-on-suspend -s false
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -s false
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/blank-on-suspend -s false

# Disable screen blanking and power saving (must be in X session)
xset s off
xset s noblank
xset -dpms
EOF

chmod +x /home/airplay/airplay-xfce-setup.sh
chown airplay:airplay /home/airplay/airplay-xfce-setup.sh

cat <<EOF > /home/airplay/.config/autostart/airplay-xfce-setup.desktop
[Desktop Entry]
Type=Application
Exec=/home/airplay/airplay-xfce-setup.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Airplay XFCE Config
Comment=Configure desktop on login
EOF

chown airplay:airplay /home/airplay/.config/autostart/airplay-xfce-setup.desktop
echo "✅ XFCE power settings and display behavior configured."

# 9) Configure unclutter
echo "[9/12] Creating unclutter autostart entry..."
cat <<EOF > /home/airplay/.config/autostart/unclutter.desktop
[Desktop Entry]
Type=Application
Exec=unclutter -idle 3 -root
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Unclutter
Comment=Auto-hide mouse cursor after 3 seconds
EOF
chown airplay:airplay /home/airplay/.config/autostart/unclutter.desktop
echo "✅ Unclutter configured."

# 10) Generate wallpaper with AirPlay name
echo "[10/12] Creating wallpaper image..."
convert -size 1920x1080 xc:black \
  -gravity center -pointsize 48 -fill white -annotate +0-30 "Airplay server enabled" \
  -gravity center -pointsize 36 -fill white -annotate +0+30 "$AIRPLAY_NAME" \
  "$WALLPAPER_PATH"
chown airplay:airplay "$WALLPAPER_PATH"
echo "✅ Wallpaper image created."

# 11) Configure power button to shutdown
echo "[11/12] Configuring power button to shutdown..."
sed -i 's/^#*HandlePowerKey=.*/HandlePowerKey=poweroff/' /etc/systemd/logind.conf
systemctl restart systemd-logind
echo "✅ Power button set to shutdown."

echo "[12/12] Setup complete! Reboot to apply all changes."
