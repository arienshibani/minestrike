# EC2 Setup - GitHub Actions Handles Everything!

## 🚀 **Automatic Fresh Deployment**

The GitHub Actions workflow now **automatically handles fresh EC2 instances**! No manual setup required.

### ✅ **What GitHub Actions Does Automatically:**

1. **📦 Updates system packages** (apt update/upgrade)
2. **☕ Installs Java 17** (if not present)
3. **👤 Creates minecraft user** (if not exists)
4. **📁 Creates directory structure** (/opt/minecraft/, etc.)
5. **📥 Downloads Paper server** (latest build)
6. **⚙️ Sets up systemd service** (auto-start on boot)
7. **🔥 Configures firewall** (ports 22, 25565, 25575)
8. **🎮 Starts Minecraft server** with your de_dust2 map
9. **🔍 Verifies deployment** (checks status, ports, etc.)

### 🎯 **All You Need:**

1. **EC2 instance running** (Ubuntu 20.04+)
2. **Security group configured** (ports 22, 25565, 25575)
3. **GitHub Secrets set** (EC2_HOST, EC2_USER, SSH_PRIVATE_KEY)
4. **Push to main branch** → Automatic deployment!

### 🚫 **No Manual Setup Required:**

- ❌ No need to upload scripts manually
- ❌ No need to SSH and run setup commands
- ❌ No need to configure anything manually
- ✅ **Just push to GitHub and it works!**

### 🔄 **How It Works:**

1. **Push to main branch** triggers GitHub Actions
2. **Creates deployment package** (excludes unnecessary files)
3. **Uploads to EC2** via SSH
4. **Runs fresh deployment** (handles everything automatically)
5. **Verifies deployment** and reports status
6. **Your de_dust2 server is live!**

### 🎮 **Ready to Deploy:**

Your next push to the main branch will automatically:
- Set up the entire EC2 instance from scratch
- Deploy your de_dust2 map
- Start the Minecraft server
- Make it accessible to players

**No manual intervention needed!** 🚀
