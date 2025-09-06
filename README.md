# Paper Minecraft Server

A simple, automated Paper Minecraft server deployment to EC2 with GitHub Actions.

## ✨ **What You Get**

- 🎮 **Paper Server** - High-performance Minecraft server
- 🚀 **Auto-Deploy** - Push to main = server restarts with new config
- 🔧 **Simple Management** - All config in this repository
- 📁 **Clean Structure** - Plugins, worlds, config all organized
- 🔄 **Zero Downtime** - Automatic restarts and updates

## 🚀 **How It Works**

1. **Edit config** in this repository
2. **Push to main** branch
3. **GitHub Actions** automatically:
   - Stops the server
   - Downloads latest Paper
   - Deploys new config
   - Restarts the server
4. **Server is updated** with your changes

## 📁 **Repository Structure**

```
minestrike/
├── .github/workflows/deploy.yml  # GitHub Actions workflow
├── deploy-paper.sh              # Deployment script
├── server/
│   ├── server.properties        # Server configuration
│   ├── plugins/                 # Plugin JAR files
│   ├── worlds/                  # Custom worlds (de_dust2, etc.)
│   └── config/                  # Plugin configurations
└── README.md                    # This file
```

## 🔧 **GitHub Actions Setup**

### **Required Secrets**
Configure these secrets in your GitHub repository:

1. **EC2_HOST** - Your EC2 instance IP
2. **EC2_USER** - SSH username (usually `ubuntu`)
3. **SSH_PRIVATE_KEY** - Your EC2 SSH private key content

### **Deployment Triggers**
- **Automatic**: Push to `main` branch
- **Manual**: Go to **Actions** tab → **Deploy Paper Minecraft Server** → **Run workflow**

## 🎮 **Server Management**

### **Access Your Server**
- **Minecraft Server**: `YOUR_EC2_IP:25565`
- **RCON**: `YOUR_EC2_IP:25575` (password: changeme123)

### **SSH Management Commands**
```bash
# Server control
sudo systemctl start minecraft-server
sudo systemctl stop minecraft-server
sudo systemctl restart minecraft-server
sudo systemctl status minecraft-server

# View logs
sudo journalctl -u minecraft-server -f

# Server directory
cd /opt/minecraft
```

## 🔌 **Adding Plugins**

1. **Download plugin JAR** files
2. **Place in** `server/plugins/` directory
3. **Commit and push** to main
4. **Server restarts** automatically with new plugins

## 🗺️ **Adding Custom Worlds**

1. **Download world files** (like de_dust2)
2. **Place in** `server/worlds/` directory
3. **Update** `server.properties` if needed
4. **Commit and push** to main
5. **Server restarts** with new worlds

## ⚙️ **Configuration**

### **Server Properties**
Edit `server/server.properties` to configure:
- Server name, MOTD, difficulty
- Player limits, spawn settings
- Performance optimizations
- Paper-specific settings

### **Plugin Configs**
Place plugin configuration files in `server/config/` directory.

## 🔄 **Workflow Features**

- ✅ **Clean Deployment** - Stops old server, deploys new one
- ✅ **Paper Download** - Automatically downloads latest Paper
- ✅ **Config Sync** - All config files synced from repository
- ✅ **Service Management** - Systemd service for reliability
- ✅ **Health Checks** - Verifies deployment success
- ✅ **Status Notifications** - Reports success/failure

## 🚨 **Troubleshooting**

### **Server Won't Start**
```bash
# Check service status
sudo systemctl status minecraft-server

# View logs
sudo journalctl -u minecraft-server -f

# Check server directory
ls -la /opt/minecraft/
```

### **Can't Connect**
1. **Check AWS Security Group** - Port 25565 must be open
2. **Verify server is running** - `sudo systemctl status minecraft-server`
3. **Check Minecraft version** - Must match server version

### **GitHub Actions Fails**
1. **Check GitHub Secrets** are configured correctly
2. **Verify EC2 instance** is running and accessible
3. **Check GitHub Actions logs** for specific errors

## 🎯 **CS2 Crossover Setup**

### **Recommended Plugins**
- **EssentialsX** - Commands, spawns, kits
- **WorldEdit** - Map building and import
- **WorldGuard** - Area protection
- **TeamManager** - Team-based gameplay
- **KitPvP** - Pre-defined gear sets

### **Setup Steps**
1. **Add plugins** to `server/plugins/`
2. **Upload de_dust2 world** to `server/worlds/`
3. **Configure teams** and spawn points
4. **Set up gear kits** for each team
5. **Push to main** - Server updates automatically!

## 🔒 **Security**

- **RCON Password**: Change `rcon.password` in server.properties
- **Whitelist**: Enable `whitelist=true` for private servers
- **Online Mode**: Keep `online-mode=true` for authentication

---

## 🎉 **You're Ready!**

Your Paper Minecraft server is now managed entirely through this repository. Any changes you make and push to main will automatically update your server!

**Happy Gaming! 🎮**