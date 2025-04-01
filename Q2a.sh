set -e

echo "🔧 Setting up four network namespaces (NetNsA, NetNsB, NetNsC, NetNsD)..."

# Create network namespaces
sudo ip netns add NetNsA
sudo ip netns add NetNsB
sudo ip netns add NetNsC
sudo ip netns add NetNsD

# Create virtual Ethernet (veth) pairs to form a mesh network
sudo ip link add vethAB type veth peer name vethBA
sudo ip link add vethAC type veth peer name vethCA
sudo ip link add vethBD type veth peer name vethDB
sudo ip link add vethCD type veth peer name vethDC

# Assign veth interfaces to the respective namespaces
sudo ip link set vethAB netns NetNsA
sudo ip link set vethBA netns NetNsB
sudo ip link set vethAC netns NetNsA
sudo ip link set vethCA netns NetNsC
sudo ip link set vethBD netns NetNsB
sudo ip link set vethDB netns NetNsD
sudo ip link set vethCD netns NetNsC
sudo ip link set vethDC netns NetNsD

# Assign IP addresses for communication
sudo ip netns exec NetNsA ip addr add 192.168.1.1/24 dev vethAB
sudo ip netns exec NetNsB ip addr add 192.168.1.2/24 dev vethBA
sudo ip netns exec NetNsA ip addr add 192.168.1.3/24 dev vethAC
sudo ip netns exec NetNsC ip addr add 192.168.1.4/24 dev vethCA
sudo ip netns exec NetNsB ip addr add 192.168.1.5/24 dev vethBD
sudo ip netns exec NetNsD ip addr add 192.168.1.6/24 dev vethDB
sudo ip netns exec NetNsC ip addr add 192.168.1.7/24 dev vethCD
sudo ip netns exec NetNsD ip addr add 192.168.1.8/24 dev vethDC

# Bring up interfaces
for ns in NetNsA NetNsB NetNsC NetNsD; do
    sudo ip netns exec $ns ip link set lo up
done

sudo ip netns exec NetNsA ip link set vethAB up
sudo ip netns exec NetNsB ip link set vethBA up
sudo ip netns exec NetNsA ip link set vethAC up
sudo ip netns exec NetNsC ip link set vethCA up
sudo ip netns exec NetNsB ip link set vethBD up
sudo ip netns exec NetNsD ip link set vethDB up
sudo ip netns exec NetNsC ip link set vethCD up
sudo ip netns exec NetNsD ip link set vethDC up

# 🏓 Run ping tests in the mesh network
echo "🏓 Running ping tests in the mesh network..."
sudo ip netns exec NetNsA ping -c 5 192.168.1.2
sudo ip netns exec NetNsA ping -c 5 192.168.1.4
sudo ip netns exec NetNsB ping -c 5 192.168.1.6
sudo ip netns exec NetNsC ping -c 5 192.168.1.8

echo "✅ Network mesh setup and testing complete!"
