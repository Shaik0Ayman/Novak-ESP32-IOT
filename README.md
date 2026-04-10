# ESP Hive Server 🐝

A production-ready IoT control server for managing ESP32-based hive monitoring nodes on Raspberry Pi.

## Quick Start (5 Minutes)

### 1. Clone & Setup

```bash
cd ~ && git clone https://github.com/yourusername/esp-hive-server.git
cd esp-hive-server
./scripts/setup.sh
```

### 2. Start Service

```bash
sudo systemctl start esp-hive
```

**✓ Auto-Start Enabled!** The setup script automatically enables auto-start. Your service will run every time the Raspberry Pi boots!

Verify auto-start configuration:
```bash
./scripts/verify-autostart.sh
```

### 3. Access Dashboard

Open browser: `http://raspi.local:5000`

That's it! 🚀

---

## Features

- **TCP Server** - Receives encrypted data from ESP32 nodes (port 5001)
- **Web Dashboard** - Real-time node monitoring (port 5000)
- **Auto-Start** - Runs automatically on Raspberry Pi boot
- **Production-Ready** - Proper directory structure, error handling, logging
- **Easy Config** - Simple `.env` file for customization

---

## Project Structure

```
esp-hive-server/
├── app/                      # Main application code
│   ├── app.py               # Flask server + TCP listener
│   ├── crypto.py            # XOR encryption utility
│   ├── __init__.py
│   └── templates/index.html # Web dashboard
├── config/                   # Configuration files
│   └── config.json          # Server settings
├── data/                     # Runtime data (auto-created)
│   ├── data.csv             # Telemetry archive
│   └── registry.json        # Active node status
├── logs/                     # Application logs
├── scripts/
│   ├── setup.sh             # Automated setup script
│   └── esp-hive.service     # Systemd service file
├── requirements.txt         # Python dependencies
├── .env.example             # Configuration template
├── run.sh                   # Manual launch script
└── README.md                # This file
```

---

## Installation

### Prerequisites

- Raspberry Pi 3B+ or newer (or any Linux system)
- Git
- SSH access (or direct terminal)

### Automated Setup

```bash
./scripts/setup.sh
```

This installs everything:

- ✓ System updates
- ✓ Python 3 & pip
- ✓ Python requirements
- ✓ Creates directories
- ✓ Configures auto-start service

### Manual Setup (if needed)

```bash
# Install dependencies
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y python3 python3-pip

# Install Python packages
pip3 install -r requirements.txt

# Create directories
mkdir -p data logs

# Copy config template
cp .env.example .env

# Install systemd service
sudo cp scripts/esp-hive.service /etc/systemd/system/
sudo systemctl daemon-reload
```

---

## Configuration

Edit `.env` to customize:

```bash
nano .env
```

Available settings:

```env
TCP_HOST=0.0.0.0          # TCP listening address
TCP_PORT=5001             # TCP port for ESP32 nodes
WEB_HOST=0.0.0.0          # Web server address
WEB_PORT=5000             # Web dashboard port
INTERVAL=10               # Node query interval (seconds)
LOG_LEVEL=INFO            # Log verbosity
```

After changing `.env`:

```bash
sudo systemctl restart esp-hive
```

---

## Service Management

### Start / Stop

```bash
sudo systemctl start esp-hive      # Start service
sudo systemctl stop esp-hive       # Stop service
sudo systemctl restart esp-hive    # Restart service
sudo systemctl status esp-hive     # Check status
```

### Auto-Start

✓ **Auto-start is enabled by setup.sh!**

The service automatically starts on every Raspberry Pi boot. No manual action needed after initial setup.

```bash
# Verify auto-start is enabled
sudo systemctl is-enabled esp-hive

# If needed, manually enable/disable
sudo systemctl enable esp-hive      # Enable on boot
sudo systemctl disable esp-hive     # Disable on boot
```

### View Logs

```bash
# Real-time logs
sudo journalctl -u esp-hive -f

# Last 50 lines
sudo journalctl -u esp-hive -n 50

# Since boot
sudo journalctl -u esp-hive -b
```

---

## Development / Manual Run

For testing without systemd:

```bash
python3 app/app.py
```

Then access at `http://localhost:5000`

---

## ESP32 Node Communication

Nodes connect via TCP on port 5001:

### 1. Node sends config request (JSON):

```json
{ "type": "cfg" }
```

### 2. Server responds:

```json
{ "interval": 10 }
```

### 3. Node sends data (base64-encoded XOR-encrypted JSON):

```
[base64-encoded encrypted payload]
```

### 4. Server acknowledges:

```json
{ "ack": 1 }
```

### Data Format (before encryption):

```json
{
  "id": "NODE_001",
  "tracks": 1,
  "vbat": 4.2,
  "soc": 95,
  "boot": 2
}
```

---

## Data Files

### registry.json

Current status of all nodes:

```json
{
  "NODE_001": {
    "ip": "192.168.1.100",
    "last_seen": 1681234567,
    "tracks": 1,
    "vbat": 4.2,
    "soc": 95,
    "boot": 2
  }
}
```

### data.csv

Complete telemetry archive:

```
timestamp,node_id,ip,tracks,vbat,soc,boot
1681234567,NODE_001,192.168.1.100,1,4.2,95,2
```

---

## Troubleshooting

### Service won't start

```bash
# Check status
sudo systemctl status esp-hive

# View logs
sudo journalctl -u esp-hive -n 20
```

### Port already in use

```bash
# Find what's using port 5001
sudo lsof -i :5001

# Kill if needed
sudo kill -9 <PID>

# Or change port in .env
```

### Permission errors

```bash
sudo chown -R pi:pi ~/esp-hive-server
chmod -R 755 ~/esp-hive-server
```

### Python modules not found

```bash
pip3 install -r requirements.txt
```

### Run manually for debugging

```bash
sudo systemctl stop esp-hive
python3 app/app.py
# Check terminal output for errors
```

---

## Updating

Pull latest changes and restart:

```bash
cd ~/esp-hive-server
git pull origin main
sudo systemctl restart esp-hive
```

---

## Maintenance

### Backup Data

```bash
tar -czf ~/esp-hive-backup-$(date +%Y%m%d).tar.gz data/ config/
```

### Monitor Resources

```bash
top
df -h
netstat -an | grep 5001
```

### Clean Old Logs

```bash
sudo journalctl --vacuum=time=1w
```

### Check Disk Usage

```bash
du -sh data/ config/ logs/
```

---

## Firewall (if enabled)

```bash
# Allow TCP connections from ESP32 nodes
sudo ufw allow 5001/tcp

# Allow web dashboard access (if needed)
sudo ufw allow 5000/tcp

# Reload firewall
sudo ufw reload
```

---

## FAQ

**Q: How do I change the TCP port?**  
A: Edit `.env`, set `TCP_PORT=<new_port>`, then `sudo systemctl restart esp-hive`

**Q: Where are the logs?**  
A: View with `sudo journalctl -u esp-hive -f`

**Q: Can I run multiple instances?**  
A: Yes, create additional service files with different ports and data directories

**Q: What if Raspberry Pi loses power?**  
A: Service auto-restarts on boot

**Q: How do I backup data?**  
A: `tar -czf backup.tar.gz data/ config/`

**Q: How do I restore from backup?**  
A: `tar -xzf backup.tar.gz` (stop service first)

---

## API Routes

### `/` (GET)

Returns HTML dashboard with all connected nodes and their latest status.

---

## Ports

- **5000** - Flask web dashboard
- **5001** - TCP server for ESP32 nodes

Make sure these aren't blocked by firewall and aren't already in use.

---

## Performance Tips

1. **Reduce query interval** - Lower `INTERVAL` in `.env` for faster updates (uses more bandwidth)
2. **Monitor disk space** - Archive old CSV files if `data.csv` grows too large
3. **Check memory usage** - Restart service if memory usage grows: `sudo systemctl restart esp-hive`

---

## Security

- Encryption: XOR key-based (see `app/crypto.py`)
- Change key if needed: Edit `XOR_KEY` in `app/crypto.py` and restart
- Firewall: Restrict TCP port 5001 to trusted IP ranges
- Service runs as `pi` user on Raspberry Pi

---

## Development

### Virtual Environment Setup

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 app/app.py
```

### Making Changes

1. Edit files in `app/`
2. Restart service: `sudo systemctl restart esp-hive`
3. Check logs: `sudo journalctl -u esp-hive -f`

---

## License

MIT License - See LICENSE file

---

## Support

- Check logs: `sudo journalctl -u esp-hive -f`
- Manual test: `python3 app/app.py`
- File an issue on GitHub

---

**Built for the swarm 🐝**
