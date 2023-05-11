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

bash multipass-install.sh

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
    echo "$hostname VM exists."
    # Check current state chosen of VM
    echo "Checking if $hostname VM is running."
    
    if ( multipass info $hostname | grep Running > /dev/null )
    then
        echo "$hostname VM is running."
    else
        echo "Starting $hostname VM..."
        multipass start $hostname
    fi
    
    ip=$(multipass info "$hostname" | grep IPv4 | awk '{ print $2 }')
else
    echo "Creating $hostname vm..."
    multipass launch --cpus $cpu --disk 10G --memory $ram --name "$hostname" --cloud-init cloud-config.yaml
    
    ip=$(multipass info "$hostname" | grep IPv4 | awk '{ print $2 }')
    
    echo "Copying $app install script to vm ~/..."
    scp -i ./ed25519 -o StrictHostKeyChecking=accept-new -q "./$app/$app-install.sh" $user@$ip:"/home/$user/$app/$app-install.sh"

    echo "Running the $app install script..."
    if [ "$app" = "jenkins" ]
    then
        ssh -i ./ed25519 $user@$ip "bash ./$app/$app-install.sh $user $password $fullyQualifiedDomainName"
    elif [ "$app" = "gitlab" ]
    then
        ssh -i ./ed25519 $user@$ip "bash ./$app/$app-install.sh $fullyQualifiedDomainName"
    else
        ssh -i ./ed25519 $user@$ip "bash ./$app/$app-install.sh"
    fi
fi

echo "Establishing SSH connection to $hostname..."
ssh -i ./ed25519 $user@$ip

exit