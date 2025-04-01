#!/bin/bash

# 🛑 Stop on any error
set -e

echo "🔧 Setting up network namespaces..."

# Create four network namespaces
sudo ip netns add NetNsA
sudo ip netns add NetNsB
sudo ip netns add NetNsC
sudo ip netns add NetNsD

# Create veth (virtual Ethernet) pairs to connect namespaces
sudo ip link add vethAB type veth peer name vethBA
sudo ip link add vethCD type veth peer name vethDC

# Assign vethAB to NetNsA and vethBA to NetNsB
sudo ip link set vethAB netns NetNsA
sudo ip link set vethBA netns NetNsB

# Assign vethCD to NetNsC and vethDC to NetNsD (for future expansion)
sudo ip link set vethCD netns NetNsC
sudo ip link set vethDC netns NetNsD

# Assign IP addresses
sudo ip netns exec NetNsA ip addr add 192.168.1.1/24 dev vethAB
sudo ip netns exec NetNsB ip addr add 192.168.1.2/24 dev vethBA

# Bring up interfaces
sudo ip netns exec NetNsA ip link set vethAB up
sudo ip netns exec NetNsB ip link set vethBA up
sudo ip netns exec NetNsA ip link set lo up
sudo ip netns exec NetNsB ip link set lo up

# 🏓 Run ping test between NetNsA and NetNsB
echo "🏓 Running initial ping test..."
sudo ip netns exec NetNsA ping -c 5 192.168.1.2

# 🌐 Add 20% packet loss
echo "🌐 Adding 20% packet loss..."
sudo ip netns exec NetNsA tc qdisc add dev vethAB root netem loss 20%

# 📡 Run ping test again with packet loss
echo "🏓 Running ping test with 20% packet loss..."
sudo ip netns exec NetNsA ping -c 10 192.168.1.2

echo "✅ Network setup complete!"
