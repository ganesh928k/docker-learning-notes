# 🐧 Linux Essentials for Docker

Running Docker heavily relies on the host Linux kernel. Understanding how to manage system time, keep packages updated, and maintain a robust history is critical for DevOps.

## ⏱️ System Time Synchronization (Chrony)

Containers share the host kernel's clock. If the host time drifts, **all containers** will have incorrect timestamps. This causes issues with logs, SSL/TLS certificates, database transactions, and authentication tokens.

Modern Linux uses `chronyd` for NTP (Network Time Protocol) synchronization.

```bash
# Enable NTP synchronization
sudo timedatectl set-ntp true

# Enable and start the chronyd service
sudo systemctl enable --now chronyd

# Force an immediate time step (useful if time is way off)
sudo chronyc -a makestep

# Sync the hardware clock to the system time
sudo hwclock --systohc

# Verify the time and NTP status
timedatectl

# Check chrony tracking and sources
chronyc tracking
chronyc sources -v
```

## 📦 Package Management & Security Updates

Keeping Docker and the host OS updated is critical for security and features.

```bash
# Check for available updates
dnf check-update

# Update specifically Docker-related packages
dnf update 'docker*' -y

# Apply only security-related updates (great for production hosts)
dnf upgrade --security -y
```

## 📜 Enterprise Bash History

In a production environment, keeping an infinite, timestamped bash history helps track down exactly who ran what command and when.

Add these configurations to `/etc/profile.d/history.sh` or `~/.bashrc`:

```bash
# Timestamp format (YYYY-MM-DD HH:MM:SS)
export HISTTIMEFORMAT="%F %T "

# Maximum commands kept in memory and on disk
export HISTSIZE=50000
export HISTFILESIZE=100000

# Append history instead of overwriting
shopt -s histappend

# Save multiline commands as one history entry
shopt -s cmdhist

# Write history immediately and reload from disk (prevent loss on disconnect)
export PROMPT_COMMAND="history -a; history -c; history -r"
```

Apply the changes immediately:
```bash
source /etc/profile
```


---

*Navigation:*<br>[&larr; Previous Note](20-docker-compose-load-balancing.md) | [Next Note &rarr;](22-docker-swarm-setup.md)
