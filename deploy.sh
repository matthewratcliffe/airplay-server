#!/bin/bash

# 1) Check for sudo/root
echo "[1/9] Checking for root permissions..."
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root. Use sudo." >&2
  exit 1
fi
echo "✅ Running as root."

# 2) Update package list
echo "[2/9] Updating package list..."
apt-get update
echo "✅ Package list updated."

# 3) Install uxplay and dependencies
echo "[3/9] Installing uxplay and dependencies..."
apt-get install -y uxplay imagemagick \
  gstreamer1.0-plugins-bad gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-ugly gstreamer1.0-libav
echo "✅ uxplay and dependencies installed."

# 4) Configure uxplay to run on startup without PIN and log output
echo "[4/9] Creating uxplay autostart entry..."
HOSTNAME=$(hostname)

cat <<EOF > /etc/xdg/autostart/uxplay.desktop
[Desktop Entry]
Type=Application
Exec=/bin/sh -c 'sleep 5 && uxplay -fs -n $HOSTNAME -nh >> /tmp/airplay.log 2>&1'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=UxPlay
Comment=Start UxPlay AirPlay Receiver
EOF
echo "✅ uxplay will start automatically on login with hostname '$HOSTNAME'. Output logged to /tmp/airplay.log"

# 5) Create user 'airplay' with password 'airplay'
echo "[5/9] Creating user 'airplay'..."
if id "airplay" &>/dev/null; then
    echo "ℹ️ User 'airplay' already exists. Skipping creation."
else
    useradd -m -s /bin/bash airplay
    echo "airplay:airplay" | chpasswd
    echo "✅ User 'airplay' created with password 'airplay'."
fi

# 6) Check for existing autologin in LightDM config and warn if conflict
echo "[6/9] Checking for existing autologin configuration..."
LIGHTDM_CONF_DIR="/etc/lightdm/lightdm.conf.d"
LIGHTDM_CONF="$LIGHTDM_CONF_DIR/50-airplay.conf"

mkdir -p "$LIGHTDM_CONF_DIR"

EXISTING_AUTOLOGIN=$(grep -E '^\s*autologin-user=' /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.d/*.conf 2>/dev/null || true)

if [ -n "$EXISTING_AUTOLOGIN" ]; then
  echo "⚠️ Warning: Existing autologin user configuration found:"
  echo "$EXISTING_AUTOLOGIN"
  echo "The auto login for user 'airplay' may not work correctly."
fi

cat <<EOF > "$LIGHTDM_CONF"
[Seat:*]
autologin-user=airplay
autologin-user-timeout=0
user-session=xubuntu
EOF
echo "✅ Autologin for 'airplay' configured."

# 7) Create XFCE setup script to disable display sleep and hide desktop icons
echo "[7/9] Creating XFCE setup script for user 'airplay'..."

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
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/sleep-display-ac -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-on-suspend -s false
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -s false
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/blank-on-suspend -s false
EOF

chmod +x /home/airplay/airplay-xfce-setup.sh
chown airplay:airplay /home/airplay/airplay-xfce-setup.sh

# Create autostart .desktop entry for airplay-xfce-setup.sh
cat <<EOF > /home/airplay/.config/autostart/airplay-xfce-setup.desktop
[Desktop Entry]
Type=Application
Exec=/home/airplay/airplay-xfce-setup.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Airplay XFCE Config
Comment=Set wallpaper, hide desktop icons, and disable display sleep
EOF

chown airplay:airplay /home/airplay/.config/autostart/airplay-xfce-setup.desktop
echo "✅ XFCE desktop config script will run on login."

# 8) Create wallpaper image
echo "[8/9] Creating wallpaper image..."
convert -size 1920x1080 xc:black -gravity center -pointsize 48 \
  -fill white -annotate +0+0 "Airplay server enabled" \
  "$WALLPAPER_PATH"
chown airplay:airplay "$WALLPAPER_PATH"
echo "✅ Wallpaper image created."

echo "🎉 Setup complete! Please reboot to apply all changes."
