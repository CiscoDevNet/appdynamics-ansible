# AppDynamics role to install the Machine Agent 

Use `machine-win` as `agent_type` parameter value for Windows OS. 

```yml
---
- hosts: linux
  tasks:
    - include_role:
        name: appdynamics.agents.machine
      vars:
        # Define Agent Type and Version
        agent_version: 20.9.0
        agent_type: machine
        # Your controller details 
        controller_account_access_key: "b0248ceb-c954-4a37-97b5-207e90418cb4" # Please add this to your Vault
        controller_global_analytics_account_name: 'customer1_e2f90621-ab21-4bf4-908c-872d213c7f64' # Please add this to your Vault
        controller_host_name: "ansible-20100nosshcont-bum4wzwa.appd-cx.com" # Your AppDynamics controller
        controller_account_name: "customer1" # Please add this to your Vault
        sim_enabled: "true"
        enable_ssl: "false"
        controller_port: "8090"
        analytics_event_endpoint: "http://ansible-20100nosshcont-bum4wzwa.appd-cx.com:7001"
        enable_analytics_agent: "true"
        machine_hierarchy: "AppName|Owners|Environment|" # Make sure it ends with a |

```