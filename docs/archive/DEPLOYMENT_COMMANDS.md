# FlowerOS v1.3.0 - Command Reference for Deployment

**Copy-paste ready commands with decision points**

---

## Quick Reference: Deployment Commands

### Decision Tree Summary

```
1. Installation Type? [Quick=Q, User=U, System=S] → _____
2. Enable Network? [Y/N] → _____
3. Enable GPU? [Y/N] → _____
4. Multi-machine? [Y/N] → _____
```

---

## SCENARIO 1: Quick Test (Q,N,N,N)

**5 minutes • Removable • Test only**

```bash
# Prerequisites
bash --version    # Must be 4.0+
gcc --version     # Must exist (or install: sudo apt-get install build-essential)

# Clone
cd ~
git clone https://github.com/your-org/FlowerOS.git
cd FlowerOS

# Build
bash build.sh

# Install (user level)
bash install.sh

# Activate
source ~/.bashrc

# Test
floweros-info
flower_banner "Test"
flower_fortune

# DECISION: Keep it? [K=keep, R=remove]
# Input: _____

# If R (remove):
bash uninstall.sh
sed -i '/FlowerOS/d' ~/.bashrc
source ~/.bashrc
```

---

## SCENARIO 2: User Installation (U,N,N,N)

**10 minutes • User-level • Permanent (for your account)**

```bash
# Prerequisites check
bash --version
gcc --version
whoami    # Verify you're the right user

# Clone
cd ~
git clone https://github.com/your-org/FlowerOS.git
cd FlowerOS

# Build
bash build.sh

# Install
bash install.sh

# Activate
source ~/.bashrc

# Verify
floweros-info
floweros-status
ls -la ~/.floweros/

# DECISION: Configure startup? [Q=quiet, W=welcome, F=full]
# Input: _____

# If Q:
echo "export FLOWEROS_STARTUP_MODE='quiet'" >> ~/.flowerrc

# If W:
echo "export FLOWEROS_STARTUP_MODE='welcome'" >> ~/.flowerrc

# If F:
echo "export FLOWEROS_STARTUP_MODE='full'" >> ~/.flowerrc

# DECISION: Select theme? [1-5 or N]
# Input: _____

# If 1:
flower_set_theme botanical

# If 2:
flower_set_theme ocean

# If 3:
flower_set_theme sunset

# If 4:
flower_set_theme matrix

# If N:
# (skip theme)
```

---

## SCENARIO 3: System-Wide Installation (S,N,N,N)

**20 minutes • Root-level • Permanent (ALL users)**

```bash
# CRITICAL WARNING
echo "⚠️  This will modify system files and require sudo"
echo "Type EXACTLY: I UNDERSTAND THE RISKS"
read -p "Input: " CONFIRM

if [ "$CONFIRM" != "I UNDERSTAND THE RISKS" ]; then
    echo "Aborted."
    exit 1
fi

# Prerequisites
sudo -v    # Verify sudo access
# Password: _____

bash --version
gcc --version
lsb_release -a    # Verify compatible OS

# CRITICAL: Backup system files
sudo cp /etc/bash.bashrc "/etc/bash.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
echo "✓ Backups created"

# Clone
cd /tmp
git clone https://github.com/your-org/FlowerOS.git
cd FlowerOS

# Build
bash build.sh

# Install permanently (will prompt for confirmations)
sudo bash install-permanent.sh

# You will see prompts like:
# ⚠️  About to modify /etc/bash.bashrc. Continue? [y/N]
# Input for each: y

# Verify installation
ls -la /opt/floweros/
ls -la /etc/floweros/
grep "FlowerOS" /etc/bash.bashrc
cat /etc/profile.d/floweros.sh

# Test as different user
sudo su - testuser -c "floweros-info"

# Check immutable flags
lsattr /etc/floweros/.flowerrc
# Expected: ----i--------

# DECISION: Activate now? [T=test terminal, A=activate, L=logout]
# Input: _____

# If T:
gnome-terminal &

# If A:
source /etc/floweros/.flowerrc

# If L:
echo "Please logout and login again"
logout
```

---

## SCENARIO 4: With Network Features (U,Y,N,N)

**25 minutes • User + Network**

```bash
# Do SCENARIO 2 first, then:

# Build network components
cd ~/FlowerOS/network/
make all

# This builds:
#   - libflowernetwork.so
#   - libflowernetwork.a
#   - terminal_node
#   - node_monitor
#   - node_discovery

# Install
make install

# Verify
ls -la ../bin/node_monitor
ls -la ../bin/node_discovery
ls -la ../bin/terminal_node

# Load terminal network functions
source ~/FlowerOS/lib/terminal_network.sh

# DECISION: Network mode? [S=single, L=local, C=cluster]
# Input: _____

# DECISION: Node type? [P=plant, T=tree, J=join]
# Input: _____

# If P (Plant - worker node):
flower_plant

# If T (Tree - master node):
# DECISION: Cluster name?
# Input: _____
CLUSTER_NAME="your_cluster_name"  # Replace with actual input
flower_grow_tree "$CLUSTER_NAME"

# If J (Join - connect to master):
# DECISION: Master IP?
# Input: _____
MASTER_IP="192.168.1.100"  # Replace with actual input
flower_join_garden "$MASTER_IP"

# DECISION: Start node monitor? [Y/N]
# Input: _____

# If Y:
# DECISION: Port?
# Input: _____ (default: 7777)
PORT=7777  # Replace with actual input
../bin/node_monitor $PORT &

# DECISION: Configure node discovery? [Y/N]
# Input: _____

# If Y:
# Edit hard-coded relationships
vim network/node_discovery.cpp

# Find line ~70, modify:
# void load_hardcoded_relations(NetworkGate& gate) {
#     // DECISION: Master nodes?
#     gate.add_relation("YOUR_IP", 7777, "master_01", true);
#     gate.add_relation("YOUR_IP", 7777, "master_02", true);
#     
#     // DECISION: Worker nodes?
#     gate.add_relation("YOUR_IP", 7777, "worker_01", false);
#     gate.add_relation("YOUR_IP", 7777, "worker_02", false);
#     
#     // DECISION: GPU nodes?
#     gate.add_relation("YOUR_IP", 7777, "gpu_01", false);
# }

# Rebuild
cd network/
make clean
make all
make install

# Run discovery
../bin/node_discovery
# Interactive menu:
# 1) Load hard-coded relationships
# 2) Scan local network
# 3) Show all relations
# 4) Show gateways only
# 5) Auto-link to all nodes
# 6) Auto-link to gateways only
# 7) Clear all relations
# 8) Exit
#
# Your selections: _____
```

---

## SCENARIO 5: With GPU Features (U,N,Y,N)

**20 minutes • User + GPU**

```bash
# Do SCENARIO 2 first, then:

# Check GPU
nvidia-smi
# DECISION: GPU detected? [Y/N]
# Input: _____

# If N:
echo "No GPU detected. Skipping GPU features."
exit 0

# If Y:
# Check CUDA
nvcc --version
# DECISION: CUDA installed? [Y/N]
# Input: _____

# If N (CUDA not installed):
echo "Install CUDA from: https://developer.nvidia.com/cuda-downloads"
echo "Then return to this script"
exit 0

# If Y:
# DECISION: GPU architecture?
# Run: nvidia-smi --query-gpu=compute_cap --format=csv,noheader
# Examples: 7.5 = sm_75, 8.6 = sm_86
# Input: sm_____ (e.g., sm_75)
GPU_ARCH="sm_75"  # Replace with your architecture

# Create GPU Makefile
cd ~/FlowerOS/gpu/
cat > Makefile << 'EOF'
NVCC = nvcc
CUDA_FLAGS = -arch=${GPU_ARCH}

all:
	$(NVCC) $(CUDA_FLAGS) -o gpu_batch gpu_batch.cu
	
install:
	cp gpu_batch ../bin/

clean:
	rm -f gpu_batch
EOF

# DECISION: Batch size? [S=32, M=128, L=512, C=custom]
# Input: _____

# If S:
BATCH_SIZE=32

# If M:
BATCH_SIZE=128

# If L:
BATCH_SIZE=512

# If C:
# DECISION: Custom batch size?
# Input: _____ (number)
BATCH_SIZE=256  # Replace with actual input

# Configure batch size
echo "export FLOWER_GPU_BATCH_SIZE=$BATCH_SIZE" >> ~/.flowerrc

# Build
make all
make install

# Test
../bin/gpu_batch --test

# Verify
../bin/gpu_batch --info
```

---

## SCENARIO 6: Full Installation (S,Y,Y,N)

**55 minutes • System + Network + GPU**

```bash
# Combine SCENARIO 3 + SCENARIO 4 + SCENARIO 5
# This is for production deployments

# WARNING CHECK
echo "⚠️  Full system installation with experimental features"
echo "Type EXACTLY: I UNDERSTAND THE RISKS"
read -p "Input: " CONFIRM

if [ "$CONFIRM" != "I UNDERSTAND THE RISKS" ]; then
    echo "Aborted."
    exit 1
fi

# Step 1: System installation
sudo -v
sudo cp /etc/bash.bashrc "/etc/bash.bashrc.backup.$(date +%Y%m%d_%H%M%S)"

cd /tmp
git clone https://github.com/your-org/FlowerOS.git
cd FlowerOS

bash build.sh
sudo bash install-permanent.sh

# Step 2: Network setup
cd network/
make all
sudo make install

# DECISION: Configure network relationships?
# Edit node IPs in node_discovery.cpp (as shown in SCENARIO 4)

# Step 3: GPU setup (if available)
nvidia-smi
# If GPU detected:
cd ../gpu/
# Configure as in SCENARIO 5

# Step 4: Verification
sudo su - testuser -c "
    floweros-info
    flower_network_status
    nvidia-smi
"

echo "✓ Full installation complete"
```

---

## SCENARIO 7: Multi-Machine Deployment (S,Y,N,Y)

**40 minutes • Multiple servers**

```bash
# DECISION: Deployment method? [S=sequential, P=parallel]
# Input: _____

# DECISION: How many machines?
# Input: _____ (number)
NUM_MACHINES=5  # Replace with actual number

# DECISION: Target IPs?
# Input (one per line):
# 192.168.1.10
# 192.168.1.11
# 192.168.1.12
# 192.168.1.13
# 192.168.1.14

# Create machine list
cat > machines.txt << 'EOF'
192.168.1.10
192.168.1.11
192.168.1.12
192.168.1.13
192.168.1.14
EOF

# METHOD 1: Sequential deployment
if [ "$METHOD" == "S" ]; then
    while read MACHINE; do
        echo "Deploying to $MACHINE..."
        
        # Copy installation
        scp -r FlowerOS/ user@$MACHINE:/tmp/
        
        # Install remotely
        ssh user@$MACHINE << 'ENDSSH'
            cd /tmp/FlowerOS
            bash build.sh
            sudo bash install-permanent.sh << 'ANSWERS'
y
y
y
ANSWERS
ENDSSH
        
        echo "✓ $MACHINE complete"
    done < machines.txt
fi

# METHOD 2: Parallel deployment with Ansible
if [ "$METHOD" == "P" ]; then
    # Create inventory
    cat > inventory.ini << 'EOF'
[floweros_nodes]
192.168.1.10
192.168.1.11
192.168.1.12
192.168.1.13
192.168.1.14

[floweros_nodes:vars]
ansible_user=youruser
ansible_become=yes
EOF

    # Create playbook
    cat > deploy-floweros.yml << 'EOF'
---
- hosts: floweros_nodes
  become: yes
  tasks:
    - name: Clone FlowerOS
      git:
        repo: https://github.com/your-org/FlowerOS.git
        dest: /tmp/FlowerOS
        
    - name: Build FlowerOS
      shell: cd /tmp/FlowerOS && bash build.sh
      
    - name: Install FlowerOS
      shell: |
        cd /tmp/FlowerOS
        echo -e "y\ny\ny\n" | bash install-permanent.sh
        
    - name: Verify installation
      command: /opt/floweros/bin/floweros-info
      register: result
      
    - name: Show result
      debug:
        var: result.stdout
EOF

    # Deploy
    ansible-playbook -i inventory.ini deploy-floweros.yml
fi

echo "✓ Multi-machine deployment complete"
```

---

## Quick Command Reference

### Check Prerequisites
```bash
bash --version              # Need 4.0+
gcc --version               # Need gcc
sudo -v                     # Need sudo (system install)
nvidia-smi                  # Check GPU (if using)
nvcc --version              # Check CUDA (if using)
```

### Build & Install
```bash
bash build.sh               # Build everything
bash install.sh             # User install
sudo bash install-permanent.sh  # System install
```

### Network Commands
```bash
cd network/ && make all     # Build network
source lib/terminal_network.sh  # Load functions
flower_plant                # Become worker
flower_grow_tree NAME       # Become master
flower_join_garden IP       # Join master
bin/node_monitor PORT       # Start dashboard
bin/node_discovery          # Start discovery
```

### GPU Commands
```bash
cd gpu/ && make all         # Build GPU
bin/gpu_batch --test        # Test GPU
bin/gpu_batch --info        # GPU info
```

### Verification
```bash
floweros-info               # Version info
floweros-status             # Installation status
flower_network_status       # Network status
ls -la /opt/floweros/       # System install
ls -la ~/.floweros/         # User install
```

### Uninstall
```bash
bash uninstall.sh           # User uninstall
sudo bash remove-permanent.sh  # System uninstall (if exists)
```

---

## Decision Input Template

Copy and fill this out before starting:

```
╔═══════════════════════════════════════════════════════════════╗
║  FLOWEROS DEPLOYMENT DECISIONS                                ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  1. Installation type: [Q/U/S] _____                          ║
║                                                               ║
║  2. Enable network: [Y/N] _____                               ║
║     If Y:                                                     ║
║       - Mode: [S/L/C] _____                                   ║
║       - Port: _____ (default: 7777)                           ║
║       - Node type: [P/T/J] _____                              ║
║       - Cluster name: _____________ (if T)                    ║
║       - Master IP: ___.___.___.___  (if J)                    ║
║                                                               ║
║  3. Enable GPU: [Y/N] _____                                   ║
║     If Y:                                                     ║
║       - Architecture: sm_____                                 ║
║       - Batch size: [S/M/L/C] _____                           ║
║       - Custom size: _____ (if C)                             ║
║                                                               ║
║  4. Multi-machine: [Y/N] _____                                ║
║     If Y:                                                     ║
║       - Method: [S/P] _____                                   ║
║       - Number of machines: _____                             ║
║       - IPs: (list below)                                     ║
║         ___.___.___.___                                       ║
║         ___.___.___.___                                       ║
║         ___.___.___.___                                       ║
║                                                               ║
║  5. Shell integration: [B/Z/F/A] _____                        ║
║                                                               ║
║  6. Startup mode: [Q/W/F/C] _____                             ║
║     Custom message: _________________ (if C)                  ║
║                                                               ║
║  7. Theme: [1/2/3/4/5/N] _____                                ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

**FlowerOS v1.3.0 - Command Reference**  
*Copy, paste, deploy.* 🚀🌱
