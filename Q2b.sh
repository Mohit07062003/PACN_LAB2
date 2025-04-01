import os
import time
import random
import subprocess

def run_command(cmd):
    print(f"Executing: {cmd}")
    os.system(cmd)

def setup_network():
    namespaces = ['A', 'B', 'C', 'D', 'E']
    edges = [('A', 'B'), ('D', 'A'), ('B', 'C'), ('E', 'B'), ('C', 'D'), ('C', 'E')]
    
    for ns in namespaces:
        run_command(f"ip netns add {ns} 2>/dev/null")
    
    for i, (ns1, ns2) in enumerate(edges):
        run_command(f"ip link add veth{i}a type veth peer name veth{i}b")
        run_command(f"ip link set veth{i}a netns {ns1}")
        run_command(f"ip link set veth{i}b netns {ns2}")
    
    for i, (ns1, ns2) in enumerate(edges):
        run_command(f"ip netns exec {ns1} ip addr add 192.168.{i}.1/24 dev veth{i}a")
        run_command(f"ip netns exec {ns2} ip addr add 192.168.{i}.2/24 dev veth{i}b")
        run_command(f"ip netns exec {ns1} ip link set veth{i}a up")
        run_command(f"ip netns exec {ns2} ip link set veth{i}b up")

def observe_traffic(ns, interface, filename):
    run_command(f"ip netns exec {ns} tcpdump -i {interface} -w {filename} &")

def activate_edge(ns, interface):
    run_command(f"ip netns exec {ns} ip link set {interface} up")

def deactivate_edge(ns, interface):
    run_command(f"ip netns exec {ns} ip link set {interface} down")

def send_parallel_pings(edges):
    processes = []
    for i, (ns1, ns2) in enumerate(edges):
        cmd = f"ip netns exec {ns1} ping -i 1 192.168.{i}.2"
        proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        processes.append(proc)
    return processes

def stop_pings(processes):
    for proc in processes:
        proc.terminate()

def probabilistic_scheduling(edges, T, N):
    slot_duration = T // N
    for _ in range(N):
        ns1, ns2 = random.choice(edges)
        interface = f"veth{edges.index((ns1, ns2))}a"
        print(f"Activating edge {ns1} -> {ns2}")
        activate_edge(ns1, interface)
        time.sleep(slot_duration)
        deactivate_edge(ns1, interface)

def deterministic_scheduling(edge_sets, edges, T, N):
    slot_duration = T // N
    for edge_set in edge_sets:
        for ns1, ns2 in edge_set:
            interface = f"veth{edges.index((ns1, ns2))}a"
            activate_edge(ns1, interface)
        time.sleep(slot_duration)
        for ns1, ns2 in edge_set:
            interface = f"veth{edges.index((ns1, ns2))}a"
            deactivate_edge(ns1, interface)


def main():
    setup_network()
    edges = [('A', 'B'), ('D', 'A'), ('B', 'C'), ('E', 'B'), ('C', 'D'), ('C', 'E')]
    
    ping_processes = send_parallel_pings(edges)
    
    observe_traffic('B', 'veth0b', 'probabilistic.pcap')
    probabilistic_scheduling(edges, T=50, N=5)
    run_command("pkill tcpdump")
    
    edge_sets = [[('A', 'B'), ('C', 'D')], [('D', 'A'), ('C', 'E')], [('E', 'B'), ('B', 'C')]]
    observe_traffic('B', 'veth0b', 'deterministic.pcap')
    deterministic_scheduling(edge_sets, edges, T=50, N=5)
    run_command("pkill tcpdump")
    
    stop_pings(ping_processes)
    
    
    print("Experiment completed.")

if __name__ == "__main__":
    main()
