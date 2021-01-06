# AppDynamics role to install the .NET Core agent

```yml
---
- hosts: linux
  tasks:
    - include_role:
        name: appdynamics.agents.dotnetcore
      vars:
        # Define Agent Type and Version
        agent_type: dotnetcore
        agent_version: 20.9.0
        # The applicationName
        application_name: "IoT_API" # ONLY required if agent type is not machine or db
        tier_name: "dotnetcore_tier" # ONLY required if agent type is not machine or db
        # Your controller details 
        controller_account_access_key: "b0248ceb-c954-4a37-97b5-207e90418cb4" # Please add this to your Vault
        controller_host_name: "ansible-20100nosshcont-bum4wzwa.appd-cx.com" # Your AppDynamics controller
        controller_account_name: "customer1" # Please add this to your Vault
        enable_ssl: "false"
        controller_port: "8090"

```
