# AppDynamics role to install the Java agent

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

