#!/bin/env bash

# A script to install an GitLab webserver

if ( which jenkins )
then 
    echo "Jenkins"
else 
    echo -e "Installing Jenkins"

    # Download Jenkins signing key and add to keyring
    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

    # Add the package repository address to apt
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

    # Get dependencies
    sudo apt update -y
    sudo apt install -y openjdk-11-jre -y

    # Install jenkins
    sudo apt install jenkins -y

fi
