import sys
import pysftp


if len(sys.argv) != 4:
    print("Usage: python pySftp.py [get/put] [ip] /path/to/info.txt")
    sys.exit()


def sftp_get(host, file):
    with pysftp.Connection(host, username="dylan", private_key="/home/dylan/.ssh/id_rsa") as sftp:
        print("Connection established to {}\nDownloading {}...".format(host, file))
        sftp.get(file)


def sftp_put(host, file):
    with pysftp.Connection(host, username="dylan", private_key="/home/dylan/.ssh/id_rsa") as sftp:
        print("Connection established to {}\nUploading {}...".format(host, file))
        sftp.put(file)


if __name__ == "__main__":

    option = sys.argv[1]
    host = sys.argv[2]
    file = sys.argv[3]

    if option == "get":
        sftp_get(host, file)
    elif option == "put":
        sftp_put(host, file)
    else:
        print("Invalid input")
        sys.exit()
