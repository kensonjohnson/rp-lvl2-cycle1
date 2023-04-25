#!/bin/bash

sudo apt update -yq

echo "Checking for Nginx..."
if ! ( command -v nginx 2> /dev/null )
then
    echo "Installing Nginx..."
    sudo apt install nginx -yq
    echo "Nginx installed."
else
    echo "Nginx already installed."
fi

echo "Starting Nginx..."
sudo systemctl start nginx
exit 0
