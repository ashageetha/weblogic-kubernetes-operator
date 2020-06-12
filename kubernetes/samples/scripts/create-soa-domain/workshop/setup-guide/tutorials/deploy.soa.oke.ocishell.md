# SOA on OKE with Oracle WebLogic Server Kubernetes Operator Tutorial #

### Deploy a SOA/OSB Domain  ###

#### Prepare the Kubernetes cluster to run SOA domains ####


Prepare the environment for Domain creation
    a. Create the domain namespace
    ```bash
    $ kubectl create namespace soans
    ```
    b. Configure the operator to manage domain namespace
    ```bash
    $ cd ~/weblogic-kubernetes-operator
    $ helm upgrade --reuse-values --namespace opns --set "domainNamespaces={soans}" --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
    ```

    Output should be something like below
    ```bash
    Release "weblogic-kubernetes-operator" has been upgraded. Happy Helming!
    NAME: weblogic-kubernetes-operator
    LAST DEPLOYED: Mon Jun  1 11:07:35 2020
    NAMESPACE: opns
    STATUS: deployed
    REVISION: 2
    TEST SUITE: None
    ```
    c. Create Kubernetes Secrets
        
        i. For Domain ( using
        create-weblogic-credentials.sh)  : Create a Kubernetes secret for the Domain (username : weblogic and password: Welcome1) in the same Kubernetes namespace as the domain (soans): 
    ```bash
        $ cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-credentials
        $ ./create-weblogic-credentials.sh -u weblogic -p Welcome1 -n soans -d soainfra -s soainfra-domain-credentials
    ```


        ii) For RCU ( using create-rcu-credentials.sh) : Create a Kubernetes secret for the RCU in the same Kubernetes namespace as the domain (soans) with below details:

            Schema user          : SOA1
            Schema password      : Oradoc_db1                   
            DB sys user password : Oradoc_db1
            Domain name          : soainfra
            Domain Namespace     : soans
            Secret name          : soainfra-rcu-credentials

    ```bash   
        $ cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-rcu-credentials
        $ ./create-rcu-credentials.sh -u SOA1 -p Oradoc_db1 -a sys -q Oradoc_db1 -d soainfra -n soans -s soainfra-rcu-credentials
    ```

Create a kubernetes PV and PVC  (Persistent Volume and Persistent Volume Claim). Here we will use the created NFS Server and mount Path at Step 5 for domain home.

    Update the create-pv-pvc-inputs.yaml.Make sure to update the "weblogicDomainStorageNFSServer: 10.0.1.6" with the NFS Server IP as per your Environment, rest are updated for you in the repository:
            $ cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-pv-pvc
            $ diff create-pv-pvc-inputs.yaml.orig create-pv-pvc-inputs.yaml
            8c8
            < baseName: weblogic-sample
            ---
            > baseName: domain
            13c13
            < domainUID:
            ---
            > domainUID: soainfra
            16c16
            < namespace: default
            ---
            > namespace: soans
            21c21
            < weblogicDomainStorageType: HOST_PATH
            ---
            > weblogicDomainStorageType: NFS
            25c25
            < #weblogicDomainStorageNFSServer: nfsServer
            ---
            > weblogicDomainStorageNFSServer: 10.0.1.6
            36c36
            < #weblogicDomainStoragePath: /scratch/k8s_dir
            ---
            > weblogicDomainStoragePath: /sharevolume

            Execute create-pv-pvc.sh script to create the PV and PVC configuration files.
            $ ./create-pv-pvc.sh -i create-pv-pvc-inputs.yaml -o output

            Output will be as below
            Input parameters being used
            export version="create-weblogic-sample-domain-pv-pvc-inputs-v1"
            export baseName="domain"
            export domainUID="soainfra"
            export namespace="soans"
            export weblogicDomainStorageType="NFS"
            export weblogicDomainStorageNFSServer="10.0.1.6"
            export weblogicDomainStoragePath="/sharevolume"
            export weblogicDomainStorageReclaimPolicy="Retain"
            export weblogicDomainStorageSize="10Gi"
             
            Generating output/pv-pvcs/soainfra-domain-pv.yaml
            Generating output/pv-pvcs/soainfra-domain-pvc.yaml
            The following files were generated:
              output/pv-pvcs/soainfra-domain-pv.yaml
              output/pv-pvcs/soainfra-domain-pvc.yaml
             
            Completed

            Create the PV and PVC using the configuration files created in previous step as shown below:
            $ kubectl create -f  output/pv-pvcs/soainfra-domain-pv.yaml
            $ kubectl create -f  output/pv-pvcs/soainfra-domain-pvc.yaml

Create the imagePullSecrets (in soans namespace) so that Kubernetes Deployment can pull the image automatically from OCIR with below command :
    Note: Create the imagePullSecret as per your environement
    $ kubectl create secret docker-registry image-secret -n soans --docker-server=phx.ocir.io  --docker-username=tenancy-foo/me@oracle.com --docker-password='bxnXvug9A2vvnI(;fczF'  --docker-email=me@oracle.com

     Where:
      OCI Region is phoenix         :   phx.ocir.io
      OCI Tenancy name              :   tenancy-foo
      Username and email address    :   me@oracle.com
      Auth Token Password           :   bxnXvug9A2vvnI(;fczF

Install and start the Database

    NOTE: This step is required only when standalone database was not already setup and the user wanted to use the database in a container.
    The Oracle Database Docker images are supported only for non-production use. For more details, see My Oracle Support note: Oracle Support for Database Running on Docker (Doc ID 2216342.1). For production usecase it is suggested to use a standalone db.
    Sample provides steps to create the database in a container.

    The database in a container can be created with a PV attached for persisting the data or without attaching the PV.
    In this demo we will be creating database in a container without PV attached.
    $ cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oracle-db-service
    $ ./start-db-service.sh -i  phx.ocir.io/tenancy-foo/oracle/database/enterprise:12.2.0.1-slim -s image-secret -n soans


    Output will be as below
    $ ./start-db-service.sh  -i phx.ocir.io/tenancy-foo/oracle/database/enterprise:12.2.0.1-slim -s image-secret -n soans
    Checking Status for NameSpace [soans]
    Skipping the NameSpace[soans] Creation ...
    NodePort[30011] ImagePullSecret[image-secret] Image[phx.ocir.io/tenancy-foo/oracle/database/enterprise:12.2.0.1-slim] NameSpace[soans]
    service/oracle-db created
    deployment.extensions/oracle-db created
    service/oracle-db unchanged
    deployment.extensions/oracle-db unchanged
    [oracle-db-78b7566996-vsg89] already initialized ..
    Checking Pod READY column for State [1/1]
    NAME                         READY   STATUS    RESTARTS   AGE
    oracle-db-78b7566996-vsg89   1/1     Running   0          16s
    NAME                         READY   STATUS    RESTARTS   AGE
    oracle-db-78b7566996-vsg89   1/1     Running   0          17s
    NAME        TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE
    oracle-db   LoadBalancer   10.96.6.36   <pending>     1521:30011/TCP   19s
    [1/30] Retrying for Oracle Database Availability...
    [2/30] Retrying for Oracle Database Availability...
    [3/30] Retrying for Oracle Database Availability...
    [4/30] Retrying for Oracle Database Availability...
    [5/30] Retrying for Oracle Database Availability...
    [6/30] Retrying for Oracle Database Availability...
    [7/30] Retrying for Oracle Database Availability...
    [8/30] Retrying for Oracle Database Availability...
    [9/30] Retrying for Oracle Database Availability...
    [10/30] Retrying for Oracle Database Availability...
    [11/30] Retrying for Oracle Database Availability...
    [12/30] Retrying for Oracle Database Availability...
    [13/30] Retrying for Oracle Database Availability...
    [14/30] Retrying for Oracle Database Availability...
    [15/30] Retrying for Oracle Database Availability...
    [16/30] Retrying for Oracle Database Availability...
    Done ! The database is ready for use .
    Oracle DB Service is RUNNING with NodePort [30011]
    Oracle DB Service URL [oracle-db.soans.svc.cluster.local:1521/devpdb.k8s]

    Once database is created successfully, you can use the database connection string, "oracle-db.soans.svc.cluster.local:1521/devpdb.k8s", as an rcuDatabaseURL parameter in the create-domain-inputs.yaml file.


Run the RCU to create SOA schemas

    To install SOA schemas, run the "create-rcu-schema.sh" script with below inputs:

    -s <RCU PREFIX>   Here: SOA1 
    -t <SOA domain type>  Here: soaessosb
    -p <ImagePullSecret name> Here: image-secret
    -d <DB connection string>  Here: oracle-db.soans.svc.cluster.local:1521/devpdb.k8s 
    -i <SOASuite image>   Here: phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4.0

    $ cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-rcu-schema
    $ ./create-rcu-schema.sh -s SOA1 -t soaessosb -d oracle-db.soans.svc.cluster.local:1521/devpdb.k8s  -p image-secret -i phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4.0  -n soans -q Oradoc_db1 -r Oradoc_db1


    Output will be as below
    ImagePullSecret[image-secret] Image[phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4.0] dburl[oracle-db.soans.svc.cluster.local:1521/devpdb.k8s] rcuType[soaessosb]
    pod/rcu created
    [rcu] already initialized ..
    Checking Pod READY column for State [1/1]
    Pod [rcu] Status is NotReady Iter [1/60]
    Pod [rcu] Status is NotReady Iter [2/60]
    Pod [rcu] Status is NotReady Iter [3/60]
    Pod [rcu] Status is NotReady Iter [4/60]
    Pod [rcu] Status is NotReady Iter [5/60]
    Pod [rcu] Status is NotReady Iter [6/60]
    Pod [rcu] Status is NotReady Iter [7/60]
    Pod [rcu] Status is NotReady Iter [8/60]
    Pod [rcu] Status is NotReady Iter [9/60]
    Pod [rcu] Status is NotReady Iter [10/60]
    Pod [rcu] Status is NotReady Iter [11/60]
    Pod [rcu] Status is NotReady Iter [12/60]
    Pod [rcu] Status is NotReady Iter [13/60]
    Pod [rcu] Status is NotReady Iter [14/60]
    Pod [rcu] Status is NotReady Iter [15/60]
    Pod [rcu] Status is NotReady Iter [16/60]
    Pod [rcu] Status is NotReady Iter [17/60]
    Pod [rcu] Status is NotReady Iter [18/60]
    Pod [rcu] Status is NotReady Iter [19/60]
    Pod [rcu] Status is NotReady Iter [20/60]
    Pod [rcu] Status is NotReady Iter [21/60]
    Pod [rcu] Status is NotReady Iter [22/60]
    Pod [rcu] Status is NotReady Iter [23/60]
    Pod [rcu] Status is NotReady Iter [24/60]
    Pod [rcu] Status is NotReady Iter [25/60]
    Pod [rcu] Status is NotReady Iter [26/60]
    Pod [rcu] Status is NotReady Iter [27/60]
    Pod [rcu] Status is NotReady Iter [28/60]
    Pod [rcu] Status is NotReady Iter [29/60]
    Pod [rcu] Status is NotReady Iter [30/60]
    Pod [rcu] Status is NotReady Iter [31/60]
    Pod [rcu] Status is NotReady Iter [32/60]
    Pod [rcu] Status is NotReady Iter [33/60]
    Pod [rcu] Status is NotReady Iter [34/60]
    Pod [rcu] Status is NotReady Iter [35/60]
    Pod [rcu] Status is NotReady Iter [36/60]
    Pod [rcu] Status is Ready Iter [37/60]
    NAME   READY   STATUS    RESTARTS   AGE
    rcu    1/1     Running   0          4m25s
    NAME   READY   STATUS    RESTARTS   AGE
    rcu    1/1     Running   0          4m32s
    CLASSPATH=/u01/jdk/lib/tools.jar:/u01/oracle/wlserver/modules/features/wlst.wls.classpath.jar:
     
    PATH=/u01/oracle/wlserver/server/bin:/u01/oracle/wlserver/../oracle_common/modules/thirdparty/org.apache.ant/1.10.5.0.0/apache-ant-1.10.5/bin:/u01/jdk/jre/bin:/u01/jdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/u01/jdk/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts:/u01/oracle/wlserver/../oracle_common/modules/org.apache.maven_3.2.5/bin
     
    Your environment has been set.
    Check if the DB Service is ready to accept request
    DB Connection String [oracle-db.soans.svc.cluster.local:1521/devpdb.k8s], schemaPrefix [SOA1] rcuType [soaessosb]
     
    **** Success!!! ****
     
    You can connect to the database in your app using:
     
      java.util.Properties props = new java.util.Properties();
      props.put("user", "sys as sysdba");
      props.put("password", "Oradoc_db1");
      java.sql.Driver d =
        Class.forName("oracle.jdbc.OracleDriver").newInstance();
      java.sql.Connection conn =
        Driver.connect("sys as sysdba", props);
    Creating RCU Schema for SOA Domain w/ESS [soaessosb] ...
    Extra RCU Schema Component Choosen[-component SOAINFRA -component ESS]
     
    Processing command line ....
    Repository Creation Utility - Checking Prerequisites
     
    Repository Creation Utility - Checking Prerequisites                                                                                                         Checking Component Prerequisites
    Repository Creation Utility - Creating Tablespaces                                                                                                           Validating and Creating Tablespaces
    Create tablespaces in the repository database
    Repository Creation Utility - Create
    Repository Create in progress.
            Percent Complete: 10
    Executing pre create operations
            Percent Complete: 25
            Percent Complete: 25
            Percent Complete: 26
            Percent Complete: 27
            Percent Complete: 28
            Percent Complete: 28
            Percent Complete: 29
            Percent Complete: 29
    Creating Common Infrastructure Services(STB)
            Percent Complete: 37
            Percent Complete: 37
            Percent Complete: 45
            Percent Complete: 45
            Percent Complete: 45
    Creating Audit Services Append(IAU_APPEND)
            Percent Complete: 52
            Percent Complete: 52
            Percent Complete: 60
            Percent Complete: 60
            Percent Complete: 60
    Creating Audit Services Viewer(IAU_VIEWER)
            Percent Complete: 67
            Percent Complete: 67
            Percent Complete: 68
            Percent Complete: 68
            Percent Complete: 69
            Percent Complete: 69
    Creating Metadata Services(MDS)
            Percent Complete: 77
            Percent Complete: 77
            Percent Complete: 77
            Percent Complete: 78
            Percent Complete: 78
            Percent Complete: 79
            Percent Complete: 79
            Percent Complete: 79
    Creating Weblogic Services(WLS)
            Percent Complete: 83
            Percent Complete: 83
            Percent Complete: 84
            Percent Complete: 85
            Percent Complete: 87
            Percent Complete: 89
            Percent Complete: 89
            Percent Complete: 89
    Creating User Messaging Service(UCSUMS)
            Percent Complete: 93
            Percent Complete: 93
            Percent Complete: 96
            Percent Complete: 96
            Percent Complete: 100
    Creating Audit Services(IAU)
    Creating Oracle Platform Security Services(OPSS)
    Creating SOA Infrastructure(SOAINFRA)
    Creating Oracle Enterprise Scheduler(ESS)
    Executing post create operations
     
    Repository Creation Utility: Create - Completion Summary
     
    Database details:
    -----------------------------
    Host Name                                    : oracle-db.soans.svc.cluster.local
    Port                                         : 1521
    Service Name                                 : DEVPDB.K8S
    Connected As                                 : sys
    Prefix for (prefixable) Schema Owners        : SOA1
    RCU Logfile                                  : /tmp/RCU2020-06-01_15-36_974422936/logs/rcu.log
     
    Component schemas created:
    -----------------------------
    Component                                    Status         Logfile
     
    Common Infrastructure Services               Success        /tmp/RCU2020-06-01_15-36_974422936/logs/stb.log
    Oracle Enterprise Scheduler                  Success        /tmp/RCU2020-06-01_15-36_974422936/logs/ess.log
    Oracle Platform Security Services            Success        /tmp/RCU2020-06-01_15-36_974422936/logs/opss.log
    SOA Infrastructure                           Success        /tmp/RCU2020-06-01_15-36_974422936/logs/soainfra.log
    User Messaging Service                       Success        /tmp/RCU2020-06-01_15-36_974422936/logs/ucsums.log
    Audit Services                               Success        /tmp/RCU2020-06-01_15-36_974422936/logs/iau.log
    Audit Services Append                        Success        /tmp/RCU2020-06-01_15-36_974422936/logs/iau_append.log
    Audit Services Viewer                        Success        /tmp/RCU2020-06-01_15-36_974422936/logs/iau_viewer.log
    Metadata Services                            Success        /tmp/RCU2020-06-01_15-36_974422936/logs/mds.log
    WebLogic Services                            Success        /tmp/RCU2020-06-01_15-36_974422936/logs/wls.log
     
    Repository Creation Utility - Create : Operation Completed
    [INFO] Modify the domain.input.yaml to use [oracle-db.soans.svc.cluster.local:1521/devpdb.k8s] as rcuDatabaseURL and [SOA1] as rcuSchemaPrefix

Create the domain

        The input "create-domain-inputs.yaml" is updated with below values.

        domainType: soaessosb
        initialManagedServerReplicas: 1
        image: phx.ocir.io/paasreleaseeng/nordeaworkshop/oracle/soasuite:12.2.1.4.0
        imagePullSecretName: image-secret
        rcuDatabaseURL: oracle-db.soans.svc.cluster.local:1521/devpdb.k8s


        $ cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-soa-domain/domain-home-on-pv/
        $ diff create-domain-inputs.yaml.orig create-domain-inputs.yaml
        25c25
        < domainType: soa
        ---
        > domainType: soaessosb
        42c42
        < initialManagedServerReplicas: 2
        ---
        > initialManagedServerReplicas: 1
        56c56
        < image: container-registry.oracle.com/middleware/soasuite:12.2.1.3
        ---
        > image: phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4
        64c64
        < #imagePullSecretName:
        ---
        > imagePullSecretName: image-secret
        169c169
        < rcuDatabaseURL: oracle-db.default.svc.cluster.local:1521/devpdb.k8s
        ---
        > rcuDatabaseURL: oracle-db.soans.svc.cluster.local:1521/devpdb.k8s

        The create-domain-job-template.yaml  is updated as per 'https://oracle.github.io/weblogic-kubernetes-operator/faq/oci-fss-pv/' to fix the PV ownership to oracle user:
        Updated create-domain-job-template.yaml  is already available in repository.

        Run the create-domain.sh script to create a domain
        $ cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-soa-domain/domain-home-on-pv
        $ ./create-domain.sh -i create-domain-inputs.yaml -o output

        Output is similar to as below
        Input parameters being used
        export version="create-weblogic-sample-domain-inputs-v1"
        export adminPort="7001"
        export adminServerName="AdminServer"
        export domainUID="soainfra"
        export domainType="soaessosb"
        export domainHome="/u01/oracle/user_projects/domains/soainfra"
        export serverStartPolicy="IF_NEEDED"
        export clusterName="soa_cluster"
        export configuredManagedServerCount="5"
        export initialManagedServerReplicas="2"
        export managedServerNameBase="soa_server"
        export managedServerPort="8001"
        export image="phx.ocir.io/paasreleaseeng/nordeaworkshop/oracle/soasuite:12.2.1.4.0"
        export imagePullPolicy="IfNotPresent"
        export imagePullSecretName="image-secret"
        export productionModeEnabled="true"
        export weblogicCredentialsSecretName="soainfra-domain-credentials"
        export includeServerOutInPodLog="true"
        export logHome="/u01/oracle/user_projects/domains/logs/soainfra"
        export t3ChannelPort="30012"
        export exposeAdminT3Channel="false"
        export adminNodePort="30701"
        export exposeAdminNodePort="false"
        export namespace="soans"
        javaOptions=-Dweblogic.StdoutDebugEnabled=false
        export persistentVolumeClaimName="soainfra-domain-pvc"
        export domainPVMountPath="/u01/oracle/user_projects"
        export createDomainScriptsMountPath="/u01/weblogic"
        export createDomainScriptName="create-domain-job.sh"
        export createDomainFilesDir="wlst"
        export rcuSchemaPrefix="SOA1"
        export rcuDatabaseURL="oracle-db.soans.svc.cluster.local:1521/devpdb.k8s"
        export rcuCredentialsSecret="soainfra-rcu-credentials"
         
        Generating output/weblogic-domains/soainfra/create-domain-job.yaml
        Generating output/weblogic-domains/soainfra/delete-domain-job.yaml
        Generating output/weblogic-domains/soainfra/domain.yaml
        Checking to see if the secret soainfra-domain-credentials exists in namespace soans
        configmap/soainfra-create-soa-infra-domain-job-cm created
        Checking the configmap soainfra-create-soa-infra-domain-job-cm was created
        configmap/soainfra-create-soa-infra-domain-job-cm labeled
        Checking if object type job with name soainfra-create-soa-infra-domain-job exists
        No resources found.
        domainType is: soaessosb
        Creating the domain by creating the job output/weblogic-domains/soainfra/create-domain-job.yaml
        job.batch/soainfra-create-soa-infra-domain-job created
        Waiting for the job to complete...
        status on iteration 1 of 20
        pod soainfra-create-soa-infra-domain-job-9n89n status is Running
        status on iteration 2 of 20
        pod soainfra-create-soa-infra-domain-job-9n89n status is Running
        status on iteration 3 of 20
        pod soainfra-create-soa-infra-domain-job-9n89n status is Running
        status on iteration 4 of 20
        pod soainfra-create-soa-infra-domain-job-9n89n status is Running
        status on iteration 5 of 20
        pod soainfra-create-soa-infra-domain-job-9n89n status is Running
        status on iteration 6 of 20
        pod soainfra-create-soa-infra-domain-job-9n89n status is Running
        status on iteration 7 of 20
        pod soainfra-create-soa-infra-domain-job-9n89n status is Running
        status on iteration 8 of 20
        pod soainfra-create-soa-infra-domain-job-9n89n status is Running
        status on iteration 9 of 20
        pod soainfra-create-soa-infra-domain-job-9n89n status is Completed
         
        Domain soainfra was created and will be started by the WebLogic Kubernetes Operator
         
        The following files were generated:
          output/weblogic-domains/soainfra/create-domain-inputs.yaml
          output/weblogic-domains/soainfra/create-domain-job.yaml
          output/weblogic-domains/soainfra/domain.yaml
         
        Completed

        Once the create-domain.sh is success, it generates the "output/weblogic-domains/soainfra/domain.yaml" using which you can create the Kubernetes resource domain which starts the domain and servers as shown below:

            Create Kubernetes Domain object
            $ kubectl create -f output/weblogic-domains/soainfra/domain.yaml

            Verify that Kubernetes Domain Object (name: soainfra)  is created:
            $ kubectl get domain -n soans
            NAME       AGE
            soainfra   28s

            Once you create the domain, "introspect pod" will get created. This inspects the Domain Home and then start the "soainfra-adminserver" pod.  Once the "soainfra-adminserver" pod comes up successfully, then the managed server pods are started in parallel.
            Watch the "soans" namespace for the status of domain creation with below command
            $ kubectl get pods -n soans -w

            Verify that SOA Domain server pods and services are created and in READY state:
            $ kubectl get all -n soans

            Output to similar to below
            $  kubectl get all -n soans
            NAME                                             READY   STATUS      RESTARTS   AGE
            pod/oracle-db-78b7566996-vsg89                   1/1     Running     0          27h
            pod/rcu                                          1/1     Running     0          26h
            pod/soainfra-adminserver                         1/1     Running     0          23m
            pod/soainfra-create-soa-infra-domain-job-9n89n   0/1     Completed   0          23h
            pod/soainfra-osb-server1                         1/1     Running     0          19m
            pod/soainfra-soa-server1                         1/1     Running     0          19m
             
             
            NAME                                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE
            service/oracle-db                      LoadBalancer   10.96.6.36      129.146.236.86   1521:30011/TCP   27h
            service/soainfra-adminserver           ClusterIP      None            <none>           7001/TCP         23h
            service/soainfra-cluster-osb-cluster   ClusterIP      10.96.237.199   <none>           9001/TCP         23h
            service/soainfra-cluster-soa-cluster   ClusterIP      10.96.166.96    <none>           8001/TCP         23h
            service/soainfra-osb-server1           ClusterIP      None            <none>           9001/TCP         23h
            service/soainfra-osb-server2           ClusterIP      10.96.174.34    <none>           9001/TCP         19m
            service/soainfra-osb-server3           ClusterIP      10.96.250.216   <none>           9001/TCP         19m
            service/soainfra-osb-server4           ClusterIP      10.96.253.13    <none>           9001/TCP         19m
            service/soainfra-osb-server5           ClusterIP      10.96.72.25     <none>           9001/TCP         19m
            service/soainfra-soa-server1           ClusterIP      None            <none>           8001/TCP         23h
            service/soainfra-soa-server2           ClusterIP      10.96.128.229   <none>           8001/TCP         19m
            service/soainfra-soa-server3           ClusterIP      10.96.251.159   <none>           8001/TCP         19m
            service/soainfra-soa-server4           ClusterIP      10.96.149.141   <none>           8001/TCP         19m
            service/soainfra-soa-server5           ClusterIP      10.96.49.11     <none>           8001/TCP         19m
             
             
            NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
            deployment.apps/oracle-db   1/1     1            1           27h
             
            NAME                                   DESIRED   CURRENT   READY   AGE
            replicaset.apps/oracle-db-78b7566996   1         1         1       27h
             
             
             
            NAME                                             COMPLETIONS   DURATION   AGE
            job.batch/soainfra-create-soa-infra-domain-job   1/1           4m51s      23h


