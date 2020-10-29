# appd

This role installs and configures the AppDynamics DB agent on Linux

## Example 

````

---
- hosts: linux
  become: true
  tasks:
    - include_role:
        name: db-agent
      vars:
        dir: '.'
        db_agent_name: 'ACME' 
        application_environment: 'dev'
        aws_access_key: xxxxxx #read from vault or environment variable 
        aws_secret_key: xxxxxx #read from vault or environment variable 


````

## Nexus uploads

### Linux Machine Agent (download from AppDynamics)

- Appd Download: Machine Agent Bundle - 64-bit linux (zip)  

- repository: software
- group: com.appdynamics
- artifact: machine-agent-linux
- packaging: zip
- version: 1.0.0 (using 1st 3 numbers of archive)

### Linux Application (Java) Agent (download from AppDynamics)

- Appd Download: Java Agent - Sun and JRockit JVM (zip) 

- repository: software
- group: com.appdynamics
- artifact: application-agent-linux
- packaging: zip
- version: 1.0.0.0
