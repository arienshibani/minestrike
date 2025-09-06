# EC2 Initial Setup Commands

## Step 1: Upload the setup script to your EC2 instance

Replace `YOUR_EC2_IP` and `YOUR_KEY.pem` with your actual values:

```bash
# Upload the deployment script
scp -i YOUR_KEY.pem scripts/deploy-ec2.sh ubuntu@YOUR_EC2_IP:~/
scp -i YOUR_KEY.pem scripts/minecraft-server.service ubuntu@YOUR_EC2_IP:~/
```

## Step 2: SSH into your EC2 instance

```bash
ssh -i YOUR_KEY.pem ubuntu@YOUR_EC2_IP
```

## Step 3: Run the initial setup

Once you're SSH'd into the EC2 instance:

```bash
# Make the script executable
chmod +x deploy-ec2.sh

# Run the setup (this will take a few minutes)
sudo ./deploy-ec2.sh
```

## Step 4: Verify the setup

After the setup completes:

```bash
# Check if the service is running
sudo systemctl status minecraft-server

# Check if the server is accessible
sudo -u minecraft /opt/minecraft/scripts/test-port.sh
```

## Step 5: Test GitHub Actions deployment

Once the initial setup is complete, push a small change to trigger the GitHub Actions:

```bash
# Make a small change locally
echo "# Test deployment" >> README.md
git add README.md
git commit -m "Test EC2 deployment"
git push
```

The GitHub Actions should now work properly!
