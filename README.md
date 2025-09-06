# 🎮 Modern Minecraft Server Management

A clean, modern solution for managing Minecraft servers with **Crafty Controller** - a web-based management panel that makes server administration easy and intuitive.

## ✨ **What You Get**

- 🌐 **Web-based GUI** - Manage your server from any device
- 👥 **User Management** - Admin and user roles with secure login
- 🗺️ **Easy World Management** - Upload, swap, and manage worlds through the web interface
- 🔄 **Automated Backups** - Daily backups with easy restore
- 🐳 **Docker-based** - Clean, isolated, and portable
- 📊 **Real-time Monitoring** - Server stats, logs, and console access
- 🔌 **Plugin Management** - Install/manage plugins through the web interface
- 🚀 **One-click Deployment** - Simple EC2 deployment script

## 🚀 **Quick Start**

### **GitHub Actions Deployment (Recommended)**
```bash
# Push to main branch or trigger manually
git push origin main

# Or trigger manually via GitHub Actions tab
# The workflow will automatically deploy to your EC2 instance
```

### **Local Development**
```bash
# Clone and setup
git clone <your-repo>
cd minecraft-server

# Start the server management panel
./setup.sh

# Access at http://localhost:8000
# Default login: admin/admin
```

### **Manual EC2 Deployment**
```bash
# Deploy to EC2 (interactive)
./deploy.sh

# Or with parameters
./deploy.sh --host 1.2.3.4 --key ~/.ssh/my-key.pem
```

## 📁 **Project Structure**

```
minecraft-server/
├── docker-compose.yml    # Docker services configuration
├── nginx.conf           # Reverse proxy configuration
├── setup.sh            # Local setup script
├── deploy.sh           # Manual EC2 deployment script
├── deploy-github-actions.sh # GitHub Actions deployment script
├── backup.sh           # Automated backup script
├── .github/workflows/deploy.yml # GitHub Actions workflow
├── README.md           # This file
├── EC2_DEPLOYMENT.md  # EC2 deployment guide
├── MIGRATION_GUIDE.md  # Migration from old system
├── backups/           # Backup storage directory
├── maps/             # Custom world storage
└── ssl/              # SSL certificates (optional)
```

## 🔧 **GitHub Actions Setup**

### **Required Secrets**
Configure these secrets in your GitHub repository settings:

1. **EC2_HOST** - Your EC2 instance IP or hostname
2. **EC2_USER** - SSH username (usually `ubuntu`)
3. **SSH_PRIVATE_KEY** - Your EC2 SSH private key content

### **How to Set Secrets**
1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the exact names above

### **Deployment Triggers**
- **Automatic**: Push to `main` branch
- **Manual**: Go to **Actions** tab → **Deploy Minecraft Server** → **Run workflow**

### **Workflow Features**
- ✅ **Clean Deployment** - Stops old services, deploys new ones
- ✅ **Docker Installation** - Automatically installs Docker if needed
- ✅ **Firewall Configuration** - Sets up UFW with required ports
- ✅ **Automated Backups** - Configures daily backups
- ✅ **Health Checks** - Verifies deployment success
- ✅ **Status Notifications** - Reports success/failure

## 🎯 **Key Features**

### **Web Management Panel**
- **Dashboard** - Overview of all servers and their status
- **Server Console** - Real-time server logs and command execution
- **File Manager** - Edit server files directly in the browser
- **Player Management** - Ban, kick, whitelist players
- **Plugin Management** - Install and configure plugins
- **World Management** - Upload, download, and swap worlds

### **Security Features**
- **Role-based Access** - Admin and user permissions
- **Rate Limiting** - Protection against brute force attacks
- **SSL Support** - HTTPS encryption (optional)
- **Firewall Integration** - Automatic port configuration

### **Automation**
- **Automated Backups** - Daily backups with retention policy
- **Auto-restart** - Server auto-restart on failure
- **Resource Monitoring** - CPU, memory, and disk usage tracking

## 🔧 **Management Commands**

### **Docker Commands**
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Update services
docker-compose pull && docker-compose up -d
```

### **Backup Management**
```bash
# Manual backup
./backup.sh

# View backup logs
tail -f /var/log/minecraft-backup.log

# List backups
ls -la backups/
```

## 🌐 **Access Points**

- **Web Panel**: `http://your-server:8000`
- **Minecraft Server**: `your-server:25565`
- **RCON**: `your-server:25575`

## 🔐 **Security Setup**

### **Change Default Password**
1. Login to web panel with `admin/admin`
2. Go to Settings → Users
3. Change admin password
4. Create additional users as needed

### **Enable SSL (Optional)**
1. Place SSL certificates in `ssl/` directory
2. Update `nginx.conf` to enable HTTPS
3. Restart services: `docker-compose restart`

### **Firewall Configuration**
The deployment script automatically configures UFW with:
- Port 22 (SSH)
- Port 80 (HTTP)
- Port 443 (HTTPS)
- Port 25565 (Minecraft)
- Port 25575 (RCON)
- Port 8000 (Web Panel)

## 📊 **Monitoring & Logs**

### **Server Logs**
```bash
# View Crafty Controller logs
docker-compose logs -f crafty-controller

# View Minecraft server logs (through web panel)
# Or via file manager in web interface
```

### **System Monitoring**
- **Resource Usage**: Available in web panel dashboard
- **Player Count**: Real-time player statistics
- **Server Performance**: TPS and memory usage

## 🗺️ **World Management**

### **Upload Custom World**
1. Access web panel
2. Go to File Manager
3. Navigate to server world directory
4. Upload your world files
5. Restart server to apply changes

### **World Backup**
- Automatic daily backups
- Manual backup via web interface
- Easy restore from backup list

## 🔌 **Plugin Management**

### **Install Plugins**
1. Download plugin JAR files
2. Use web panel File Manager
3. Upload to `plugins/` directory
4. Restart server

### **Recommended Plugins**
- **EssentialsX** - Essential commands and features
- **WorldEdit** - World editing tools
- **LuckPerms** - Permission management
- **Dynmap** - Web-based map viewer

## 🚨 **Troubleshooting**

### **Common Issues**

**Server won't start:**
```bash
# Check logs
docker-compose logs crafty-controller

# Check port availability
netstat -tlnp | grep 25565
```

**Can't access web panel:**
```bash
# Check if service is running
docker ps | grep crafty-controller

# Check firewall
sudo ufw status
```

**Backup issues:**
```bash
# Check backup script permissions
ls -la backup.sh

# Check cron job
crontab -l
```

### **Reset Everything**
```bash
# Stop and remove all containers
docker-compose down -v

# Remove all data (WARNING: This deletes everything!)
sudo rm -rf backups/ maps/

# Start fresh
./setup.sh
```

## 📈 **Performance Optimization**

### **Server Settings**
- **Memory**: Adjust `-Xmx` and `-Xms` in server properties
- **View Distance**: Reduce for better performance
- **Entity Limits**: Configure in server.properties

### **Docker Resources**
- **CPU Limits**: Add to docker-compose.yml if needed
- **Memory Limits**: Configure container memory limits
- **Storage**: Use SSD storage for better performance

## 🔄 **Updates & Maintenance**

### **Update Crafty Controller**
```bash
docker-compose pull
docker-compose up -d
```

### **Update Minecraft Server**
1. Use web panel to download new server JAR
2. Replace server.jar in File Manager
3. Restart server

### **System Updates**
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker
sudo apt install docker-ce docker-ce-cli containerd.io
```

## 🆘 **Support**

### **Documentation**
- [Crafty Controller Docs](https://craftycontrol.com/docs)
- [Docker Compose Reference](https://docs.docker.com/compose/)

### **Community**
- [Crafty Controller Discord](https://discord.gg/crafty)
- [Minecraft Server Admin Forums](https://www.spigotmc.org/)

---

## 🎉 **You're All Set!**

Your modern Minecraft server management system is ready! Enjoy the clean, intuitive web interface and powerful automation features.

**Happy Gaming! 🎮**