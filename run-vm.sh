#!/bin/bash

usage="Usage:       $ bash run-vm.sh [options]
  -a        Has the options of nginx, gitlab or jenkins. 
                        Default: nginx

  -d        Is the domain name that will be used. 
                        Default: relativepath.tech

  -h        Is the hostname that will be used.
                        Default: [appname]

  -p        Password for the server service being created.
                        Default: adminServerPassword

  -u        Is the username that will be configured on the VM. 
                        Default: \$USER

  -?        This Usage message."

declare -l app

while getopts "?a:d:h:p:u:" option
do
    # : "$option" "$OPTARG"
    case $option in
        a)
            app=$OPTARG
            # echo $app
        ;;
        d)
            fullyQualifiedDomainName=$OPTARG
            # echo $fullyQualifiedDomainName
        ;;
        h)
            hostname=$OPTARG
            # echo $fullyQualifiedDomainName
        ;;
        p)
            password=$OPTARG
            # echo $password
        ;;
        u)
            user=$OPTARG
            # echo $user
        ;;
        ?) 
            echo $usage
            echo ""
            exit
        ;;
    esac
done


if [ "$app" = "" ]
then
    app="nginx"
fi

if [ "$password" = "" ]
then
    password="adminServerPassword"
fi

if ! [ "$user" ]
then
    user=$USER
fi

if ! [ "$hostname" ]
then
    hostname=$app
fi

if [ "$fullyQualifiedDomainName" = "" ]
then
    fullyQualifiedDomainName="relativepath.tech"
fi

if [ $(uname) = "Linux" ]
then
    
    if ( snap --version 2>/dev/null )
    then
        echo "Snap is already installed."
    else
        echo "Installing snapd..."
        sudo apt install -yq snapd
    fi

    if ( multipass version 2>/dev/null )
    then
        echo "Multipass is already installed."
    else
        echo "Installing multipass..."
        sudo snap install multipass >/dev/null
    fi

    if ( ps -aef | grep multipass.multipassd > /dev/null )
    then
        sudo snap stop multipass > /dev/null
    fi

    if ( ps -aef | grep multipass.gui > /dev/null )
    then
        sudo killall multipass.gui >/dev/null
    fi

    if [ -f "/var/snap/multipass/common/data/multipassd/authenticated-certs/multipass_client_certs.pem" ] > /dev/null
    then
        # Removes authentication error by removing client certs and replacing them with user generated cert.
        sudo rm /var/snap/multipass/common/data/multipassd/authenticated-certs/multipass_client_certs.pem
    fi

    if [ -f "~/snap/multipass/current/data/multipass-client-certificate/multipass_cert.pem" ] > /dev/null
    then
        sudo cp ~/snap/multipass/current/data/multipass-client-certificate/multipass_cert.pem /var/snap/multipass/common/data/multipassd/authenticated-certs/multipass_client_certs.pem
    fi

    sudo snap start multipass > /dev/null
    sleep 10

    multipass start --all > /dev/null
    sleep 10
fi


# Check if SSH keys already exist
if [ -f "./ed25519" ]
then
    echo "SSH keys exist."
else
    ssh-keygen -f "./ed25519" -b 4096 -t ed25519 -N ''
fi

if ( grep "$(cat ./ed25519.pub)" ./cloud-config.yaml 2> /dev/null )
then
    echo "cloud-config.yaml configured correctly."
else
    echo "create cloud-config.yaml and add the ssh public key..."
    cat <<- EOF > cloud-config.yaml
users:
  - default
  - name: $user
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat ./ed25519.pub)
EOF
fi

# GitLab minimum specs call for 4G memory and 4 cpu threads
if [ "$app" == "gitlab" ]
then
    cpu=4
    ram=4G
else
    cpu=2
    ram=2G
fi

# Check if chosen VM already exists
echo "Checking for a $app instance within multipass."
if ( multipass info "$hostname" > /dev/null )
then
    echo "$app VM exists."
else
    echo "Creating $app vm..."
    multipass launch --cpus $cpu --disk 10G --memory $ram --name "$hostname" --cloud-init cloud-config.yaml
fi

# Check current state chosen of VM
echo "Checking if $app VM is running."
if ( multipass info $app | grep Running > /dev/null )
then
    echo "$app VM is running."
else
    echo "Starting $app VM..."
    multipass start $app
fi

ip=$(multipass info "$hostname" | grep IPv4 | awk '{ print $2 }')

echo "Copying $app install script to vm ~/..."
scp -i ./ed25519 -o StrictHostKeyChecking=accept-new -q "./$app/$app-install.sh" $user@$ip:"/home/$user/$app-install.sh"

echo "Running the $app install script..."
if [ "$app" = "jenkins" ]
then
    ssh -i ./ed25519 $user@$ip "bash $app-install.sh $user $password $fullyQualifiedDomainName"
elif [ "$app" = "gitlab" ]
then
    ssh -i ./ed25519 $user@$ip "bash $app-install.sh $fullyQualifiedDomainName"
else
    ssh -i ./ed25519 $user@$ip "bash $app-install.sh"
fi

echo "Establishing SSH connection to $hostname..."
ssh -i ./ed25519 $user@$ip