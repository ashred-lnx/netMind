#!/bin/bash

# Automate cl-support cleanup and generation process
# This script should be run from the netMind directory on the switch

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [[ ! -d "Data" ]] || [[ ! -f ".git/config" ]]; then
    print_error "This script must be run from the netMind repository root directory"
    exit 1
fi

# Get the hostname for cl-support file naming
HOSTNAME=$(hostname)
CL_SUPPORT_DIR="/home/cumulus/netMind/Data"

# Generate timestamp for commit messages
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

print_step "Starting cl-support automation process..."

# Step 1: Git pull
print_step "Pulling latest changes from remote..."
if sudo git pull; then
    print_info "Git pull completed successfully"
else
    print_error "Git pull failed"
    exit 1
fi

# Step 2: Clean up old cl-support files
print_step "Cleaning up old cl-support files..."

# Remove analysis.txt if it exists
if [[ -f "Analysis/analysis.txt" ]]; then
    sudo rm -f Analysis/analysis.txt
    print_info "Removed analysis.txt"
fi

# Remove old cl-support .txz files (keep README)
if ls Data/cl_support_*.txz 1> /dev/null 2>&1; then
    sudo rm -f Data/cl_support_*.txz
    print_info "Removed old cl-support .txz files"
fi

# Check if there are any changes to commit
print_step "Checking for changes to commit..."
if sudo git status --porcelain | grep -q .; then
    print_info "Found changes to commit"
    
    # Step 3: Commit cleanup
    print_step "Committing cleanup changes..."
    sudo git add .
    sudo git commit -m "cleanup previous data and analysis - $TIMESTAMP"
    print_info "Cleanup committed successfully"
else
    print_info "No changes to commit for cleanup"
fi

# Step 4: Generate new cl-support file
print_step "Generating new cl-support file..."
if sudo cl-support -S "$CL_SUPPORT_DIR/"; then
    print_info "cl-support file generated successfully"
else
    print_error "Failed to generate cl-support file"
    exit 1
fi

# Step 5: Check for new files and commit
print_step "Committing new cl-support file..."
if sudo git status --porcelain | grep -q .; then
    sudo git add .
    sudo git commit -m "updating latest cl-support - $TIMESTAMP"
    print_info "New cl-support file committed successfully"
else
    print_info "No new files to commit"
fi

# Step 6: Push changes
print_step "Pushing changes to remote..."
if sudo git push; then
    print_info "Changes pushed successfully"
else
    print_error "Failed to push changes"
    exit 1
fi

print_step "cl-support automation completed successfully!"

# Show the latest cl-support file
print_info "Latest cl-support file:"
ls -lrt Data/cl_support_*.txz 2>/dev/null | tail -1 || print_info "No cl-support files found"

print_info "Process completed successfully!"
