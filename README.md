# 🛰️ AirPlay Receiver Setup for Xubuntu

This project sets up an **AirPlay receiver** on a Xubuntu system using `uxplay`. It configures a dedicated user account, autologin, and a clean display environment tailored & dedicated for AirPlay use.

> ⚠️ **Warning:**  
> This script will take over the machine and dedicate it exclusively as an AirPlay receiver.  
> It configures autologin, disables desktop features, and schedules automatic shutdowns.  
> **If you do not want your system to be fully dedicated for this purpose, do NOT run this script.**

---

## 📋 Requirements

- Xubuntu (tested on 22.04+) [https://xubuntu.org/download/](Download) | [https://xubuntu.github.io/xubuntu-docs/user/C/installation.html](Install Guide)
- Internet connection
- Sudo privileges
- A machine you can dedicate to this purpose

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
- Sets a custom wallpaper displaying “Airplay Receiver enabled” and scheduled shutdown time
- Replaces the xubuntu logo with "Airplay Receiver"

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

## ⚡ Auto-Starting the PC

To make your AirPlay receiver fully hands-free, consider one of the following ways to automatically power on the system each day:

### ✅ Wake-on-LAN (WOL)
- Enable **Wake-on-LAN** in your BIOS/UEFI settings.
- Use another device on the same network to send a WOL magic packet.
- This method requires the device to remain connected to power and the network while shut down.

### ✅ Powerboard Timer (Recommended)
- Use a **smart plug** or **powerboard timer** to supply power at a scheduled time each day.
- Set your BIOS/UEFI to **"Power On After Power Loss"** or **"Restore on AC Power Loss"**.
- The PC will automatically boot when power is restored.

### ✅ Manual Power On
- Simply press the power button each day to start the receiver manually.
- This is the least automated method but requires no configuration.

> 💡 **Tip:** For most kiosk or display use-cases, a powerboard timer combined with BIOS auto-boot is the most reliable and low-maintenance option.

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

