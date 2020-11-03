#!/usr/bin/env bash

rm -rf ~/.ansible/collections/ansible_collections/appdynamics #uninstall the collection if it exists

#build a new one 
echo "Build collection"
collection_file=$(basename "$(ansible-galaxy collection build -f | awk -F" " '{print $NF}')")

echo "Built file - ${collection_file}"

echo "Install collection from - ${collection_file}"
ansible-galaxy collection install "${collection_file}"

rm -rf "${collection_file}"

 