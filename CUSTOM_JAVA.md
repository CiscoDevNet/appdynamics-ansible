
In order to instrument custom java app, that is started by script

1. Use instrument_tomcat role as blueprint

For example, if your app is called BDR
mkdir -p roles
cp -R ~/.ansible/collections/ansible_collections/appdynamics/agents/roles/instrument_tomcat ./roles/instrument_bdr