#!/bin/bash

# 0) Ask for AirPlay display name (default to hostname)
read -rp "🎛️ Enter AirPlay display name (default: system hostname): " AIRPLAY_NAME
if [ -z "$AIRPLAY_NAME" ]; then
  AIRPLAY_NAME=$(hostname)
fi
# Replace hyphens and spaces with underscores
AIRPLAY_NAME="${AIRPLAY_NAME//[- ]/_}"
echo "ℹ️ AirPlay display name set to: $AIRPLAY_NAME"

# 1) Check for sudo/root
echo "[1/10] Checking for root permissions..."
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root. Use sudo." >&2
  exit 1
fi
echo "✅ Running as root."

# 2) Update package list
echo "[2/10] Updating package list..."
apt-get update
echo "✅ Package list updated."

# 3) Install uxplay, imagemagick, and unclutter
echo "[3/10] Installing uxplay, imagemagick, and unclutter..."
apt-get install -y uxplay imagemagick unclutter \
  gstreamer1.0-plugins-bad gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-ugly gstreamer1.0-libav
echo "✅ Packages installed."

# 4) Configure uxplay to run on startup and log to /tmp/airplay.log
echo "[4/10] Creating uxplay autostart entry..."
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
echo "✅ uxplay autostart configured with logging to /tmp/airplay.log"

# 5) Create user 'airplay' with password 'airplay'
echo "[5/10] Creating user 'airplay'..."
if id "airplay" &>/dev/null; then
  echo "ℹ️ User 'airplay' already exists. Skipping creation."
else
  useradd -m -s /bin/bash airplay
  echo "airplay:airplay" | chpasswd
  echo "✅ User 'airplay' created."
fi

# 6) Configure autologin for 'airplay' user in LightDM
echo "[6/10] Configuring LightDM autologin for 'airplay'..."
LIGHTDM_CONF="/etc/lightdm/lightdm.conf.d/50-airplay.conf"
mkdir -p "$(dirname "$LIGHTDM_CONF")"

if grep -q '^autologin-user=' /etc/lightdm/lightdm.conf 2>/dev/null; then
  echo "⚠️ Warning: Another autologin-user directive found in /etc/lightdm/lightdm.conf"
fi

cat <<EOF > "$LIGHTDM_CONF"
[Seat:*]
autologin-user=airplay
autologin-user-timeout=0
user-session=xubuntu
EOF
echo "✅ Autologin configured."

# 7) Create XFCE setup script for user configuration
echo "[7/10] Creating XFCE setup script for user 'airplay'..."

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

# Disable display sleep and screen blanking
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-battery -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-sleep -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-battery-sleep -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-ac -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-battery -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-on-suspend -s false
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -s false

# Fallback settings using xset
xset s off        # Disable screen saver
xset s noblank    # Disable screen blanking
xset -dpms        # Disable display power management (DPMS)
EOF

chmod +x /home/airplay/airplay-xfce-setup.sh
chown airplay:airplay /home/airplay/airplay-xfce-setup.sh

# Create autostart entry for the XFCE setup script
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
echo "✅ XFCE desktop setup configured."

# 8) Configure unclutter to auto-hide cursor
echo "[8/10] Creating autostart entry for unclutter (auto-hide cursor)..."

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
echo "✅ Cursor auto-hide configured."

# 9) Create wallpaper image with AirPlay server name in second line
echo "[9/10] Creating wallpaper image..."
convert -size 1920x1080 xc:black -gravity center -pointsize 48 \
  -fill white -annotate +0-40 "Airplay server enabled" \
  -pointsize 36 -annotate +0+40 "$AIRPLAY_NAME" \
  "$WALLPAPER_PATH"
chown airplay:airplay "$WALLPAPER_PATH"
echo "✅ Wallpaper image created."

echo "🎉 Setup complete! Please reboot the system to apply changes."
