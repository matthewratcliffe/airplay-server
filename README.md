# 🛰️ AirPlay Server Setup for Xubuntu

This project sets up an **AirPlay receiver** on a Xubuntu system using `uxplay`. It configures a dedicated user account, autologin, and a clean display environment tailored for AirPlay use.

## 📋 Requirements

- Xubuntu (tested on 22.04+)
- Internet connection
- Sudo privileges

---

## 🚀 Quick Start

### 1. Open Terminal (Ctrl+Alt+T) and run:

```bash
git clone https://github.com/matthewratcliffe/airplay-server.git
cd airplay-server
```
2. Make the deployment script executable:
```bash
Copy
Edit
chmod +x deploy.sh
```
3. Run the deployment script with sudo:
```bash
Copy
Edit
sudo ./deploy.sh
```
⚠️ This script must be run as root (via sudo) or it will exit with an error.

## 🛠️ What This Script Does
Verifies that it’s being run as root

Updates your system’s package list

Installs uxplay and imagemagick

Creates a new user called airplay with password airplay

Enables autologin for the airplay user using LightDM

Configures uxplay to run on system startup

Hides all desktop icons for a clean AirPlay display

Sets a custom wallpaper saying “Airplay server enabled”

## 🔁 After Running
Once the script completes:

Reboot the system:

bash
Copy
Edit
sudo reboot
On reboot, the system will auto-login as the airplay user and automatically start the AirPlay receiver.

## 🔐 Security Note
The user airplay is created with a default password (airplay). For production or public-facing devices, you should change this password:

bash
```
Copy
Edit
sudo passwd airplay
```

##🧹 To Uninstall
Manual steps required:

bash
Copy
Edit
sudo deluser --remove-home airplay
sudo apt-get remove --purge uxplay imagemagick
sudo rm /etc/xdg/autostart/uxplay.desktop
sudo rm /etc/lightdm/lightdm.conf.d/50-airplay.conf
