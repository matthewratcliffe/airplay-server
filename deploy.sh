#!/bin/bash

# 0) Check for sudo/root
echo "[0/8] Checking for root permissions..."
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root. Use sudo." >&2
  exit 1
fi
echo "✅ Running as root."

# 1) Update package list
echo "[1/8] Updating package list..."
apt-get update
echo "✅ Package list updated."

# 2) Install uxplay
echo "[2/8] Installing uxplay..."
apt-get install -y uxplay
echo "✅ uxplay installed."

# 3) Configure uxplay to run on startup
echo "[3/8] Creating uxplay autostart entry..."
cat <<EOF > /etc/xdg/autostart/uxplay.desktop
[Desktop Entry]
Type=Application
Exec=uxplay
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=UxPlay
Comment=Start UxPlay AirPlay Receiver
EOF
echo "✅ uxplay will start automatically on login."

# 4) Create user 'airplay' with password 'airplay'
echo "[4/8] Creating user 'airplay'..."
if id "airplay" &>/dev/null; then
    echo "ℹ️ User 'airplay' already exists. Skipping creation."
else
    useradd -m -s /bin/bash airplay
    echo "airplay:airplay" | chpasswd
    echo "✅ User 'airplay' created with password 'airplay'."
fi

# 5) Set lightdm to auto-login as airplay
echo "[5/8] Configuring LightDM autologin for 'airplay'..."
LIGHTDM_CONF="/etc/lightdm/lightdm.conf.d/50-airplay.conf"
mkdir -p "$(dirname "$LIGHTDM_CONF")"
cat <<EOF > "$LIGHTDM_CONF"
[Seat:*]
autologin-user=airplay
autologin-user-timeout=0
user-session=xubuntu
EOF
echo "✅ Autologin for 'airplay' configured."

# 6) Hide all desktop icons for airplay user (Xfce specific)
echo "[6/8] Hiding desktop icons for user 'airplay'..."
sudo -u airplay mkdir -p /home/airplay/.config/xfce4/desktop
sudo -u airplay mkdir -p /home/airplay/.config/xfce4/xfconf/xfce-perchannel-xml

cat <<EOF > /home/airplay/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="desktop-icons" type="empty">
    <property name="show-trash-icon" type="bool" value="false"/>
    <property name="show-filesystem-icon" type="bool" value="false"/>
    <property name="show-home-icon" type="bool" value="false"/>
    <property name="show-removable-icon" type="bool" value="false"/>
    <property name="show-network-icon" type="bool" value="false"/>
  </property>
</channel>
EOF

chown -R airplay:airplay /home/airplay/.config
echo "✅ Desktop icons hidden for 'airplay'."

# 7) Set wallpaper (create placeholder image)
echo "[7/8] Creating wallpaper image..."
WALLPAPER_PATH="/home/airplay/Pictures/airplay_wallpaper.png"
mkdir -p /home/airplay/Pictures

# Install ImageMagick if not already present
echo "Installing ImageMagick (for wallpaper generation)..."
apt-get install -y imagemagick

convert -size 1920x1080 xc:black -gravity center -pointsize 48 \
    -fill white -annotate +0+0 "Airplay server enabled" "$WALLPAPER_PATH"

chown airplay:airplay "$WALLPAPER_PATH"
echo "✅ Wallpaper image created."

# Apply wallpaper using xfconf
echo "[8/8] Setting wallpaper via xfconf..."
sudo -u airplay xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$WALLPAPER_PATH"
sudo -u airplay xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-style -s 3
echo "✅ Wallpaper set."

echo "🎉 Setup complete! Please reboot to apply all changes."
