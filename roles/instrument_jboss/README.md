# AppDynamics role to instrument Jboss/Wildfly

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
        # use java role variables in the following instrumentation tasks when public: yes
        public: yes
      vars:
        agent_version: 21.1.0
        agent_type: java8

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
        # use java role variables in the following instrumentation tasks when public: yes
        public: yes
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
