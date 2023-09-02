import socket
import threading
import sys

def main():
    port = 9382
    addr = "0.0.0.0"
    allow_address = None
    users_file_path = None
    verbose = False

    if len(sys.argv) > 2:
        i = 1
        while i < len(sys.argv):
            arg = sys.argv[i]

            if arg == "--help":
                show_help()
                sys.exit(1)
            elif arg == "-v":
                verbose = True
            elif arg == "--allow":
                if len(sys.argv) <= i + 1:
                    print("You must specify allowed address IP after --allow")
                    sys.exit(1)
                allow_address = sys.argv[i + 1].split(",")
                i += 1
            elif arg == "--file":
                if len(sys.argv) <= i + 1:
                    print("You must specify users file path after --file")
                    sys.exit(1)
                users_file_path = sys.argv[i + 1]
                i += 1
            else:
                host = arg
                try:
                    if ":" in host:
                        splits = host.split(":")
                        if len(splits) == 2:
                            addr = splits[0].strip()
                            port = int(splits[1])
                        else:
                            print("Invalid input format: host:port")
                            sys.exit(1)
                    else:
                        addr = "0.0.0.0"  # Default address if only port is provided
                        port = int(host)
                except ValueError:
                    print("Bad input")
                    show_help()
                    sys.exit(1)
            i += 1

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
            server_socket.bind((addr, port))
            server_socket.listen(5)
            print(f"Python acc_expire_date_reporter starts listening on {addr}:{port}")
            while True:
                client_socket, client_address = server_socket.accept()
                if verbose:
                    print(f"A connection from {client_address[0]}:{client_address[1]} received")
                if allow_address:
                    if client_address[0] not in allow_address:
                        if verbose:
                            print(f"Access denied from {client_address[0]}")
                        client_socket.close()
                        continue
                client_socket.settimeout(10)
                threading.Thread(target=handle_connection, args=(client_socket, users_file_path)).start()
    except Exception as e:
        print(e)

def show_help():
    print("acc_expire_reporter [0.0.0.0:]9382 or just acc_expire_reporter default listening port is 9382")
    print("--allow list of ip address separated by comma: allow address to establish connection")
    print("--file usersFilePath: set users file path")
    print("--help : show this help")

def handle_connection(client_socket, users_file_path):
    try:
        with client_socket:
            username = client_socket.recv(1024).decode('utf-8').strip()
            expire_date = AccExpireFetcher.get_expire_date(username, users_file_path)
            if expire_date is None:
                expire_date = ""
            client_socket.send(expire_date.encode('utf-8'))
    except Exception as e:
        print(e)

class AccExpireFetcher:
    @staticmethod
    def get_expire_date(username, file_path):
        if file_path is None or file_path == "":
            file_path = "/etc/acc-expire/users"
        try:
            with open(file_path, "r") as fin:
                for line in fin:
                    splits = line.split()
                    name = splits[0].strip()
                    if name == username:
                        return splits[1].strip()
        except Exception as e:
            print(e)
        return None

if __name__ == "__main__":
    main()

