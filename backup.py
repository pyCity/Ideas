#!/usr/bin/env python3
import subprocess
import shlex
import sys

"""
Author       - pyCity
Date         - 1/25/2019
Version      - 1.0
Usage:       - python backup.py [home/full]
Description: - Script to backup home directory or full system of all servers.
             - SSH keys are necessary to avoid passwords.
             - Run with cron -  
             - 0 0 * * * /home/dylan/Backups/backup.py home
"""


servers = {
    "AdminConsole" : "10.0.0.1",
    "DNSServer"    : "10.0.0.2",
    "DNSServer"    : "10.0.0.3",
    "DNSServer"    : "10.0.0.4",
    "node1"        : "10.0.0.5",
    "node2"        : "10.0.0.6",
    "node3"        : "10.0.0.7"
}


def backup():
    """Backup servers, return output"""

    output = ""
    if option == "home":
        for hostname, address in servers.items():
            try:
                cmd = "rsync -n -az --delete --info=progress2 root@" + address + ":/home/ /home/dylan/Backups/" + hostname
                print(shlex.split(cmd))
                return_code = subprocess.run(shlex.split(cmd), check=True)
                output += str(return_code) + "\n"
            except Exception:
                print(Exception)
                continue

    elif option == "full":
        for hostname, address in servers.items():
            try:
                cmd = 'rsync -aAX --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} root@' + address + ':/ /home/dylan/Backups/FullSysBackup/' + hostname
                print(shlex.split(cmd))
                return_code = subprocess.run(shlex.split(cmd), check=True)
                output += str(return_code) + "\n"
            except Exception:
                print(Exception)
                continue
    else:
        print("Invalid input. Options are: [home] or [full]")
        sys.exit()
    return output


def save_output(filename, output):
    """Log results stored in output variable to text file"""

    with open(filename, "a") as f:
        f.write(str(output))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python old_backup.py home [home / full]")
        sys.exit()

    option = sys.argv[1]

    out = backup()
    save_output("results.txt", out)

