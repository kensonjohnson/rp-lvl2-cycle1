#!/bin/bash

for vm in "gitlab", "nginx", "jenkins"
do
    if ( ip=ssh-keygen -H -F $(multipass info "$vm" | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | awk '{print $2}') 2> /dev/null ) 
    then
        echo -e "\n==== Deleting fingerprint from known host ====\n"
        ssh-keygen -f ~/.ssh/known_hosts -R "$ip"
    else 
        echo -e "\n==== Fingerprint not present in known host ====\n"
    fi 

    if ( multipass info "$vm" 2> /dev/null )
    then
        echo "Deleting the vm $vm..."
        multipass delete --purge "$vm"
    else
        echo "the vm $vm has already been deleted!"
    fi
done

if [ -f ./ed25519 ] > /dev/null
then
    echo "Deleting the ed25519 file..."
    rm ed25519 ed25519.pub
else
    echo "the ed25519 file has already been deleted!"
fi

if [ -f ./cloud-config.yaml ] > /dev/null
then
    echo "Deleting the cloud-config file..."
    rm -f ./cloud-config.yaml
else
    echo "the cloud-config file has already been deleted!"
fi

if [ -f ./jenkins-cli.jar ] > /dev/null
then
		echo "Deleting the jenkins-cli.jar..."
		rm -f jenkins-cli.jar
else
		echo "jenkins-cli.jar doesn't exist."
fi

# if ( multipass version 2> /dev/null )
# then 
#     echo "Removing multipass..."
#     sudo snap stop multipass
#     sleep 5
#     sudo snap remove multipass > /dev/null
# else
#     echo "Multipass does not exist."
# fi

# if [ $(snap list | wc -l) >= 5 ] > /dev/null
# then
#     echo "Multiple snaps are in use, snapd won't be removed"
# else
#     echo "Removing snapd..."
#     sudo apt remove -yq --purge snapd > /dev/null
# fi
