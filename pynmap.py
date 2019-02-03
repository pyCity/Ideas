#!/usr/bin/env python3
import argparse
import sys
import nmap

"""
Author  - pyCity
Date    - 27th January 2019
Version - 1.0

Description    : Simple nmap scanner
"""


def parseArgs(args=None):
    parser = argparse.ArgumentParser(description="Usage: sudo python pyNmap.py -ip 127.0.0.1 -t 1")
    parser.add_argument("-ip", "--host", help="Target host ip", required=True, default="localhost")
    parser.add_argument("-p", "--port", help="Target port", default="1-1024")
    parser.add_argument("-t", "--type", help="Scan type", default="SYN ACK scan")

    results = parser.parse_args(args)
    host, port, type = results.host, results.port, results.type
    return host, port, type

def getScanType(type):
    if type == "1":
        type = "-v -sS"
    elif type == "2":
        type = "-v -sU"
    elif type == "3":
        type = "-v -sS -sV -sC -AO"
    elif type == "4":
        type = "-v -sT"
    return type



def saveOutput(filename, results):
    with open(filename, "w") as file:
        file.write(str(results))


def nmapScan(host, port, type):
    scanner = nmap.PortScanner()
    scanner.scan(host, port, type)
    print("Status: {}".format(scanner[host].state()))
    if type == "3":
        print("Open Ports: {}".format(scanner[host]["udp"].keys()))
    else:
        print("Open Ports: {}".format(scanner[host]["tcp"].keys()))



if __name__ == "__main__":
    print("Valid scan types:\n"
          "1. SYN Half Connect scan\n"
          "2. UDP scan\n"
          "3. Comprehensive scan\n"
          "4. TCP Full Connect scan\n")

    host, port, type = parseArgs(sys.argv[1:])
    type = getScanType(type)

    output = nmapScan(host, port, type)
    saveOutput("results.txt", output)

