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
fi

echo "Starting multipass..."
sudo snap start multipass > /dev/null
sleep 20

exit