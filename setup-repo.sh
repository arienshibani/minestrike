#!/bin/bash

# Repository Setup Script for MineStrike
# This script helps initialize the repository and set up GitHub Actions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install git first."
        exit 1
    fi
    print_status "Git is installed"
}

# Initialize git repository
init_git() {
    print_header "Initializing Git Repository"
    
    if [ -d ".git" ]; then
        print_warning "Git repository already exists"
        return
    fi
    
    git init
    print_status "Git repository initialized"
}

# Create initial commit
create_initial_commit() {
    print_header "Creating Initial Commit"
    
    # Add all files
    git add .
    
    # Create initial commit
    git commit -m "Initial commit: MineStrike Minecraft server with auto-deployment

- Complete server setup with mod support
- GitHub Actions for automatic EC2 deployment
- Production-ready configuration and monitoring
- Interactive management scripts
- Automated backup system"
    
    print_status "Initial commit created"
}

# Show next steps
show_next_steps() {
    print_header "Repository Setup Complete!"
    
    echo ""
    print_status "Next steps:"
    echo ""
    echo "1. Create a GitHub repository:"
    echo "   - Go to https://github.com/new"
    echo "   - Name it 'minestrike' (or your preferred name)"
    echo "   - Don't initialize with README (we already have one)"
    echo ""
    echo "2. Add remote origin:"
    echo "   git remote add origin https://github.com/YOUR_USERNAME/minestrike.git"
    echo ""
    echo "3. Push to GitHub:"
    echo "   git branch -M main"
    echo "   git push -u origin main"
    echo ""
    echo "4. Set up GitHub Secrets:"
    echo "   - Go to repository Settings → Secrets and variables → Actions"
    echo "   - Add EC2_HOST, EC2_USER, and SSH_PRIVATE_KEY"
    echo ""
    echo "5. Set up EC2 instance:"
    echo "   - Launch Ubuntu 20.04+ EC2 instance"
    echo "   - Configure security group (22, 25565, 25575)"
    echo "   - Run initial setup script"
    echo ""
    print_warning "Important: Update the GitHub Actions badge URL in README.md"
    print_warning "Replace 'yourusername' with your actual GitHub username"
}

# Main function
main() {
    print_header "MineStrike Repository Setup"
    
    check_git
    init_git
    create_initial_commit
    show_next_steps
}

# Run main function
main "$@"
