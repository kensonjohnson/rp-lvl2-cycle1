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

sudo snap start multipass.multipassd > /dev/null
multipass start --all > /dev/null

while ! (ss -l | grep multipass_socket)
do
    sleep 2
done

exit