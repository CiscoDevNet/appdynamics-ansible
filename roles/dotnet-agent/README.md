# win_appd

This role installs and configures the AppDynamics machine agent and application agents for Windows application servers

## Parameters

### application_environment
Theenvironment that the role is being deployed to

`required: yes`

### application_name
The application name that will appear in AppDynamics Controller.

`required: yes`

### tier_name
The tier name of the application

`required: yes`

### services
A list of the service executable names to monitor. These will appear as separate processes in the AppDynamics Controller  

`required: yes`

## Notes

When upgrading the versions, you will need to upgrade the `product_id` for the msi installer.  https://stackoverflow.com/questions/29937568/how-can-i-find-the-product-guid-of-an-installed-msi-setup

## Nexus uploads

### Windows Machine Agent (download from AppDynamics)

- Appd Download: Machine Agent Bundle - 64-bit windows (zip)  

- repository: software
- group: com.appdynamics
- artifact: machine-agent-windows
- packaging: zip
- version: 1.0.0.0

### Windows Application Agent (download from AppDynamics)

- Appd Download: .NET Agent - 64-bit windows (msi)

- repository: software
- group: com.appdynamics
- artifact: application-agent-windows
- packaging: msi
- version: 1.0.0.0

### Windows Netviz Agent (download from AppDynamics)

- Appd Download: appd-netviz-agent - 64-bit windows (zip)

- repository: software
- group: com.appdynamics
- artifact: netviz-agent-windows
- packaging: zip
- version: 1.0.0.0

