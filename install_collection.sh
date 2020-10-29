#!/usr/bin/env bash

rm -rf ~/.ansible/collections/ansible_collections/appdynamics #uninstall the collection if it exists

#build a new one 
collection_file=$(basename $(ansible-galaxy collection build -f | awk -F" " '{print $NF}'))

ansible-galaxy collection install "${collection_file}"

rm -rf "${collection_file}"

 