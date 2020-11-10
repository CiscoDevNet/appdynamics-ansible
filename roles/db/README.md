# AppDynamics role to install the Database agent

This role currently supports Linux only, Windows support will be released soon.

```yml
---
- hosts: linux
  tasks:
    - include_role:
        name: appdynamics.agents.db
      vars:
        agent_version: 20.9.0
        agent_type: db
        controller_account_access_key: "b0248ceb-c954-4a37-97b5-207e90418cb4" # Please add this to your Vault
        controller_host_name: "ansible-20100nosshcont-bum4wzwa.appd-cx.com" # Your AppDynamics controller
        controller_account_name: "customer1" # Please add this to your Vault
        enable_ssl: "false"
        controller_port: "8090"
        db_agent_name: "ProdDBAgent"
```