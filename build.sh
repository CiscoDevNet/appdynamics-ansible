#!/usr/bin/env bash

rm -rf /Users/israel.ogbole/.ansible/collections/ansible_collections/appdynamics
rm -rf appdynamics-agents-20.8.0.tar.gz

ansible-galaxy collection build --force 

ansible-galaxy collection install appdynamics-agents-20.8.0.tar.gz

rm -rf appdynamics-agents-20.8.0.tar.gz
