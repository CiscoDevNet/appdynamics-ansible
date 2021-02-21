# AppDynamics role to install the Java agent

Use `sun-java8` instead of `sun-java` as `agent_type` if the instrumented application runs on JRE 8+ 

```yml
---
- hosts: all
  tasks:
    - include_role:
        name: appdynamics.agents.java
      vars:
        # Define Agent Type and Version 
        agent_type: sun-java
        agent_version: 20.9.0
        # The applicationName
        application_name: "IoT_API" # ONLY required if agent type is not machine or db
        tier_name: "java_tier" # ONLY required if agent type is not machine or db
        # Your controller details 
        controller_account_access_key: "b0248ceb-c954-4a37-97b5-207e90418cb4" # Please add this to your Vault 
        controller_host_name: "ansible-20100nosshcont-bum4wzwa.appd-cx.com" # Your AppDynamics controller 
        controller_account_name: "customer1" # Please add this to your Vault 
        enable_ssl: "false"
        controller_port: "8090"

```


## Instrumentation

# Common vars
service - systemd service
restart_app - 
user - pid user that should be added to appdynamics group
application_name:
tier_name: 
node_name: 
backup: whether to make backup modified files or not

# Jboss specific:
jboss_config
