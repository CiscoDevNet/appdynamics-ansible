# AppDynamics role to instrument Apache tomcat

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
        # use java role variables in the following instrumentation tasks when public: yes
        public: yes
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
        # use java role variables in the following instrumentation tasks when public: yes
        public: yes
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
