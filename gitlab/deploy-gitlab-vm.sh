# Check if Mint OS User and if they allow snap to be installed

if [[ -f "/etc/apt/preferences.d/nosnap.pref" ]];
then
    echo "Running on Mint OS."
    echo "By default, Mint does not allow Snap package manager to be installed."
    echo "Would you like to enable this feature? y/n"
    # Promt user for input
    read allowInstallOfSnap
    echo "$allowInstallOfSnap"
    if [[ "$allowInstallOfSnap" == "y" ]]
    then 
        sudo rm /etc/apt/preferences.d/nosnap.pref
    else
        echo "Unable to install multipass, Snap not installed."
        echo "Either use an Ubuntu machine or enable Snap installation."
        exit 1
    fi
fi

# Check for SSH keys
echo "Checking for SSH keys."
if [ -f id_ed25519 ]
then 
  echo -e "SSH keys present."
else
# Create if not present
  echo -e "SSH keys not found. Generating..."
  ssh-keygen -t ed25519 -q -f id_ed25519 -C "gitlab@relative.path" -N ""
fi


# Check for Cloud-Init
echo "Checking for Cloud-Init file."
if [ -f cloud-init.yaml ]
then 
  echo -e "Cloud-Init file found."
else
# Create if not present
  echo -e "Cloud-Init file not found. Generating..."
  cat <<- EOF > cloud-init.yaml
users:
  - default
  - name: gitlab
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat id_ed25519.pub)
EOF
fi

# Check for snap package manager
echo "Checking if Snap package manager installed."
if ( snap > /dev/null)
then 
    echo "Snap already installed."
else
# Install if not present 
    echo "Installing Snap"
    sudo apt update
    sudo apt install snapd
fi

# Check for multipass
echo "Checking if Multipass installed."
if ( multipass version > /dev/null)
then
    echo "Multipass already installed."
else 
# Install if not present
    echo "Installing Multipass"
    sudo snap install multipass
fi

# Check if Ubuntu VM Exists
echo "Checking if 'gitlab' VM exists."
if ( multipass info gitlab > /dev/null )
then
    echo "A virtual machine named 'gitlab' already exists."
else
    echo "Creating virtual machine named 'gitlab'"
    multipass launch --name gitlab --cloud-init cloud-init.yaml --disk 20G --cpus 4 --memory 4G

    # Use scp to transfer install-gitlab script to VM
    scp -i ./id_ed25519 -o StrictHostKeyChecking=no install-gitlab.sh gitlab@$(multipass info gitlab | grep IPv4 | awk '{print $2}'):/home/gitlab

    # Run install-gitlab file on VM
    ssh -i id_ed25519 -o StrictHostKeyChecking=no gitlab@$(multipass info gitlab | grep IPv4 | awk '{print $2}') 'bash install-gitlab.sh'
fi

# Check current state of VM
echo "Checking if 'gitlab' VM is running."
if ( multipass info gitlab | grep Running > /dev/null )
then
    echo "VM is running."
else
    echo "Starting VM..."
    multipass start gitlab
fi

# Handle ssh into VM
ssh -i id_ed25519 -o StrictHostKeyChecking=no gitlab@$(multipass info gitlab | grep IPv4 | awk '{print $2}')
