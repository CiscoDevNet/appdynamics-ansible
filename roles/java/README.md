# AppDynamics role to install the Java agent

This role features:

- java-agent installation for Windows/Linux
- instrumentation of applications such as tomcat and jboss(wildfly). Multiple application instances such as Jboss domains can be instrumented with the agent.
- automatic applications restart (if systemd service is present)
- java agent start verification

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

Example 2: Install java-agent and instrument one or more applications.

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
        
        # List applications to instrument with java agent. 'jboss' and 'tomcat' are currently supported (Linux only). Remove 'apps' if you want to install java agent only.
        application_details_in_config: no
        apps:
          - type: jboss
            application_name: MyApp
            tier_name: Jboss
            jboss_config: /opt/wildfly/bin/standalone.sh
            user: wildfly
            service: wildfly
            restart_app: yes
          - type: tomcat
            application_name: MyApp2
            tier_name: Tomcat
            tomcat_config: /usr/share/tomcat9/bin/setenv.sh
            user: tomcat
            service: tomcat9
            restart_app: yes
```

[![asciicast](https://asciinema.org/a/394098.svg)](https://asciinema.org/a/394098)

Example 3: To make sure all instrumented applications can have access to java-agent logs directory, this role creates `appdynamics` functional user/group to own java-agent dir and then assigns applications PID users to `appdynamics` group.
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
        # List applications to instrument with java agent. 'jboss' and 'tomcat' are currently supported (Linux only). Remove 'apps' if you want to install java agent only.
        application_details_in_config: no
        apps:
          - type: tomcat
            application_name: MyApp2
            tier_name: Tomcat
            tomcat_config: /usr/share/tomcat9/bin/setenv.sh
            user: tomcat
            service: tomcat9
            restart_app: yes
```


Java agent specific variables:

|Variable<img width="200"/>     | Description | Required | Default |
|--|--|--|--|
| `application_details_in_config` | If default application_name, tier_name, node_name should be placed in controller-info.xml file. Set to 'no' if multiple apps are instrumented. | N | yes
|`apps` | List of applications to be instrumented with the java agent. Supported types are `jboss`, `tomcat` | N
|`apps[*].type` | Type of application to instrument. Supported types are `jboss`, `tomcat` | Y | |
|`apps[*].application_name` | Application name. Overrides default application_name for this host | N
|`apps[*].tier_name` | Tier name. Overrides default tier_name for this host | N
|`apps[*].node_name` | Node name. Overrides default node_name for this host | N
|`apps[*].user` | User that runs this application. It must be provided, so write permissions are given to the java-agent logs directory | Y | `tomcat`: tomcat, `jboss`: wildfly
|`apps[*].service` | Systemd service that should be restated if `restart_app` is set to 'yes' | N | `jboss`: wildfly
|`apps[*].add_service_override` | If enabled, adds systemd override file to explicitly allow write permissions to appdynamics java-agent dir. Required for tomcat9 installed on ubuntu20.04 | N | `all`: no, `tomcat`: yes
|`apps[*].restart_app` | Set to 'yes' to automatically restart instrumented service | N | no 
|`apps[*].backup` | Whether original config file should be backed up before any changes | N | no
|`apps[*].tomcat_config` | Tomcat config to instrument. Choose which tomcat config file to modify. You should set full path to setenv.sh file, like <CATALINA_HOME>/bin/setenv.sh. Note that if Tomcat is installed with yum on RHEL distributions this file is not invoked by startup script. In that case, it can be set to `/etc/tomcat/conf.d/appdynamics.conf` instead. | Y |
|`apps[*].jboss_config` | Jboss/Wildfly config to instrument. Provide a path to jboss standalone.sh | Y | /opt/wildfly/bin/standalone.sh
