

# AppDynamics Ansible Collection

The AppDynamics Ansible Collection installs and configures AppDynamics agents and configurations. All supported agents are downloaded from the download portal unto the Ansible control node automatically –– this makes it easy to acquire and upgrade agents declaratively.

Refer to the [role variables](#Role-Variables) below for a description of available deployment options.

We built this AppDynamics Ansible collection to support (immutable) infrastructure as code deployment methodology; this means that the collection will NOT preserve any manual configuration changes on the target servers. In other words, the collection will overwrite any local or pre-existing configuration with the variables that are defined in the playbook.  Therefore, we strongly recommend that you convert any custom agent configuration (this collection does not support) into an ansible role to ensure consistency of deployments and configurations across your estate.

## Demo

<i> Pro Tip: Right-Click the GIF and "Open in new Tab" or view on <a href="https://terminalizer.com/view/405023a64449">terminalizer</a> </i>

![DEMO](https://github.com/Appdynamics/appdynamics-ansible/blob/master/docs/ansible.gif?raw=true)

## Requirements

- Requires Ansible >=2.8.0
- Supports most Debian and RHEL-based Linux distributions, and Windows.
- Windows OS requires >= Powershell 5.0
- Network/firewall access to download AppDynamics agents from `https://download-files.appdynamics.com` and `https://download.appdynamics.com` on the Ansible control node  
 -  <a href="https://stedolan.github.io/jq/"> `jq` </a> is required on the Ansible control node. It is recommended that you install it manually (since it requires `sudo` access and it is a one time task), or run the `install_jq.yaml` playbook in the `playbook` folder. For example: `ansible-playbook install_jq.yaml --ask-become-pass -e 'ansible_python_interpreter=/usr/bin/python'`
 - `lxml` is required if you need to enable enhanced agent logging (e.g DEBUG, TRACE, etc). We recommend that you install it manaually on the Ansible control node using `pip3 install lxml`, or run the `install_lxml.yaml` playbook in the `playbook` folder.

## Supported Agents

The agent binaries and the installation process for the Machine and DB agent depend on the OS type –– Windows or Linux. This AppDynamics collection abstracts the OS differences so you should only have to provide `agent_type`, without necessarily specifying your OS type.  

| Agent type <img width="180"/> | Description |
|--|--|
|`sun-java`   or     `java`   | Agent to monitor Java applications running on JRE version 1.7 and less |
|`sun-java8`   or     `java8`   | Agent to monitor Java applications running on JRE version 1.8 and above |
|`ibm-java` | Agent to monitor Java applications running on IBM JRE |
|`dotnet` | Agent to monitor Full .Net Framework application on Windows |
|`machine` | 64 Bit Machine agent ZIP bundle with JRE. Windows and Linux |
|`db` | Agent to monitor Databases. Windows and Linux|
|`dotnetcore` | Agent to Monitor .NetCore applications on Linux|
## Installation

Install the <a href="https://galaxy.ansible.com/appdynamics"> AppDynamics Collection </a> from Ansible Galaxy on your Ansible control node:

```shell
ansible-galaxy collection install appdynamics.agents
```

## Playbooks

Example playbooks for each agent type is provided in the collections's `playbooks` folder.  
You should either reference the example playbooks in the collection installation folder, or access the examples in the GitHub <a href="https://github.com/Appdynamics/appdynamics-ansible/tree/master/playbooks"> repository </a>.

The `var/playbooks/controller.yaml` file is meant to contain constant variables such as `enable_ssl`, `controller_port`, etc. You may either include `var/playbooks/controller.yaml` in the playbook as shown in the java example below, or overwrite the variables in the playbooks - whatever works best for you.

### Java agent

This role features:

- java-agent installation for Windows/Linux

Example 1: Install java-agent without any apps instrumentation.

```yml
---
- hosts: all
  tasks:
    - name: Include variables for the controller settings
      include_vars: vars/controller.yaml
    - include_role:
        name: appdynamics.agents.java
      vars:
        agent_version: 21.1.0
        agent_type: java8
        application_name: "IoT_API" # agent default application
        tier_name: "java_tier" # agent default tier
```

Java agent specific variables:

|Variable<img width="200"/>     | Description | Required | Default |
|--|--|--|--|


### AppDynamics role to instrument Jboss/Wildfly

This role features:

- java-agent installation for Linux
- instrumentation of Jboss/Wildfly
- automatic applications restart (if systemd service is present)
- java agent start verification

Example 1: Install java-agent and instrument one or more applications.

```yml
---
- hosts: all
  tasks:
    - name: Include variables for the controller settings
      include_vars: vars/controller.yaml
    - include_role:
        name: appdynamics.agents.java
      vars:
        agent_version: 21.1.0
        agent_type: java8
        # use java role variables in the following instrumentation tasks when public: yes
        public: yes

    - include_role:
        name: appdynamics.agents.instrument_jboss
      vars:
        # instrument jboss:
        application_name: "IoT_API2"
        tier_name: "Jboss"
        jboss_service: wildfly
        app_user: wildfly
        restart_app: yes
        jboss_config: /opt/wildfly/bin/standalone.sh
```

Example 2: To make sure all instrumented applications can have access to java-agent logs directory, this role creates `appdynamics` functional user/group to own java-agent dir and then assigns applications PID users to `appdynamics` group.
In some cases, when application PID user is not local on linux host (i.e. from external source) it cannot be added to the `appdynamics` group. In such case you can let application user to own java-agent directory instead.

```yml
---
- hosts: all
  tasks:
    - name: Include variables for the controller settings
      include_vars: vars/controller.yaml
    - include_role:
        name: appdynamics.agents.java
      vars:
        agent_version: 21.1.0
        agent_type: java8
        # single app mode: Can skip appdynamics user creation and own java-agent directory by app user (wildfly in this case)
        create_appdynamics_user: no
        agent_dir_permission:
          user:  wildfly
          group: wildfly
    - include_role:
        name: appdynamics.agents.instrument_jboss
      vars:
        # instrument jboss:
        application_name: "IoT_API2"
        tier_name: "Jboss"
        jboss_service: wildfly
        app_user: wildfly
        restart_app: yes
        jboss_config: /opt/wildfly/bin/standalone.sh
```

instrument_jboss specific variables:

|Variable<img width="200"/>     | Description | Required | Default |
|--|--|--|--|
|`app_user` | User that runs this application. It must be provided, so write permissions are given to the java-agent logs directory | Y | jboss
|`jboss_service` | Systemd service that should be restarted if `restart_app` is set to 'yes' | N | 
|`restart_app` | Set to 'yes' to automatically restart instrumented service | N | no 
|`backup` | Whether original config file should be backed up before any changes | N | False
|`jboss_config` | Jboss/Wildfly config to instrument. Provide a path to jboss standalone.sh | Y | /opt/wildfly/bin/standalone.sh

### AppDynamics role to instrument Apache tomcat

This role features:

- java-agent installation for Linux
- instrumentation of Apache Tomcat
- automatic applications restart (if systemd service is present)
- java agent start verification


Example 1: Install java-agent and instrument one or more applications.

```yml
---
- hosts: all
  tasks:
    - name: Include variables for the controller settings
      include_vars: vars/controller.yaml
    - include_role:
        name: appdynamics.agents.java
      vars:
        agent_version: 21.1.0
        agent_type: java8
    - include_role:
        name: appdynamics.agents.instrument_tomcat
      vars:
      # instrument tomcat:
        tomcat_service: tomcat9
        application_name: "IoT_API22"
        tier_name: "Tomcat"
        app_user: tomcat
        restart_app: yes
        tomcat_config: /usr/share/tomcat9/bin/setenv.sh
```

Example 2: To make sure all instrumented applications can have access to java-agent logs directory, this role creates `appdynamics` functional user/group to own java-agent dir and then assigns applications PID users to `appdynamics` group.
In some cases, when application PID user is not local on linux host (i.e. from external source) it cannot be added to the `appdynamics` group. In such case you can let application user to own java-agent directory instead.

```yml
---
- hosts: all
  tasks:
    - name: Include variables for the controller settings
      include_vars: vars/controller.yaml
    - include_role:
        name: appdynamics.agents.java
      vars:
        agent_version: 21.1.0
        agent_type: java8
        # single app mode: Can skip appdynamics user creation and own java-agent directory by app user (tomcat in this case)
        create_appdynamics_user: no
        agent_dir_permission:
          user:  tomcat
          group: tomcat

    - include_role:
        name: appdynamics.agents.instrument_tomcat
      vars:
        # instrument tomcat:
        tomcat_service: tomcat9
        application_name: "IoT_API22"
        tier_name: "Tomcat"
        app_user: tomcat
        restart_app: yes
        tomcat_config: /usr/share/tomcat9/bin/setenv.sh
```


instrument_tomcat specific variables:

|Variable<img width="200"/>     | Description | Required | Default |
|--|--|--|--|
|`app_user` | User that runs this application. It must be provided, so write permissions are given to the java-agent logs directory | Y | tomcat
|`tomcat_service` | Systemd service that should be restated if `restart_app` is set to 'yes' | N | 
|`add_service_override` | If enabled, adds systemd override file to explicitly allow write permissions to appdynamics java-agent dir. Required for tomcat9 installed on ubuntu20.04 | N | yes
|`restart_app` | Set to 'yes' to automatically restart instrumented service | N | no 
|`backup` | Whether original config file should be backed up before any changes | N | no
|`tomcat_config` | Tomcat config to instrument. Choose which tomcat config file to modify. You should set full path to setenv.sh file, like <CATALINA_HOME>/bin/setenv.sh. Note that if Tomcat is installed with yum on RHEL distributions this file is not invoked by startup script. In that case, it can be set to `/etc/tomcat/conf.d/appdynamics.conf` instead. | Y |

### .NET agent

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
        standalone_applications:
          - tier: login
            executable: login.exe
          - tier: tmw
            executable: tmw.exe
            command-line: "-x"
          - tier: mso
            executable: mso.exe
```

.NET agent specific variables:

|Variable<img width="200"/>     | Description
|--|--|
|`monitor_all_IIS_apps`| Enable automatic instrumentation of all IIS applications
|`runtime_reinstrumentation` | Runtime re-instrumentation works for .NET Framework 4.5.2 and greater. Note: Make sure you test this first in a non-production environment
|`dotnet_machine_agent` | YAML map that describes dotnet machine agent settings. See [roles/dotnet/defaults/main.yml](roles/dotnet/defaults/main.yml) for the example
|`standalone_applications` | List of standalone services to be instrumented with the .NET agent. See [roles/dotnet/defaults/main.yml](roles/dotnet/defaults/main.yml) for the example
|`logFileFolderAccessPermissions` | The list of users who require write access to log directory of the agent (i.e. user who runs IIS). See [roles/dotnet/defaults/main.yml](roles/dotnet/defaults/main.yml) for the example


### DB agent

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

DB agent specific variables:

|Variable<img width="200"/>     | Description |
|--|--|
|`db_agent_name` | Name assigned to the agent, typically used to allow one Database Agent  to act as a backup to another one
|`install_jre`| Set this parameter to false if the JRE should not be installed together with the DB agent. <br><br>**Note:** to install java on windows, you need to run the <i>install-roles.yml</i> playbook first, which adds a galaxy role (lean_delivery.java) to you local playbook folder

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
### Logger
The logger role allows you to change the agent log level for already deployed agents (either one agent type at a time or multiple types, depending on the value of the `agents_to_set_loggers_for` list.

The `init_and_validate_agent_variables` should be  **false** when using the logger role after the agents are already deployed, to skip unnecessary common role processing.

Machine agent specific variables:

|Variable<img width="200"/>     | Description 
|--|--|
|`java_system_properties`| can be used to configure proxy setting for agents 
|`analytics_event_endpoint`   | Your Events Service URL  
|`enable_analytics_agent`   | Indicate if analytics agent should be enabled in the Machine agent 
|`sim_enabled` | Enable server infrastructure monitoring
|`controller_global_analytics`<br/>`_account_name`| This is the global account name of the controller

### Logger

The logger role allows you to change the agent log level for already deployed agents (either one agent type at a time or multiple types, depending on the value of the `agents_to_set_loggers_for` list.

The `init_and_validate_agent_variables` should be  **false** when using the logger role after the agents are already deployed, to skip unnecessary common role processing.

```yaml
- hosts: all
  tasks:
      - include_role:
          name: appdynamics.agents.logger
        vars:
          init_and_validate_agent_variables: false # skip agent type variable init and validation
          agents_to_set_loggers_for: ['db', 'java', 'machine']
          agent_log_level: "info"
          agent_loggers: ['com.appdynamics', 'com', 'com.singularity', 'com.singularity.BusinessTransactions', 'com.singularity.ee.agent.dbagent.collector.server.connection.wmi.NativeClient']

```

## Common role variables

Check `Agent Type/Roles` for specific variable support.

|Variable<img width="200"/>     | Description | Agent Type/Roles |
|--|--|--|
|`agent_type`   | AppDynamics agent type.  java, machine, etc  | All |
|`agent_version`  | AppDynamics agent version. AppDynamics uses calendar versioning. For example, if a Java agent is released in November of 2020, its version will begin with 20.11.0. When the Java agent team releases again in the month of November, the new agent will be 20.11.1  | All |
|`application_name`   | The AppDynamics business application name, this variable is compulsory for all the  `dotnet`, `java` and `dotnetcore` roles  | All |
|`tier_name`   | The AppDynamics tier name, this variable is compulsory for all the `dotnet`, `java` and `dotnetcore` roles  | All |
|`node_name`   | The AppDynamics node name for `dotnet`, `java` and `dotnetcore` roles  | All |
|`controller_host_name`   | The  controller host name, do not include `http(s)` | All |
|`controller_account_name`   | Controller account name   | All |
|`controller_account_access_key` | Account or license rule access key. This should ideally be placed into your vault | All |
|`controller_account_name` |  Account name | All |
|`controller_port`   | The controller port   | All |
|`enable_ssl`   | Indicate if SSL is enabled in the controller or not | All |
|`agent_log_level` | set the log level for the agent. valid options are : **info, trace, debug, warn, error, fatal, all** and **off**. This setting is applied to all the loggers named in the **`agent_loggers`** list. <br><br> **Note:** The log level, when used with the .NET agent, only applies to loggers that write to the agent log-file (as opposed to other files in the log directory)  | Machine, DB, Java, .NET and Logger
|`agent_loggers` | List of loggers to set the log level on. The logger names vary from agent to agent. The default is set to ['*', 'com.singularity','com']. Update this variable with loggers specific to the target agent as required (refer to the log4j files in the <agent-home>/conf/logging directory for more info). | Machine, DB, Java, .NET, Logger
|`init_and_validate`<br/>`_agent_variables`| This variable controls whether the Common role initialisation (which sets download urls and controller parameters) needs to be run. When using the logger role in isolations (that is not as part of agent installation) the value should be **false**|Machine, DB, Java, .NET, Logger
|`agents_to_set_loggers_for`| List of agents to apply the log-level changes to. for example to set the log level of all deployed agents to say "info". initialise the variable to **['db', 'java', 'machine', 'dotnet']**. In contrast, to affect only the java agent, remove the unwanted entries from the list. **Note**: This variable should not be set when using the logger role as part of agent deployments. The `agent_type` variable will be used to determine how the log-level needs to be adjusted during the installation |Machine, DB, Java, .NET, Logger
| `analytics_agent_host` `analytics_agent_port` | Defines where the application agents sends its analytics events. The default is **localhost:9090** | .NET-Core
| `enable_proxy` | Set to "true" to apply agent proxy settings to the agent config. When set, the `proxy_host` and `proxy_port` variables also need to be assigned | .NET and .NET-Core, Java
|`proxy_host`<br/> `proxy_port`| Host name/IP address and port number of the proxy to route agent data through. |.NET and .NET-Core, Java
| `enable_proxy_authentication` | Set to "true" to apply proxy authentication details using `proxy_user` and `proxy_password` parameters. | .NET&#8209;Core 
| `create_appdynamics_user` | Whether to create AppDynamics functional user on linux if missing | Java, DB, Machine |
| `appdynamics_user` | Appdynamics functional user name, default is 'appdynamics' | Java, DB, Machine |
|`agent_dir_permission.user` `agent_dir_permission.group` | user and group file permissions to assign to the java-agent/.net-core agent on linux. The user and group selected must already exist on the host if `create_appdynamics_user` is set to 'no'. For .NET-core, If the parameters are omitted the permissions will default to root |  .NET-Core, Java

## Contributing

Here are a few ways you can pitch in:

- Report bugs or issues.
- Fix bugs and submit pull requests.
- Write, clarify or fix documentation.
- Refactor code.
