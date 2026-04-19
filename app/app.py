import socket
import base64
import json
import csv
import time
import threading
import os
from flask import Flask, render_template
from crypto import xor_decrypt

TCP_HOST = "0.0.0.0"
TCP_PORT = 5001
WEB_PORT = 5000
SOCKET_TIMEOUT = 10  # seconds

# Get paths relative to project root
APP_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(APP_DIR)
DATA_DIR = os.path.join(PROJECT_ROOT, "data")
CONFIG_DIR = os.path.join(PROJECT_ROOT, "config")

# Ensure directories exist
os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(CONFIG_DIR, exist_ok=True)

CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")
CSV_FILE = os.path.join(DATA_DIR, "data.csv")
REGISTRY_FILE = os.path.join(DATA_DIR, "registry.json")

def load_interval():
    try:
        with open(CONFIG_FILE) as f:
            return int(json.load(f).get("interval", 10))
    except:
        return 10

def recv_line(conn):
    buf = b""
    while True:
        c = conn.recv(1)
        if not c:
            break
        buf += c
        if c == b"\n":
            break
    return buf

def ensure_files():
    if not os.path.exists(CSV_FILE):
        with open(CSV_FILE, "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["timestamp","node_id","ip","tracks","vbat","soc","boot"])

    if not os.path.exists(REGISTRY_FILE):
        with open(REGISTRY_FILE, "w") as f:
            json.dump({}, f)

def handle_client(conn, addr):
    """Handle ESP32 client connection with proper protocol"""
    ip = addr[0]
    conn.settimeout(SOCKET_TIMEOUT)
    
    try:
        # Step 1: Receive config request from ESP32
        raw = recv_line(conn)
        if raw:
            try:
                pkt = json.loads(raw.decode().strip())
                if pkt.get("type") == "cfg":
                    interval = load_interval()
                    conn.sendall((json.dumps({"interval": interval}) + "\n").encode())
                    print(f"[CFG] Sent interval={interval} to {ip}")
            except json.JSONDecodeError:
                pass

        # Step 2: Receive encrypted data from ESP32
        raw = recv_line(conn)
        if not raw:
            print(f"[WARN] No data received from {ip}")
            return

        try:
            # Decode base64, then XOR decrypt
            encrypted = base64.b64decode(raw.strip())
            plain = xor_decrypt(encrypted)
            pkt = json.loads(plain.decode())
            
            ts = int(time.time())

            # Send acknowledgment to ESP32
            conn.sendall(b'{"ack":1}\n')
            print(f"[ACK] Sent to {pkt.get('id', 'unknown')}")

            # Store in CSV
            with open(CSV_FILE, "a", newline="") as f:
                writer = csv.writer(f)
                writer.writerow([ts, pkt.get("id", "unknown"), ip, 
                                pkt.get("tracks", 0), pkt.get("vbat", 0), 
                                pkt.get("soc", 0), pkt.get("boot", 0)])

            # Update registry
            with open(REGISTRY_FILE, "r") as f:
                reg = json.load(f)

            reg[pkt.get("id", "unknown")] = {
                "ip": ip,
                "last_seen": ts,
                "tracks": pkt.get("tracks", 0),
                "vbat": pkt.get("vbat", 0),
                "soc": pkt.get("soc", 0),
                "boot": pkt.get("boot", 0),
                "wh": pkt.get("wh", 0),  # Include energy in Wh
            }

            with open(REGISTRY_FILE, "w") as f:
                json.dump(reg, f, indent=2)

            print(f"[DATA] {pkt.get('id')} | V={pkt.get('vbat')}V | SOC={pkt.get('soc')}% | tracks={pkt.get('tracks')} | boot={pkt.get('boot')}")

        except base64.b64decode.Error as e:
            print(f"[ERROR] Base64 decode failed from {ip}: {e}")
        except json.JSONDecodeError as e:
            print(f"[ERROR] JSON parse failed from {ip}: {e}")
        except Exception as e:
            print(f"[WARN] Bad packet from {ip}: {e}")

    except socket.timeout:
        print(f"[WARN] Connection timeout from {ip}")
    except Exception as e:
        print(f"[ERROR] Client handling {ip}: {e}")
    finally:
        conn.close()

def tcp_server():
    ensure_files()
    print("[TCP] Listening on port", TCP_PORT)

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((TCP_HOST, TCP_PORT))
    s.listen()

    while True:
        conn, addr = s.accept()
        print("[TCP] Connection from", addr[0])
        threading.Thread(target=handle_client,args=(conn, addr),daemon=True).start()

app = Flask(__name__)

@app.route("/")
def index():
    nodes = []
    if os.path.exists(REGISTRY_FILE):
        with open(REGISTRY_FILE) as f:
            reg = json.load(f)

        now = int(time.time())
        for node_id, data in reg.items():
            data["id"] = node_id
            data["age"] = now - data["last_seen"]
            nodes.append(data)

    return render_template("index.html", nodes=nodes)

if __name__ == "__main__":
    print("==============================")
    print(" ESP HIVE CONTROL SERVER")
    print("==============================")

    threading.Thread(target=tcp_server, daemon=True).start()

    print("[WEB] Dashboard on port", WEB_PORT)
    app.run(host="0.0.0.0", port=WEB_PORT)