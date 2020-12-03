# AppDynamics Ansible Collection

The AppDynamics Ansible Collection installs and configures AppDynamics agents and configurations. All supported agents are downloaded from the download portal unto the Ansible control node automatically –– this makes it easy to acquire and upgrade agents declaratively. 

Refer to the [role variables](#Role-Variables) below for a description of available deployment options. 

We have built this AppDynamics collection to support (immutable) infrastructure as code deployment methodology; this means that the AppDynamics collection will NOT preserve any manual configurations on the target servers. In other words, the ansible roles will overwrite any local or pre-existing configuration. 
We strongly recommend that you convert any custom agent configuration (this collection does not support that) into an ansible role to ensure consistency of deployments and configurations across your estate. 


## Requirements

- Requires Ansible >=2.8.0
- Supports most Debian and RHEL-based Linux distributions, and Windows.
- Windows OS requires >= Powershell 5.0
- Network/firewall access to download AppDynamics agents from `https://download-files.appdynamics.com` and `https://download.appdynamics.com` on the Ansible control node  

<b>Note:</b>  <a href="https://stedolan.github.io/jq/"> `jq` </a> is required on the Ansible control node. The collection automatcially  installs `jq` to the control node if it is not installed. 

## Supported Agents

|  <img width="200"/> Agent type | Description |
|--|--|
|`sun-java`   or     `java`   | Agent to monitor Java applications running on JRE version 1.7 and less |
|`sun-java8`   or     `java8`   | Agent to monitor Java applications running on JRE version 1.8 and above |
|`ibm-java` | Agent to monitor Java applications running on IBM JRE |
|`dotnet` | Agent to monitor Full .Net Framework application on Windows |
|`machine` | 64 Bit Machine agent ZIP bundle with JRE |
|`db` | Agent to monitor Databases|
|`dotnet-core*` | Agent to Monitor .NetCore applications on Linux|

<i> `*`  Coming soon...</i><br>

The agent binaries and the installation process for the Machine and DB agent depend on the OS type –– Windows or Linux. This AppDynamics collection abstracts the OS differences so you should only have to provide `agent_type`, without necessarily specifying your OS type.  

## Installation

Install the <a href="https://galaxy.ansible.com/appdynamics"> AppDynamics Collection </a> from Ansible Galaxy on your Ansible server:

```shell
ansible-galaxy collection install appdynamics.agents
```

## Playbooks
Example playbooks for each agent type is provided in the collections's `playbooks` folder.  
You should either reference the example playbooks in the collection installation folder, or access the examples in the GitHub <a href="https://github.com/Appdynamics/appdynamics-ansible/tree/master/playbooks"> repository </a>. 

The `var/playbooks/controller.yaml` file is meant to contain constant variables such as `enable_ssl`, `controller_port`, etc. You may either use this var or overwrite the variables in the playbooks - whatever works best for you. 

## Java agent

```yml
---
  - hosts: all
    tasks:
      - name: Include variables for the controller settings
        include_vars: vars/controller.yaml
      - include_role:
          name: appdynamics.agents.java
        vars:
          agent_version: 20.10.0
          agent_type: java8
          application_name: "IoT_API" # ONLY required if agent type is not machine or db
          tier_name: "java_tier" # ONLY required if agent type is not machine or db
          # Directory permissions for agent. These can be set at host level in the invertory as well
          agent_dir_permission:  #defaults to root:root if not specified
            user:  "appdynamics" # This user must pre-exist. It is recommended to use the PID owner of your Java app
            group: "appdynamics" # This group must pre-exist
```

### DotNet agent
In the playbook below, the parameters are initialised directly in the yaml file rather than including them from `var/playbooks/controller.yaml`

```yml
---
- hosts: windows
  tasks:
    - include_role:
        name: appdynamics.agents.dotnet
      vars:
        agent_version: 20.8.0
        agent_type: dotnet
        application_name: 'IoT_API'
        # Your controller details
        controller_account_access_key: "123456" # Please add this to your Vault
        controller_global_analytics_account_name: "customer1_GUID" # Please add this to your Vault
        controller_host_name: "fieldlab.saas.appdynamics.com" 
        controller_account_name: "customer1" # Please add this to your Vault
        enable_ssl: "true"
        controller_port: "443"
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

```yml
---
- hosts: all
  tasks:
    - include_role:
        name: appdynamics.agents.machine
      vars:
        # Define Agent Type and Version
        agent_version: 20.9.0
        agent_type: machine
        machine_hierarchy: "AppName|Owners|Environment|" # Make sure it ends with a |
        sim_enabled: "true"
        # Analytics settings
        analytics_event_endpoint: "https://fra-ana-api.saas.appdynamics.com:443"
        enable_analytics_agent: "true"
        # Your controller details
        controller_account_access_key: "123key" # Please add this to your Vault
        controller_host_name: "fieldlab.saas.appdynamics.com" # Your AppDynamics controller
        controller_account_name: "customer1" # Please add this to your Vault
        enable_ssl: "false"
        controller_port: "8090"
        controller_global_analytics_account_name: 'customer1_e52eb4e7-25d2-41c4-a5bc-9685502317f2' # Please add this to your Vault
        # config properties docs - https://docs.appdynamics.com/display/latest/Machine+Agent+Configuration+Properties
        # Can be used to configure the proxy for the agent
        java_system_properties: "-Dappdynamics.http.proxyHost=10.0.4.2 -Dappdynamics.http.proxyPort=9090" # mind the space between each property
```

## Role Variables

|<img width="200"/>  Variable   | Description | Agent Type |
|--|--|--|
|`agent_type`   | AppDynamics agent type.  java, machine, etc  | All |
|`agent_version`  | AppDynamics agent version. AppDynamics uses calendar versioning. For example, if a Java agent is released in November of 2020, its version will begin with 20.11.0. When the Java agent team releases again in the month of November, the new agent will be 20.11.1  | All |
|`application_name`   | The AppDynamics business application name, this variable is compulsory for all the  `dotnet`, `java` and `dotnetcore` roles  | All |
|`tier_name`   | The AppDynamics tier name, this variable is compulsory for all the `dotnet`, `java` and `dotnetcore` roles  | All |
|`controller_host_name`   | The  controller host name, do not include `http(s)` | All |
|`controller_account_name`   | Controller account name   | All |
|`controller_account_access_key` | Account or license rule access key. This should ideally be placed into your vault | All |
|`controller_account_name` |  Account name | All |
|`controller_port`   | The controller port   | All |
|`enable_ssl`   | Indicate if SSL is enabled in the controller or not | All |
|`db_agent_name` | Name assigned to the agent, typically used to allow one Database Agent  to act as a backup to another one | DB 
|`install_jre`| Set this parameter to false if the JRE should not be installed together with the DB agent. <br><br>**Note:** To install java on windows, we automatically install lean_delivery.java role from galaxy to your control node | DB
|`services`| List of stand-alone services to be instrumented with the .NET agent| .NET
|`monitor_all_IIS_apps`| Enable automatic instrumentation of all IIS applications | .NET
|`runtime_reinstrumentation` | Runtime re-instrumentation works for .NET Framework 4.5.2 and greater. Note: Make sure you test this first in a non-production environment | .NET |
|`agent_dir_permission.user` `agent_dir_permission.group` | user and group file permissions to assign to the java-agent on linux. The user and group selected must already exist on the host. If the parameters are omitted the permissions will default to root | Java
|`java_system_properties`| can be used to configure proxy setting for agents | DB, Machine
|`analytics_event_endpoint`   | Your Events Service URL   | Machine |
|`enable_analytics_agent`   | Indicate if analytics agent should be enabled in the Machine agent | Machine |
|`sim_enabled` | Enable server infrastructure monitoring | Machine
|`controller_global_analytics_account_name`| This is the global account name of the controller | Machine
