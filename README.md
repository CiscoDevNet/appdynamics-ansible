
# Ansible AppDynamics Collection

The AppDynamics collection installs and configures AppDynamics agents and configurations. Refer to the
[role variables](#Role-Variables) below for a description of available deployment options. It should be noted that
the implementation as provided does not preserve custom configuration settings applied subsequent
to the initial agent installation.

## Setup

### Requirements

- Requires Ansible >=2.8.0
- Supports most Debian and RHEL-based Linux distributions, and Windows.
- Windows OS requires >= Powershell 5.0 for the `Machine agent`, `DotNet agent` and `Java agent`
- Network firewall access to download AppDynamics agents from `https://download-files.appdynamics.com` and `https://download.appdynamics.com` to the Ansible controller.  

Note:  <a href="https://stedolan.github.io/jq/"> `jq` </a> is required on the Ansible controller. The AppDynamics collection installs `jq` if it is not installed on the Ansible controller node.

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
|`machine-win`** | 64 Bit Machine agent ZIP bundle with JRE to monitor your windows servers. |
|`db` | Agent to monitor Databases|
|`db-win`** | Agent to monitor any combination of DB2, Oracle, SQL Server, Sybase, MySQL, Sybase IQ and PostgreSQL database platforms. Windows Install|
|`dotnet-core*` | Agent to Monitor .NetCore applications on Linux|
|`dotnet-core-win*` | Agent to Monitor .NetCore applications on Windows |

<i> `*`  Coming soon...</i><br>
<i> `**` When installing the Machine or DB agents on Windows, the agent type
selected in the playbook should be 'machine' or 'db' without the '-win'
suffix, which is added automatically based on the OS family of the host</i>

## Playbooks

### Java agent

For testing purposes you can specify the target controller parameters either directly in the
sample playbooks, or you can include them as shown below from the provided common "controller.yaml" file.

```yml
---
  - hosts: all
    tasks:
      - name: Include variables for the controller settings
        include_vars: vars/controller.yaml

      - include_role:
          name: appdynamics.agents.java
        vars:
          # Define Agent Type and Version
          agent_version: 20.10.0
          agent_type: java8

          # The applicationName
          application_name: "IoT_API" # ONLY required if agent type is not machine or db
          tier_name: "java_tier" # ONLY required if agent type is not machine or db

          # Directory permissions for agent. These can be set at host level in the invertory as well
          agent_dir_permission:  #defaults to root:root if not specified
            user:  "appdynamics" # This user must pre-exist. It is recommended to use the PID owner of your Java app
            group: "appdynamics" # This group must pre-exist
```

### DotNet agent
In the playbook below, the parameters are initialised directly in the yaml file rather than including them.
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

        # config properties docs - https://docs.appdynamics.com/display/latest/Machine+Agent+Configuration+Properties
        # Can be used to configure the proxy for the agent
        java_system_properties: "-Dappdynamics.http.proxyHost=10.0.4.2 -Dappdynamics.http.proxyPort=9090" # mind the space between each property

        # Analytics settings
        analytics_event_endpoint: "https://lncontroller20103-2010-o8evv8rp.appd-cx.com:9080"
        enable_analytics_agent: "true"

        # Your controller details
        controller_account_access_key: "b0248ceb-c954-4a37-97b5-207e90418cb4" # Please add this to your Vault
        controller_host_name: "ansible-20100nosshcont-bum4wzwa.appd-cx.com" # Your AppDynamics controller
        controller_account_name: "customer1" # Please add this to your Vault
        enable_ssl: "false"
        controller_port: "8090"
        controller_global_analytics_account_name: 'customer1_e52eb4e7-25d2-41c4-a5bc-9685502317f2' # Please add this to your Vault
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
|`agent_log_level` | set the log level for the agent. valid options are : **info, trace, debug, warn, error, fatal, all** and **off**. This setting is applied to all the loggers named in the **`agent_loggers`** list| Machine, DB, Java
|`agent_loggers` | List of loggers to set the log level on. The logger names vary from agent to agent. The default is set to ['com.singularity','com']. Update this variable with loggers specific to the target agent as required (refer to the log4j files in the <get-home>/conf/logging directory for more info). | Machine, DB, Java
|`db_agent_name` | Name assigned to the agent, typically used to allow one Database Agent  to act as a backup to another one | DB
|`install_jre`| Set this parameter to false if the JRE should not be installed together with the DB agent. <br><br>**Note:** to install java on windows, you need to run the <i>install-roles.yml</i> playbook first, which adds a galaxy role (lean_delivery.java) to you local playbook folder | DB
|`services`| List of stand-alone services to be instrumented with the .NET agent| .NET
|`monitor_all_IIS_apps`| Enable automatic instrumentation of all IIS applications | .NET
|`runtime_reinstrumentation` | Runtime re-instrumentation works for .NET Framework 4.5.2 and greater. Note: Make sure you test this first in a non-production environment | .NET |
|`agent_dir_permission.user` `agent_dir_permission.group` | user and group file permissions to assign to the java-agent on linux. The user and group selected must already exist on the host. If the parameters are omitted the permissions will default to root | Java
|`java_system_properties`| can be used to configure proxy setting for agents | DB, Machine
|`analytics_event_endpoint`   | Your Events Service URL   | Machine |
|`enable_analytics_agent`   | Indicate if analytics agent should be enabled in the Machine agent | Machine |
|`sim_enabled` | Enable server infrastructure monitoring | Machine
|`controller_global_analytics_account_name`| This is the global account name of the controller | Machine
