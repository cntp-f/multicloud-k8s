#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

function set_kyes(){
    echo "[*]Setting keys..."
    if ! [ -f ~/.ssh/id_rsa ]; then
        echo "[*]Generating rsa key for this host"
        ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa <&-
    fi
    if ! grep -qF "$(ssh-keygen -y -f ~/.ssh/id_rsa)" ~/.ssh/authorized_keys; then
        echo "[*]Allowing present ~/.ssh/id_rsa key to be used for login to this host"
        ssh-keygen -y -f ~/.ssh/id_rsa >> ~/.ssh/authorized_keys
    fi
    chmod og-wx ~/.ssh/authorized_keys
}

function gen_ansible_hosts(){
    
    # For aio inventory by default get ovn central ip from local host default interface.
    # This variable used only in this file, but env variable defined to enable user to override it prior calling aio.sh.
    OVN_CENTRAL_IP_ADDRESS=${OVN_CENTRAL_IP_ADDRESS:-$(hostname -I | cut -d ' ' -f 1)}
    echo "[*]Preparing inventory for ansible"
cat <<EOF > inventory/hosts.ini
[all]
localhost ansible_ssh_host=${OVN_CENTRAL_IP_ADDRESS} ansible_ssh_port=22

[kube-master]
localhost

[kube-node]
localhost

[etcd]
localhost

[ovn-central]
localhost

[ovn-controller]
localhost

[virtlet]
localhost

[k8s-cluster:children]
kube-node
kube-master
EOF
}

function enable_nested_virtulization(){
    echo "[*]Enabling nested-virtualization"
    sudo ./node.sh
}


function deploy_kud(){
    echo "[*]Deploying KUD project"
    ./installer.sh | tee kud_installer.log
}

function get_path(){
    SCRIPT=$(readlink -f "$0")
    SCRIPTPATH=$(dirname "$SCRIPT")
    echo $SCRIPTPATH
}

### main worflow
aio_dir=$(get_path)
cd ${aio_dir}/../vagrant

set_kyes
gen_ansible_hosts
enable_nested_virtulization
deploy_kud