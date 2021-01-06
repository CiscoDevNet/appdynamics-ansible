# AppDynamics role to install the DotNet Agent

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
        # Your controller details 
        controller_account_access_key: "b0248ceb-c954-4a37-97b5-207e90418cb4" # Please add this to your Vault
        controller_global_analytics_account_name: "customer1_e2f90621-ab21-4bf4-908c-872d213c7f64" # Please add this to your Vault
        controller_host_name: "ansible-20100nosshcont-bum4wzwa.appd-cx.com" # Your AppDynamics controller
        controller_account_name: "customer1" # Please add this to your Vault
        enable_ssl: "false"
        controller_port: "8090"
        enable_proxy: "false"  #use quotes please
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
