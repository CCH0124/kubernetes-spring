# -*- mode: ruby -*-
# vi: set ft=ruby :

servers = [
    {
        :name => "master-spring",
        :type => "master",
        :box => "generic/ubuntu2004",
        :eth1 => "192.168.56.20",
        :mem => "2048",
        :cpu => "2"
    },
    {
        :name => "node1-spring",
        :type => "node",
        :box => "generic/ubuntu2004",
        :eth1 => "192.168.56.21",
        :mem => "2048",
        :cpu => "2"
    },
    {
        :name => "node2-spring",
        :type => "node",
        :box => "generic/ubuntu2004",
        :eth1 => "192.168.56.22",
        :mem => "2048",
        :cpu => "2"
    }
]

# This script to install k8s using kubeadm will get executed after a box is provisioned
$configureBox = <<-SCRIPT
    set -e -x -u
    export DEBIAN_FRONTEND=noninteractive
    # CRI-O

    #Disable swap
    sudo swapoff -a && sudo sysctl -w vm.swappiness=0
    sudo sed '/vagrant--vg-swap/d' -i /etc/fstab
    # Create the .conf file to load the modules at bootup
    cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF 
    sudo modprobe overlay
    sudo modprobe br_netfilter
    # Set up required sysctl params, these persist across reboots.
    cat << EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
    # Kernel settings
    cat << EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
    
    sudo sysctl --system >/dev/null 2>&1


    # add CRI-O package repository
    export OS=xUbuntu_20.04
    export VERSION=1.23
    cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF
    cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF

    curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
    curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers-cri-o.gpg add -
    sudo apt-get update
    sudo apt-get install cri-o cri-o-runc -y
    ## start CRI-O
    sudo systemctl daemon-reload
    sudo systemctl enable crio
    sudo systemctl start crio

    # install kubeadm
    sudo apt-get install -y apt-transport-https curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee --append /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet=1.23.0-00 kubeadm=1.23.0-00 kubectl=1.23.0-00
    sudo apt-mark hold kubelet kubeadm kubectl
    
        # config /etc/default/kubelet for CRI-O
    cat << EOF | sudo tee /etc/default/kubelet
    # issue https://blog.yonabeshite.com/2021/09/351/
KUBELET_EXTRA_ARGS=--feature-gates="AllAlpha=false" --container-runtime=remote --cgroup-driver=systemd --container-runtime-endpoint='unix:///var/run/crio/crio.sock' --runtime-request-timeout=5m
EOF
    # hosts
    cat >>/etc/hosts<<EOF
192.168.56.20 cch.master k8s-master master
192.168.56.21 cch.node1 k8s-node-1 node1
192.168.56.22 cch.node2 k8s-node-2 node2
EOF

SCRIPT


$configureMaster = <<-SCRIPT
    # install helm
    curl -s https://baltocdn.com/helm/signing.asc | sudo apt-key add -
    sudo apt-get install apt-transport-https --yes
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee -a /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm -y
    # install other tool
    sudo apt-get install -y vim git cmake build-essential tcpdump tig jq socat bash-completion

    # install k8s master

    git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
    bash ~/.bash_it/install.sh -s
    
    sudo modprobe br_netfilter
    sudo su -c "echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables"

    HOST_NAME=$(hostname -s)
    sudo kubeadm init --skip-phases=addon/kube-proxy --apiserver-advertise-address=$1 --apiserver-cert-extra-sans=$1  --node-name $HOST_NAME --pod-network-cidr=10.10.0.0/16 --cri-socket="/var/run/crio/crio.sock" 

    #copying credentials to regular user - vagrant
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    echo "copying credentials"
    # install cilium pod network addon
    helm repo add cilium https://helm.cilium.io/
    helm install cilium cilium/cilium --version 1.11.0 \
    --namespace kube-system \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=$1  \
    --set k8sServicePort=6443 \
    --set nodePort.enabled=true \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,http}"
    
    sudo kubeadm token create --print-join-command >> $HOME/kubeadm_join_cmd.sh
    sudo chmod +x $HOME/kubeadm_join_cmd.sh

    echo 'source <(kubectl completion bash)' >>~/.bashrc

    # required for setting up password less ssh between guest VMs
    sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
    sudo systemctl restart sshd.service

SCRIPT

$configureNode = <<-SCRIPT
    sudo modprobe br_netfilter
    sudo su -c "echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables"
    echo "This is worker"
    sudo apt-get install -y sshpass
    sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@192.168.56.20:/home/vagrant/kubeadm_join_cmd.sh .
    sudo ./kubeadm_join_cmd.sh
SCRIPT


Vagrant.configure("2") do |config|

    servers.each do |opts|
        config.vm.define opts[:name] do |config|

            config.vm.box = opts[:box]
            config.vm.hostname = opts[:name]
            config.vm.network :private_network, ip: opts[:eth1]
            config.vm.define vm_name = opts[:name]
            config.vm.provider "virtualbox" do |v|
#		v.gui = true
                v.name = opts[:name]
                v.customize ['modifyvm', :id, '--nicpromisc1', 'allow-all']
                v.customize ["modifyvm", :id, "--memory", opts[:mem]]
                v.customize ["modifyvm", :id, "--cpus", opts[:cpu]]

            end
            config.vm.provision "shell",privileged: true, inline: $configureBox

            if opts[:type] == "master"
                config.vm.provision "shell", privileged: false, inline: $configureMaster, args: opts[:eth1]
            else
                config.vm.provision "shell", privileged: false, inline: $configureNode
            end

        end

    end

end
