#!/bin/bash

# 0) Ask for AirPlay display name (default to hostname)
read -rp "🎛️ Enter AirPlay display name (default: system hostname): " AIRPLAY_NAME
if [ -z "$AIRPLAY_NAME" ]; then
  AIRPLAY_NAME=$(hostname)
fi
# Replace hyphens and spaces with underscores
AIRPLAY_NAME="${AIRPLAY_NAME//[- ]/_}"
echo "ℹ️ AirPlay display name set to: $AIRPLAY_NAME"

# Ask if user wants auto shutdown
read -rp "⚙️ Enable auto shutdown? (y/N): " AUTO_SHUTDOWN
AUTO_SHUTDOWN=${AUTO_SHUTDOWN,,} # lowercase
if [[ "$AUTO_SHUTDOWN" == "y" || "$AUTO_SHUTDOWN" == "yes" ]]; then
  read -rp "⏰ Enter hours before shutdown (whole number): " SHUTDOWN_HOURS
  if ! [[ "$SHUTDOWN_HOURS" =~ ^[0-9]+$ ]]; then
    echo "❌ Invalid number. Skipping auto shutdown setup."
    AUTO_SHUTDOWN="n"
  else
    echo "✅ Auto shutdown enabled after $SHUTDOWN_HOURS hour(s)."
  fi
else
  AUTO_SHUTDOWN="n"
fi

# 1) Check for sudo/root
echo "[1/11] Checking for root permissions..."
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root. Use sudo." >&2
  exit 1
fi
echo "✅ Running as root."

# 2) Update package list
echo "[2/11] Updating package list..."
apt-get update
echo "✅ Package list updated."

# 3) Install uxplay, imagemagick, and unclutter
echo "[3/11] Installing uxplay, imagemagick, and unclutter..."
apt-get install -y uxplay imagemagick unclutter \
  gstreamer1.0-plugins-bad gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-ugly gstreamer1.0-libav
echo "✅ Packages installed."

# 4) Configure uxplay to run on startup and log to /tmp/airplay.log
echo "[4/11] Creating uxplay autostart entry..."
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
echo "[5/11] Creating user 'airplay'..."
if id "airplay" &>/dev/null; then
  echo "ℹ️ User 'airplay' already exists. Skipping creation."
else
  useradd -m -s /bin/bash airplay
  echo "airplay:airplay" | chpasswd
  echo "✅ User 'airplay' created."
fi

# 6) Configure autologin for 'airplay' user in LightDM
echo "[6/11] Configuring LightDM autologin for 'airplay'..."
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
echo "[7/11] Creating XFCE setup script for user 'airplay'..."

WALLPAPER_PATH="/home/airplay/Pictures/airplay_wallpaper.png"

sudo -u airplay mkdir -p /home/airplay/.config/autostart
sudo -u airplay mkdir -p /home/airplay/Pictures

# Build wallpaper text lines
WALLPAPER_LINE2="$AIRPLAY_NAME"
if [[ "$AUTO_SHUTDOWN" == "y" ]]; then
  SHUTDOWN_DISPLAY_TIME=$(date -d "+$SHUTDOWN_HOURS hours" +"%-d/%-m/%Y @ %-l:%M %p")
  WALLPAPER_LINE3="Will auto shutdown at $SHUTDOWN_DISPLAY_TIME"
else
  WALLPAPER_LINE3=""
fi

cat <<EOF > /home/airplay/airplay-xfce-setup.sh
#!/bin/bash

# Set wallpaper
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$WALLPAPER_PATH"
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-style -s 3

# Hide desktop icons + panel
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-home -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-trash -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-removable -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-volumes -s false
xfconf-query -c xfce4-panel -p /panels/panel-1/autohide-behavior -s 2

# Disable display sleep and screen blanking
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/sleep-display-ac -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-on-suspend -s false
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -s false
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/blank-on-suspend -s false
EOF

chmod +x /home/airplay/airplay-xfce-setup.sh
chown airplay:airplay /home/airplay/airplay-xfce-setup.sh

# Create autostart entry for XFCE setup
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
echo "[8/11] Creating autostart entry for unclutter (auto-hide cursor)..."

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

# 9) Create wallpaper image with 2 or 3 lines
echo "[9/11] Creating wallpaper image..."
if [[ -z "$WALLPAPER_LINE3" ]]; then
  convert -size 1920x1080 xc:black -gravity center \
    -pointsize 48 -fill white -annotate +0-80 "Airplay Receiver Enabled" \
    -pointsize 36 -annotate +0+10 "$WALLPAPER_LINE2" \
    "$WALLPAPER_PATH"
else
  convert -size 1920x1080 xc:black -gravity center \
    -pointsize 48 -fill white -annotate +0-100 "Airplay Receiver Enabled" \
    -pointsize 36 -annotate +0+10 "$WALLPAPER_LINE2" \
    -pointsize 28 -annotate +0+60 "$WALLPAPER_LINE3" \
    "$WALLPAPER_PATH"
fi
chown airplay:airplay "$WALLPAPER_PATH"
echo "✅ Wallpaper image created."

# 10) Back up Plymouth theme and replace logo
echo "[10/11] Backing up Plymouth theme and replacing logo..."

PLYMOUTH_THEME_DIR="/usr/share/plymouth/themes/xubuntu-logo"
BACKUP_DIR="/usr/share/plymouth/themes/xubuntu-logo-backup"

if [ ! -d "$BACKUP_DIR" ]; then
  cp -r "$PLYMOUTH_THEME_DIR" "$BACKUP_DIR"
  echo "✅ Plymouth theme backup created at $BACKUP_DIR"
else
  echo "ℹ️ Plymouth theme backup already exists. Skipping backup."
fi

CUSTOM_LOGO="/tmp/airplay-receiver-logo.png"
convert -size 400x150 xc:none -gravity center \
  -pointsize 48 -fill white -annotate +0+0 "Airplay Receiver" \
  "$CUSTOM_LOGO"

LOGO_PATH="$PLYMOUTH_THEME_DIR/logo.png"
if [ -f "$LOGO_PATH" ]; then
  cp "$CUSTOM_LOGO" "$LOGO_PATH"
  echo "✅ Plymouth logo replaced with custom Airplay Receiver logo."
else
  echo "⚠️ Plymouth logo image not found at $LOGO_PATH. Skipping logo replacement."
fi

echo "Updating initramfs..."
update-initramfs -u
echo "✅ initramfs updated."

# 11) Create auto-shutdown script for airplay user (runs at login)
echo "[11/11] Creating auto-shutdown script for user login..."

cat <<EOF > /home/airplay/auto-shutdown.sh
#!/bin/bash
AUTO_SHUTDOWN="$AUTO_SHUTDOWN"
SHUTDOWN_HOURS="$SHUTDOWN_HOURS"

if [[ "\$AUTO_SHUTDOWN" == "y" ]]; then
  shutdown_minutes=\$((SHUTDOWN_HOURS * 60))
  echo "Scheduling shutdown in \$SHUTDOWN_HOURS hour(s) at user login..."
  sudo /sbin/shutdown -h +\$shutdown_minutes
fi
EOF

chmod +x /home/airplay/auto-shutdown.sh
chown airplay:airplay /home/airplay/auto-shutdown.sh

cat <<EOF > /home/airplay/.config/autostart/auto-shutdown.desktop
[Desktop Entry]
Type=Application
Exec=/home/airplay/auto-shutdown.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Auto Shutdown Scheduler
Comment=Schedule shutdown on login
EOF

chown airplay:airplay /home/airplay/.config/autostart/auto-shutdown.desktop
echo "✅ Auto-shutdown scheduled on user login."

# 12) Setup sudoers to allow passwordless shutdown for 'airplay'
echo "[*] Setting sudoers for passwordless shutdown for user 'airplay'..."
echo 'airplay ALL=(ALL) NOPASSWD: /sbin/shutdown' > /etc/sudoers.d/airplay-shutdown
chmod 440 /etc/sudoers.d/airplay-shutdown
echo "✅ Sudoers updated."

echo "🎉 Setup complete! Please reboot the system to apply all changes."

read -rp "🔄 Do you want to reboot now? (y/N): " REBOOT_NOW
REBOOT_NOW=${REBOOT_NOW,,} # lowercase
if [[ "$REBOOT_NOW" == "y" || "$REBOOT_NOW" == "yes" ]]; then
  echo "Rebooting now..."
  reboot
else
  echo "Exiting without reboot. Remember to reboot later to apply changes."
  exit 0
fi
