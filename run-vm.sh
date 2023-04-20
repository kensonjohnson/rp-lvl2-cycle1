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

while getopts "?a:d:h:p:u:" option
do
    # : "$option" "$OPTARG"
    case $option in
        a)
            app=$OPTARG
            # echo $app
        ;;
        d)
            fqdn=$OPTARG
            # echo $fqdn
        ;;
        h)
            hostn=$OPTARG
            # echo $fqdn
        ;;
        p)
            passwd=$OPTARG
            # echo $passwd
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

if [ "$passwd" = "" ]
then
    passwd="adminServerPassword"
fi

if ! [ "$user" ]
then
    user=$USER
fi

if ! [ "$hostn" ]
then
    hostn=$app
fi

if [ "$fqdn" = "" ]
then
    fqdn="relativepath.tech"
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

    sudo snap start multipass
    sleep 10

    multipass start --all > /dev/null
    sleep 10
fi

if [ -f "./ed25519" ]
then
    echo "SSH keys exist."
else
    ssh-keygen -f "./ed25519" -b 4096 -t ed25519 -N ''
fi

if ( grep "$(cat ./ed25519.pub)" ./cloud-config.yaml 2> /dev/null )
then
    echo "cloud-config.yaml already exists and is correct"
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

echo "launching $app instance with multipass"
if ( multipass info "$hostn" > /dev/null )
then
    echo "$app VM exists."
else
    echo "Creating $app vm..."
    multipass launch -c 2 -d 10G -m 4G --name "$hostn" --cloud-init cloud-config.yaml
fi

ip=$(multipass info "$hostn" | grep IPv4 | awk '{ print $2 }')

echo "Copying $app install script to vm ~/..."
if [ "$app" != 'nginx' ]
then
    scp -i ./ed25519 -o StrictHostKeyChecking=accept-new -q "./$app/$app-install.sh" $user@$ip:"/home/$user/$app-install.sh"
else
    scp -i ./ed25519 -o StrictHostKeyChecking=accept-new -q "./$app-install.sh" $user@$ip:"/home/$user/$app-install.sh"
fi


if [ "$app" = "jenkins" ]
then
    ssh -i ./ed25519 $user@$ip "bash $app-install.sh $user $passwd $fqdn"
elif [ "$app" = "gitlab" ]
then
    ssh -i ./ed25519 $user@$ip "bash $app-install.sh $fqdn"
else
    ssh -i ./ed25519 $user@$ip "bash $app-install.sh"
fi


ssh -i ./ed25519 $user@$ip