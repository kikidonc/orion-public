#!/bin/bash

# Variables

STATE_FILE="$HOME/.git_setup_state"

# Function to update the state file
update_state() {
    echo "$1" > "${STATE_FILE}"
}

# Function to read the state file
read_state() {
    if [ -f "${STATE_FILE}" ]; then
        cat "${STATE_FILE}"
    else
        echo "START"
    fi
}

# Prompt for user's real name and email
if [ "$(read_state)" == "START" ]; then
    read -p "Enter your Git real name: " GIT_NAME
    read -p "Enter your Git email: " GIT_EMAIL

    # Update state
    update_state "GIT_CONFIGURED"
fi

# Get the current system username
GIT_USERNAME=$(whoami)

REPO_NAME="orion"
REPO_HOST="github.com"  # Change this to your Git server's host
REPO_URL="git@${REPO_HOST}:${GIT_USERNAME}/${REPO_NAME}.git"
SSH_KEY_PATH="$HOME/.ssh/id_rsa"  # Change this path if you use a different key

# Step 0: Install Git
if [ "$(read_state)" == "GIT_CONFIGURED" ]; then
    sudo apt update
    sudo apt install -y git

    # Step 1: Configure Git
    git config --global user.name "${GIT_NAME}"
    git config --global user.email "${GIT_EMAIL}"
    echo "Configured Git username as ${GIT_USERNAME}"
    echo "Configured Git name as ${GIT_NAME}"
    echo "Configured Git email as ${GIT_EMAIL}"

    # Print repository URL
    echo "Repository URL: ${REPO_URL}"

    # Update state
    update_state "SSH_KEY_CHECK"
fi

# Step 2: Check if SSH key exists
if [ "$(read_state)" == "SSH_KEY_CHECK" ]; then
    if [ ! -f "${SSH_KEY_PATH}" ]; then
        echo "SSH key not found at ${SSH_KEY_PATH}, generating new SSH key..."
        ssh-keygen -t rsa -b 4096 -C "${GIT_USERNAME}@github.com" -f "${SSH_KEY_PATH}" -N ""
        echo "SSH key generated at ${SSH_KEY_PATH}"
        
        # Assuming the server uses a standard SSH setup, you might need to add the SSH key to your SSH agent
        eval "$(ssh-agent -s)"
        ssh-add "${SSH_KEY_PATH}"
        echo "SSH key added to SSH agent."

        echo "Please add the following public key to your Git server:"
        cat "${SSH_KEY_PATH}.pub"
        echo "Once added, re-run this script."
        update_state "SSH_KEY_PENDING"
        exit 1
    else
        echo "SSH key found at ${SSH_KEY_PATH}, continuing..."
        update_state "REPO_CLONE"
    fi
fi

# Step 3: Clone the repository
if [ "$(read_state)" == "REPO_CLONE" ]; then
    if [ ! -d "${REPO_NAME}" ]; then
        git clone "${REPO_URL}"
        echo "Repository '${REPO_NAME}' has been cloned."
    else
        echo "Directory '${REPO_NAME}' already exists. Pulling latest changes..."
        cd "${REPO_NAME}"
        git pull
    fi
    update_state "DONE"
fi

echo "Script completed successfully."
