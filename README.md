# Ansible AppDynamics Collection

The AppDynamics collection installs and configures AppDynamics agents and configurations.

## Setup

### Requirements

- Requires Ansible >=2.8.0
- Supports most Debian and RHEL-based Linux distributions, and Windows.
- Windows OS requires >= Powershell 5.0 for the `Machine Agent`
- Network firewall access to download AppDynamics agents from `https://download-files.appdynamics.com` and `https://download.appdynamics.com` to the Ansible controller.  

Note:  <a href="https://stedolan.github.io/jq/"> `jq` </a> is required on the Ansible controller. The AppDynamics collection installs automatically installed `jq` if it is not installed on the Ansible controller.

### Installation

Install the <a href="https://galaxy.ansible.com/appdynamics"> AppDynamics Collection </a> from Ansible Galaxy on your Ansible server:

```shell
ansible-galaxy collection install appdynamics.agents
```

## Supported Agents

|  <img width="200"/> Agent type | Description |
|--|--|
|`sun-java`   or     `java`   | Agent to monitor Java applications (All Vendors) running on JRE version 1.7 and less |
|`sun-java8`   or     `java8`   | Agent to monitor Java applications (All Vendors) running on JRE version 1.8 and above |
|`ibm-java` | Agent to monitor Java applications (All Vendors) running on IBM JRE |
|`dotnet` | Agent to monitor Full .Net Framework application on Windows |
|`machine` | 64 Bit Machine agent ZIP bundle with JRE to monitor your Linux servers |
|`machine-win` | 64 Bit Machine agent ZIP bundle with JRE to monitor your windows servers. |
|`db` | Agent to monitor Databases|
|`db-win*` | Agent to monitor any combination of DB2, Oracle, SQL Server, Sybase, MySQL, Sybase IQ and PostgreSQL database platforms. Windows Install|
|`dotnet-core*` | Agent to Monitor .NetCore applications on Linux|
|`dotnet-core-win*` | Agent to Monitor .NetCore applications on Windows |

<i> `*`  Coming soon...</i>

## Playbooks

### Java agent

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

### DotNet agent

```yml
---
- hosts: windows
  tasks:
    - include_role:
        name: appdynamics.agents.dotnet
      vars:
        # Define Agent Type and Version
        agent_version: 20.8.0
        agent_type: dotnet
        # The applicationName
        application_name: 'IoT_API'
        tier_name: 'login_service2' # ONLY required if agent type is not machine and db agent
        # Your controller details 
        controller_account_access_key: "b0248ceb-c954-4a37-97b5-207e90418cb4" # Please add this to your Vault
        controller_global_analytics_account_name: "customer1_e2f90621-ab21-4bf4-908c-872d213c7f64" # Please add this to your Vault
        controller_host_name: "ansible-20100nosshcont-bum4wzwa.appd-cx.com" # Your AppDynamics controller
        controller_account_name: "customer1" # Please add this to your Vault 
        enable_ssl: "false"
        controller_port: "8090"
        enable_proxy: "true"  #use quotes please 
        proxy_host: "10.0.1.3"
        proxy_port: "80"
        monitor_all_IIS_apps: "false"  # Enable automatic instrumentation of all IIS applications 
        runtime_reinstrumentation: "true" # Runtime reinstrumentation works for .NET Framework 4.5.2 and greater.
        # Define standalone executive applications to monitor
        services:
          - login.exe
          - tmw.exe
          - mso.exe
```

### Machine agent

#### Linux

`agent_type: machine`

#### Windows

`agent_type: machine-win`

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

### Database agent

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

## Role Variables

|<img width="200"/>  variable   | Description |
|--|--|
|`agent_type`   | AppDynamics agent type.  java, machine, etc  |
|`agent_version`  | AppDynamics agent version. AppDynamics uses calendar versioning. For example, if a Java agent is released in November of 2020, it’s version will begin with 20.11.0. When the Java agent team releases again in the month of November, the new agent will be 20.11.1  |
|`application_name`   | The AppDynamics business application name, this variable is compulsory for all the  dotnet, java and dotnetcore roles  |
|`tier_name`   | The AppDynamics tier name, this variable is compulsory for all the  dotnet, java and dotnetcore roles  |
|`controller_host_name`   | The  controller host name, do not include `http(s)` |
|`controller_account_name`   | Controller account name   |
|`controller_port`   | The Controller port   |
|`enable_ssl`   | Indicate if SSL is enabled in the controller or not |
|`enable_ssl`   | Indicate if SSL is enable or not  |
