# 🚀 EC2 Deployment Guide

This guide covers both **GitHub Actions automated deployment** (recommended) and **manual deployment** options for your modern Minecraft server management system.

## 📋 **Prerequisites**

- AWS EC2 instance running Ubuntu 20.04+
- SSH key pair for EC2 access
- Security group configured with required ports
- GitHub repository with secrets configured (for automated deployment)

## 🔧 **Security Group Configuration**

Configure your EC2 security group to allow these ports:

| Port | Protocol | Source | Description |
|------|----------|--------|-------------|
| 22 | TCP | Your IP | SSH access |
| 80 | TCP | 0.0.0.0/0 | HTTP (web panel) |
| 443 | TCP | 0.0.0.0/0 | HTTPS (web panel) |
| 25565 | TCP | 0.0.0.0/0 | Minecraft server |
| 25575 | TCP | Your IP | RCON (admin) |
| 23333 | TCP | Your IP | Direct web panel access |

## 🚀 **Deployment Options**

### **Option 1: GitHub Actions (Recommended)**

#### **Setup GitHub Secrets**
1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Add these secrets:
   - **EC2_HOST**: Your EC2 instance IP
   - **EC2_USER**: SSH username (usually `ubuntu`)
   - **SSH_PRIVATE_KEY**: Your EC2 SSH private key content

#### **Deploy**
```bash
# Push to main branch (triggers automatic deployment)
git push origin main

# Or trigger manually via GitHub Actions tab
# Go to Actions → Deploy Minecraft Server → Run workflow
```

#### **What GitHub Actions Does**
- ✅ **Clean Deployment** - Stops old services, deploys new ones
- ✅ **Docker Installation** - Automatically installs Docker if needed
- ✅ **Firewall Configuration** - Sets up UFW with required ports
- ✅ **Automated Backups** - Configures daily backups
- ✅ **Health Checks** - Verifies deployment success
- ✅ **Status Notifications** - Reports success/failure

### **Option 2: Manual Deployment**

#### **1. Prepare Your Local Environment**
```bash
# Ensure you have the deployment files
ls -la
# Should show: docker-compose.yml, setup.sh, deploy.sh, nginx.conf, backup.sh
```

#### **2. Run the Deployment Script**
```bash
# Interactive deployment
./deploy.sh

# Or with command line parameters
./deploy.sh --host YOUR_EC2_IP --key /path/to/your-key.pem
```

#### **3. Follow the Interactive Prompts**
The script will ask for:
- EC2 server IP or hostname
- Path to your SSH private key
- SSH username (default: ubuntu)

#### **4. Wait for Deployment**
The script will:
- ✅ Test SSH connection
- ✅ Install Docker and Docker Compose
- ✅ Deploy all necessary files
- ✅ Configure firewall
- ✅ Start Crafty Controller
- ✅ Setup automated backups

## 🌐 **Access Your Server**

After deployment completes (either method), you can access:

- **Web Management Panel**: `http://YOUR_EC2_IP:23333`
- **Minecraft Server**: `YOUR_EC2_IP:25565`

### **Default Login Credentials**
- **Username**: `admin`
- **Password**: `admin`

⚠️ **IMPORTANT**: Change the default password immediately after first login!

## 🔧 **Post-Deployment Setup**

### **1. Change Admin Password**
1. Open `http://YOUR_EC2_IP:23333`
2. Login with `admin/admin`
3. Go to Settings → Users
4. Change the admin password
5. Create additional users if needed

### **2. Create Your First Minecraft Server**
1. Click "Create Server" in the web panel
2. Choose server type (Paper recommended)
3. Configure server settings
4. Start the server

### **3. Upload Your Custom World**
1. Go to File Manager in the web panel
2. Navigate to your server's world directory
3. Upload your custom world files
4. Restart the server

## 🔍 **Verification**

### **Check Server Status**
```bash
# SSH to your EC2 instance
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Check if services are running
cd ~/minecraft-server
docker-compose ps

# Check logs
docker-compose logs -f
```

### **Test Minecraft Connection**
```bash
# Test if Minecraft port is accessible
nc -z YOUR_EC2_IP 25565

# Or use online tools like minecraft-server-status.com
```

## 🛠️ **Management Commands**

### **SSH Access**
```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
```

### **Server Management**
```bash
# Start services
cd ~/minecraft-server
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Restart services
docker-compose restart
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

## 🔒 **Security Best Practices**

### **1. Update System Regularly**
```bash
sudo apt update && sudo apt upgrade -y
```

### **2. Configure SSL (Optional)**
1. Obtain SSL certificates
2. Place them in `ssl/` directory
3. Update `nginx.conf` to enable HTTPS
4. Restart services

### **3. Firewall Configuration**
The deployment script automatically configures UFW, but you can verify:
```bash
sudo ufw status verbose
```

### **4. Regular Backups**
- Automated daily backups are configured
- Manual backups available through web panel
- Test restore procedures regularly

## 🚨 **Troubleshooting**

### **Common Issues**

**Can't access web panel:**
```bash
# Check if service is running
docker ps | grep crafty-controller

# Check firewall
sudo ufw status

# Check if port is listening
sudo netstat -tlnp | grep 8000
```

**Minecraft server won't start:**
```bash
# Check Minecraft server logs through web panel
# Or check Docker logs
docker-compose logs minecraft-server
```

**SSH connection issues:**
```bash
# Verify key permissions
chmod 600 your-key.pem

# Test connection
ssh -i your-key.pem -v ubuntu@YOUR_EC2_IP
```

**GitHub Actions deployment fails:**
1. Check GitHub Secrets are configured correctly
2. Verify EC2 instance is running and accessible
3. Check GitHub Actions logs for specific error messages
4. Ensure security group allows SSH access from GitHub Actions

### **Reset Everything**
```bash
# Stop all services
docker-compose down -v

# Remove all data (WARNING: This deletes everything!)
sudo rm -rf backups/ maps/

# Start fresh
./setup.sh
```

## 📊 **Monitoring**

### **Resource Monitoring**
- Use the web panel dashboard for real-time stats
- Monitor CPU, memory, and disk usage
- Set up alerts for resource thresholds

### **Log Monitoring**
```bash
# View system logs
sudo journalctl -u docker

# View application logs
docker-compose logs -f
```

### **GitHub Actions Monitoring**
- Check GitHub Actions tab for deployment status
- View workflow logs for detailed information
- Set up notifications for failed deployments

## 🔄 **Updates**

### **Update Crafty Controller**
```bash
cd ~/minecraft-server
docker-compose pull
docker-compose up -d
```

### **Update System**
```bash
sudo apt update && sudo apt upgrade -y
sudo reboot  # If kernel updates were installed
```

### **Update via GitHub Actions**
- Push changes to main branch
- GitHub Actions will automatically deploy updates
- Or trigger manually via GitHub Actions tab

## 💰 **Cost Optimization**

### **Instance Types**
- **t3.medium**: Good for small servers (1-10 players)
- **t3.large**: Better for medium servers (10-20 players)
- **c5.large**: High performance for large servers (20+ players)

### **Storage**
- Use GP3 EBS volumes for better performance
- Consider EBS optimization for better I/O

### **Auto-scaling**
- Use EC2 Auto Scaling for traffic spikes
- Consider Spot Instances for development/testing

---

## 🎉 **You're Ready!**

Your Minecraft server is now running on EC2 with a modern management interface! Choose between automated GitHub Actions deployment or manual deployment based on your preferences.

**Happy Gaming! 🎮**