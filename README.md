# 🎮 MineStrike - Minecraft Server with Auto-Deployment

[![Deploy to EC2](https://github.com/yourusername/minestrike/actions/workflows/deploy.yml/badge.svg)](https://github.com/yourusername/minestrike/actions/workflows/deploy.yml)

A complete Minecraft server setup with **automatic deployment** to AWS EC2 via GitHub Actions. Features mod support, automated backups, and production-ready configuration.

## ✨ Features

- 🚀 **One-click deployment** to EC2 via GitHub Actions
- 🎯 **Mod support** (Fabric, Forge, Bukkit/Spigot)
- 🔄 **Automatic backups** with retention policies
- 🛡️ **Production-ready** security and monitoring
- 📊 **Real-time logging** and status monitoring
- 🔧 **Easy management** with interactive scripts
- ☁️ **Scalable** EC2 deployment with systemd

## Project Structure

```
minestrike/
├── scripts/
│   ├── setup.sh              # Local development setup
│   ├── server.sh              # Server management (start/stop/restart)
│   ├── deploy-ec2.sh          # EC2 deployment script
│   ├── minecraft-server.service # Systemd service file
│   ├── test-port.sh           # Port accessibility testing
│   └── install-mod.sh         # Mod installation helper
├── server/
│   ├── server.properties      # Server configuration
│   ├── eula.txt              # EULA agreement
│   ├── mods/                 # Mod files directory
│   ├── plugins/              # Plugin files directory
│   ├── world/                # World data directory
│   └── config/               # Additional config files
└── logs/                     # Server logs directory
```

## Local Development Setup

### Prerequisites

- **Java 17 or higher** (OpenJDK recommended)
- **Screen** (for background server management)
- **curl or wget** (for downloading server files)
- **netcat** (for port testing)

### Quick Start

1. **Run the setup script:**
   ```bash
   ./scripts/setup.sh
   ```

2. **Start the server:**
   ```bash
   ./scripts/server.sh start
   ```

3. **Test the server:**
   ```bash
   ./scripts/test-port.sh
   ```

4. **Attach to server console:**
   ```bash
   screen -r minecraft-server
   ```

### Server Management Commands

```bash
# Start server
./scripts/server.sh start

# Stop server
./scripts/server.sh stop

# Restart server
./scripts/server.sh restart

# Check status
./scripts/server.sh status

# View logs
./scripts/server.sh logs
```

### Installing Mods

```bash
# Install mod from URL
./scripts/install-mod.sh https://example.com/mod.jar

# Install mod from local file
./scripts/install-mod.sh /path/to/mod.jar
```

### Testing Port Accessibility

The `test-port.sh` script checks if port 25565 is accessible:

```bash
./scripts/test-port.sh
```

You can also test from another machine:
```bash
# Test with netcat
nc -z YOUR_SERVER_IP 25565

# Test with telnet
telnet YOUR_SERVER_IP 25565
```

## 🚀 Automatic Deployment to EC2

### Prerequisites

- AWS EC2 instance running Ubuntu 20.04 or later
- Security group configured (see below)
- GitHub repository with Actions enabled

### Security Group Configuration

Create a security group with the following rules:

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | Your IP | SSH access |
| Custom TCP | TCP | 25565 | 0.0.0.0/0 | Minecraft server |
| Custom TCP | TCP | 25575 | Your IP | RCON (optional) |

### GitHub Secrets Setup

Add these secrets to your GitHub repository:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add the following secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `EC2_HOST` | Your EC2 instance IP or domain | `54.123.45.67` |
| `EC2_USER` | EC2 username | `ubuntu` |
| `SSH_PRIVATE_KEY` | Your EC2 SSH private key | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

### Automatic Deployment

Once configured, **every push to main branch** will automatically:

1. ✅ Create a deployment package
2. ✅ Upload to EC2
3. ✅ Stop the server gracefully
4. ✅ Create a backup
5. ✅ Deploy new version
6. ✅ Start the server
7. ✅ Verify deployment

### Manual Deployment

You can also trigger deployment manually:

1. Go to **Actions** tab in GitHub
2. Select **Deploy to EC2** workflow
3. Click **Run workflow**

### Manual EC2 Setup (First Time)

For initial EC2 setup, run this once:

```bash
# Upload deployment script
scp -i your-key.pem scripts/deploy-ec2.sh ubuntu@your-ec2-ip:~/
scp -i your-key.pem scripts/minecraft-server.service ubuntu@your-ec2-ip:~/

# SSH to EC2 and run setup
ssh -i your-key.pem ubuntu@your-ec2-ip
sudo ./deploy-ec2.sh
```

### EC2 Management Commands

```bash
# Start server
sudo systemctl start minecraft-server

# Stop server
sudo systemctl stop minecraft-server

# Restart server
sudo systemctl restart minecraft-server

# Check status
sudo systemctl status minecraft-server

# View logs
sudo journalctl -u minecraft-server -f

# Test port
sudo -u minecraft /opt/minecraft/scripts/test-port.sh
```

### Manual Server Management (EC2)

If you prefer using screen sessions instead of systemd:

```bash
# Start server manually
sudo -u minecraft /opt/minecraft/scripts/server.sh start

# Stop server manually
sudo -u minecraft /opt/minecraft/scripts/server.sh stop

# Attach to console
screen -r minecraft-server
```

## Configuration

### Server Properties

Edit `server/server.properties` to configure:

- **Server name and MOTD**
- **Game mode and difficulty**
- **Player limits**
- **World settings**
- **RCON password** (change from default!)

### Java Options

The server uses optimized JVM settings for performance:

- **Memory:** 4GB max, 2GB initial
- **GC:** G1GC with optimized settings
- **Performance:** Various JVM optimizations

You can modify these in the scripts if needed.

### Mod Support

The server is configured to support:

- **Fabric mods** (place in `server/mods/`)
- **Forge mods** (place in `server/mods/`)
- **Bukkit/Spigot plugins** (place in `server/plugins/`)

## Troubleshooting

### Common Issues

1. **Port not accessible:**
   - Check firewall settings
   - Verify server is running
   - Test with `test-port.sh`

2. **Server won't start:**
   - Check Java version (must be 17+)
   - Verify server jar exists
   - Check logs for errors

3. **Mods not loading:**
   - Ensure mods are compatible with server version
   - Check mod dependencies
   - Restart server after adding mods

4. **Performance issues:**
   - Adjust JVM memory settings
   - Reduce view distance
   - Limit player count

### Log Locations

- **Local:** `logs/` directory
- **EC2:** `/opt/minecraft/logs/` or `journalctl -u minecraft-server`

### Getting Help

- Check server logs for error messages
- Verify all prerequisites are installed
- Test port accessibility
- Ensure proper file permissions

## Security Considerations

1. **Change default passwords** (RCON password in server.properties)
2. **Use whitelist** for production servers
3. **Regular backups** of world data
4. **Keep server updated** with latest Paper builds
5. **Monitor server logs** for suspicious activity

## Backup Strategy

### Local Backup

```bash
# Backup world data
tar -czf backup-$(date +%Y%m%d).tar.gz server/world/

# Backup entire server
tar -czf server-backup-$(date +%Y%m%d).tar.gz server/
```

### EC2 Backup

```bash
# Backup world data
sudo tar -czf /opt/backups/world-$(date +%Y%m%d).tar.gz /opt/minecraft/server/world/

# Backup entire server
sudo tar -czf /opt/backups/server-$(date +%Y%m%d).tar.gz /opt/minecraft/server/
```

## Performance Optimization

### JVM Tuning

Adjust memory settings based on your server:

- **Small server (1-5 players):** `-Xmx2G -Xms1G`
- **Medium server (5-15 players):** `-Xmx4G -Xms2G`
- **Large server (15+ players):** `-Xmx8G -Xms4G`

### Server Settings

Optimize `server.properties`:

- **view-distance:** Lower for better performance
- **simulation-distance:** Adjust based on needs
- **max-tick-time:** Increase if experiencing lag

## License

This project is provided as-is for educational and personal use. Minecraft is a trademark of Mojang Studios.
