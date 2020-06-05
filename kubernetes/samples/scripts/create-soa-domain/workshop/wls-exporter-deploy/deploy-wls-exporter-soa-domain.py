connect('weblogic','Welcome1','t3://soainfra-adminserver:7001')
deploy('wls-exporter-admin','/u01/oracle/wls-exporter-deploy/wls-exporter-admin.war',upload="true",remote="true")
deploy('wls-exporter-soa','/u01/oracle/wls-exporter-deploy/wls-exporter-soa.war','soa_cluster',upload="true",remote="true")
deploy('wls-exporter-osb','/u01/oracle/wls-exporter-deploy/wls-exporter-osb.war','osb_cluster',upload="true",remote="true")

