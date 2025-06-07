# 🛰️ AirPlay Server Setup for Xubuntu

This project sets up an **AirPlay receiver** on a Xubuntu system using `uxplay`. It configures a dedicated user account, autologin, and a clean display environment tailored for AirPlay use.

> ⚠️ **Warning:**  
> This script will take over the machine and dedicate it exclusively as an AirPlay server.  
> It configures autologin, disables desktop features, and schedules automatic shutdowns.  
> **If you do not want your system to be fully dedicated for this purpose, do NOT run this script.**

---

## 📋 Requirements

- Xubuntu (tested on 22.04+)
- Internet connection
- Sudo privileges

---

## 🚀 Quick Start

### 1. Clone the repository and enter the folder:

```bash
git clone https://github.com/matthewratcliffe/airplay-server.git
cd airplay-server
```

### 2. Make the deployment script executable:

```bash
chmod +x deploy.sh
```

### 3. Run the deployment script with root privileges:

```bash
sudo bash deploy.sh
```

> ⚠️ The script must be run using `bash` (not `sh`) with root (sudo) privileges, or it will exit with an error.

---

## 🛠️ What This Script Does

- Checks for root privileges
- Updates system package lists
- Installs `uxplay`, `imagemagick`, and required GStreamer plugins
- Creates a dedicated `airplay` user with password `airplay` (change recommended)
- Enables autologin for `airplay` user via LightDM
- Configures `uxplay` to start automatically on login
- Redirects `uxplay` logs to `/tmp/airplay.log`
- Schedules automatic shutdown on user login (if enabled during setup)
- Hides all desktop icons for a clean AirPlay display
- Disables display sleep and screen blanking
- Sets a custom wallpaper displaying “Airplay server enabled” and scheduled shutdown time
- Replaces the xubuntu logo with "Airplay Server"

---

## 🔁 After Running

Reboot the system to apply all changes:

```bash
sudo reboot
```

On reboot:

- The system will autologin as the airplay user
- uxplay will start automatically, streaming AirPlay content
- The auto shutdown timer will be scheduled on login (if enabled)
- Logs from uxplay will be available at /tmp/airplay.log

---

## ⏰ Auto Shutdown

During setup, you can enable an automatic shutdown timer that will trigger a system shutdown after a specified number of hours. This timer is scheduled each time the airplay user logs in, ensuring the system shuts down even after reboots.

The scheduled shutdown time is displayed on the custom wallpaper.

---

## 🔐 Security Note

The `airplay` user is created with a default password (`airplay`). For security, especially on public or production devices, **change this password** immediately:

```bash
sudo passwd airplay
```

---

## 🧹 Uninstall / Cleanup

To remove the AirPlay setup, run:

```bash
sudo deluser --remove-home airplay
sudo apt-get remove --purge uxplay imagemagick
sudo rm /etc/xdg/autostart/uxplay.desktop
sudo rm /etc/lightdm/lightdm.conf.d/50-airplay.conf
sudo rm /home/airplay/auto-shutdown.sh
sudo rm /home/airplay/.config/autostart/auto-shutdown.desktop
```

---

## 📝 Troubleshooting

- If you encounter issues with autologin, check for conflicting settings in `/etc/lightdm/lightdm.conf` or other files under `/etc/lightdm/lightdm.conf.d/`.
- View AirPlay logs here for debugging:

```bash
cat /tmp/airplay.log
```

