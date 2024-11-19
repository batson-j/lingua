#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
#SBATCH --job-name=env_creation
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gres=gpu:8
#SBATCH --exclusive
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=128
#SBATCH --mem=0
#SBATCH --time=01:00:00

# Exit immediately if a command exits with a non-zero status
set -e

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting environment setup script..."

# Start timer
start_time=$(date +%s)

# Get system architecture
log "Detecting system architecture..."
arch=$(uname -m)
case $arch in
    "x86_64")
        miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
        log "Detected x86_64 architecture"
        ;;
    "aarch64")
        miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"
        log "Detected aarch64 architecture"
        ;;
    *)
        log "ERROR: Unsupported architecture: $arch"
        exit 1
        ;;
esac

# Check if conda is installed
if ! command -v conda &> /dev/null; then
    log "Conda not found. Installing Miniconda..."
    log "Downloading Miniconda from $miniconda_url"
    
    # Download Miniconda installer
    wget $miniconda_url -O miniconda.sh
    
    log "Installing Miniconda..."
    # Install Miniconda
    bash miniconda.sh -b -p $HOME/miniconda
    
    log "Cleaning up installer..."
    # Remove installer
    rm miniconda.sh
    
    log "Initializing conda for bash..."
    # Initialize conda for bash
    $HOME/miniconda/bin/conda init bash
    
    log "Sourcing bash environment..."
    # Source bashrc to update environment
    source ~/.bashrc
    
    log "Miniconda installation completed successfully!"
else
    log "Conda is already installed at: $(which conda)"
fi

# Get the current date
current_date=$(date +%y%m%d)

# Create environment name with the current date
env_prefix=lingua
log "Creating conda environment: $env_prefix"

# Create the conda environment
eval "$(conda shell.bash hook)"
conda create -n $env_prefix python=3.11 -y -c anaconda
conda activate $env_prefix
log "Successfully created and activated environment: $env_prefix"
log "Python location: $(which python)"
log "Python version: $(python --version)"

log "Installing PyTorch and related packages..."
pip install torch==2.5.1 xformers --index-url https://download.pytorch.org/whl/cu124
log "PyTorch installation completed"

log "Installing ninja build system..."
pip install ninja

log "Installing requirements from requirements.txt..."
pip install --requirement requirements.txt
log "All requirements installed successfully"

# End timer
end_time=$(date +%s)

# Calculate elapsed time in seconds
elapsed_time=$((end_time - start_time))

# Convert elapsed time to minutes
elapsed_minutes=$((elapsed_time / 60))

log "Environment setup completed successfully!"
log "Total setup time: $elapsed_minutes minutes"
log "Environment name: $env_prefix"
log "Python path: $(which python)"
log "Conda environment path: $CONDA_PREFIX"