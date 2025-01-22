# @author      Rayshader
# @version     0.1.0
# @description Runs a server as a daemon to trigger debugger instructions from 
#              an external program. Accepts only one client connection. Define 
#              IP_ADDRESS and PORT to your needs. Run 'stop_server()' from 
#              command-line to stop server running in background.

import threading
import socket
import time

IP_ADDRESS = '127.0.0.1'
PORT = 2077

stop_event = threading.Event()
buffer = ""

def log(msg):
    print(f"[RedSocket] {msg}")

def is_running():
    return not stop_event.is_set()

def stop_server():
    stop_event.set()

def run_server(host=IP_ADDRESS, port=PORT):
    server = None
    client = None
    try:
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.bind((host, port))
        server.listen(1)
        server.setblocking(False)
        log(f"Server listening on {host}:{port}")
        log(f"Waiting for a connection...")
        client = None
        client_address = None
        while is_running() and client == None:
            try:
                client, client_address = server.accept()
            except Exception as e:
                pass
            finally:
                time.sleep(0.100)
        
        if client == None:
            return
        
        log(f"Connection acquired from {client_address}")
        
        while is_running():
            command = read_command(client)
            if command is None:
                log(f"Client disconnected")
                break
            result = dispatch_command(client, command)
            if result == "abort":
                break
            time.sleep(0.016)
        
        client.close()
        log(f"Connection closed")
    
    except Exception as e:
        log(f"An error occurred: {e}")
    
    finally:
        if client is not None:
            client.close()
        server.close()
        log(f"Server closed")

def read_command(client):
    global buffer
    
    try:
        data = client.recv(1024)
        if len(data) == 0:
            return None
        message = data.decode("utf-8")
        buffer += message
    except Exception as e:
        pass
    eoc = buffer.find("\r\n")
    if eoc == -1:
        return ""
    command = buffer[:eoc]
    buffer = buffer[eoc + 2:]
    command = command.strip()
    if len(command) != 0:
        log(f"Command: {command}")
    return command

def send_command(client, command):
    command += "\r\n"
    client.sendall(command.encode("utf-8"))

## Forward declaration
commands = {}

def dispatch_command(client, command):
    tokens = command.split()
    if len(tokens) == 0:
        return
    cmd_id = tokens[0]
    if cmd_id not in commands:
        send_command(client, f"error\nCommand '{cmd_id}' unknown")
        log(f"Command '{cmd_id}' unknown")
        return
    tokens.pop(0)
    try:
        return commands[cmd_id](client, *tokens)
    except Exception as e:
        send_command(client, f"error\nFailed to execute command '{cmd_id}'")
        log(f"Failed to execute command '{cmd_id}': {e}")
        return

def on_exit(client):
    return "abort"

def on_watch(client, *args):
    usage = """
Usage:       watch <addr> <ref_type>

Description: add read breakpoint on <addr>.
             analyze mnemonics to deduce the type of reference (either strong or weak).

Example:     watch 0x7ff6d9fd0000 handle
             watch 0x7ff6d9fd0000 ptr
"""
    if len(args) != 2:
        send_command(client, "usage\n" + usage)
        return
    addr = int(args[0], 0)
    ref_type = args[1]
    if ref_type != "handle" and ref_type != "ptr":
        send_command(client, f"error\nArgument <ref_type> must be 'handle' or 'ptr' (current value is '{ref_type}').")
        print(f"Argument <ref_type> must be 'handle' or 'ptr' (current value is '{ref_type}').")
        return
    # TODO: add soft breakpoint when reading <addr>
    send_command(client, f"response Watching {ref_type} @ {addr}")
    print(f"Watching {ref_type} @ {addr}")

# Entry point

commands["exit"] = on_exit
commands["watch"] = on_watch

thread = threading.Thread(target=run_server, daemon=True)
thread.start()