# Uptime Kuma Deployment on Proxmox

## Introduction
Uptime Kuma is an open-source status monitoring solution that allows you to easily check the uptime of your websites and services.

## Prerequisites
- Proxmox VE installed on your nodes.
- Basic understanding of Linux command-line.
- Sufficient resources allocated for LXC containers.

## Installation of Uptime Kuma
1. **Create LXC Container**: 
   - Go to Proxmox web interface.
   - Create a new LXC container with suitable resources (at least 1 CPU and 1GB of RAM).
2. **Access the container**: 
   - SSH into your LXC container or use the Proxmox console.
3. **Install Docker**: 
   ```bash
   apt update && apt upgrade -y
   apt install -y docker.io
   systemctl start docker
   systemctl enable docker
   ```
4. **Deploy Uptime Kuma using Docker**:
   ```bash
   docker run -d \
     --restart unless-stopped \
     -p 3001:3001 \
     -v uptime-kuma:/app/data \
     louislam/uptime-kuma
   ```

## Configuration
- Access Uptime Kuma from your web browser at `http://<container-ip>:3001`.
- Set the desired admin password and initial setup settings.

## Telegram Setup
1. **Create a Telegram Bot**:
   - Talk to [BotFather](https://t.me/botfather) on Telegram to create a new bot.
   - Take the token from the BotFather.
2. **Get your Chat ID**:
   - Send a message to your bot and use the following URL to find your chat ID:
   ```
   https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
   ```
3. **Configure Uptime Kuma for Telegram**:
   - Go to settings in Uptime Kuma.
   - Choose notifications and select Telegram.
   - Provide the bot token and chat ID.

## Optimized Alert Template
- Here is the optimized alert template to use:
```json
{
  "title": "Uptime Alert - {{name}}",
  "message": "{{name}} is {{status}} at {{time}}",
  "color": "{{#if (eq status \"down\")}}#ff0000{{else}}#00ff00{{/if}}"
}
```

This template will help you send clear and actionable alerts via Telegram whenever a service goes down or comes back online.

## Conclusion
With this guide, you can successfully set up Uptime Kuma in Proxmox LXC containers and use Telegram for alert notifications. Enjoy monitoring your services!