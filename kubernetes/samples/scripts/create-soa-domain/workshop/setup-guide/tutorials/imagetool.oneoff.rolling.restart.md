# Create Oracle Container Engine for Kubernetes (OKE) on Oracle Cloud Infrastructure (OCI) #
 
Update SOA image with one-off patch

Prerequisites

    - Docker client and daemon on the build machine, with minimum Docker version 18.03.1.ce.
    - JAVA_HOME needs to configured.
    - Bash version 4.0 or later, to enable the <tab> command complete feature.

Setup

   - Download imagetool.zip from the image tool github release page.
   - Unzip the release ZIP file to a desired location.
   ```bash
   $ wget https://github.com/oracle/weblogic-image-tool/releases/download/release-1.8.5/imagetool.zip
   $ unzip imagetool.zip
   ```
   
   Output will be as below
   ```bash
   Archive:  imagetool.zip
   creating: imagetool/
   creating: imagetool/lib/
  inflating: imagetool/lib/fluent-hc-4.5.6.jar
  inflating: imagetool/lib/httpclient-4.5.6.jar
  inflating: imagetool/lib/httpcore-4.4.10.jar
  inflating: imagetool/lib/commons-logging-1.2.jar
  inflating: imagetool/lib/commons-codec-1.10.jar
  inflating: imagetool/lib/httpmime-4.5.6.jar
  inflating: imagetool/lib/picocli-4.1.4.jar
  inflating: imagetool/lib/json-20180813.jar
  inflating: imagetool/lib/compiler-0.9.6.jar
   creating: imagetool/bin/
  inflating: imagetool/bin/setup.sh
  inflating: imagetool/bin/logging.properties
  inflating: imagetool/bin/imagetool.cmd
  inflating: imagetool/bin/imagetool.sh
  inflating: imagetool/LICENSE.txt
  inflating: imagetool/lib/imagetool_completion.sh
  inflating: imagetool/lib/imagetool.jar
  ```
  
  Perform below step
  ```bash
  $ cd imagetool/bin
  $ source setup.sh
  ```
  
Download the required one-off patch (30761841) and place it in "~/imagetool/patches/.
Imagetool requires opatch (Patch 28186730) and hence download and place it in "~/imagetool/patches/".

```bash
$ ls ~/imagetool/patches/
p28186730_139422_Generic.zip  p30761841_122140_Generic.zip
```

Add the required patch to the Imagetool cache
```bash
$ imagetool cache addEntry --key=30761841_12.2.1.4.0 --value ~/imagetool/patches/p30761841_122140_Generic.zip
$ imagetool cache addEntry --key=28186730_12.2.1.4.0 --value ~/imagetool/patches/p28186730_139422_Generic.zip
```

Output will be similar to below
```
[INFO   ] Added entry 30761841_12.2.1.4.0=~/imagetool/patches/p30761841_122140_Generic.zip
[INFO   ] Added entry 28186730_12.2.1.4.0=~/imagetool/patches/p28186730_139422_Generic.zip
```


Update the SOA 12.2.1.4 Docker image with one-off patch using the below command:
```bash
$ imagetool update --fromImage phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4.0  --tag=phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4.0-30761841  --opatchBugNumber 28186730 --patches 30761841
```

Output will be similar to below
```bash
$ imagetool update --fromImage phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4.0  --tag=phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4.0-30761841  --opatchBugNumber 28186730 --patches 30761841
[INFO   ] Image Tool build ID: 5247b3f9-9cfd-484c-8fbd-7ab6d7a7cea4
[INFO   ] Temporary directory used for docker build context: /home/opc/wlsimgbuilder_temp3432462920908055384
[INFO   ] Using patch 28186730_12.2.1.4.0 from cache: /home/opc/imagetool/patches/p28186730_139422_Generic.zip
[WARNING] skipping patch conflict check, no support credentials provided
[WARNING] No credentials provided, skipping validation of patches
[INFO   ] Using patch 30761841_12.2.1.4.0 from cache: /home/opc/imagetool/patches/p30761841_122140_Generic.zip
[INFO   ] docker cmd = docker build --force-rm=true --no-cache --tag phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4.0-30761841 /home/opc/wlsimgbuilder_temp3432462920908055384
Sending build context to Docker daemon  53.47MB

Step 1/7 : FROM phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4.0 as FINAL_BUILD
 ---> 445b649a3459
Step 2/7 : USER root
 ---> Running in d84082f64be1
Removing intermediate container d84082f64be1
 ---> c05ad4122db6
Step 3/7 : ENV OPATCH_NO_FUSER=true
 ---> Running in 7db7b5590b25
Removing intermediate container 7db7b5590b25
 ---> 30f5d57a6ccd
Step 4/7 : LABEL com.oracle.weblogic.imagetool.buildid="5247b3f9-9cfd-484c-8fbd-7ab6d7a7cea4"
 ---> Running in 13ae8cd13a0a
Removing intermediate container 13ae8cd13a0a
 ---> ef529e2a418e
Step 5/7 : USER oracle
 ---> Running in 021bac488d7a
Removing intermediate container 021bac488d7a
 ---> 82737c391065
Step 6/7 : COPY --chown=oracle:oracle patches/* /tmp/imagetool/patches/
 ---> 067f37b3c6b3
Step 7/7 : RUN /u01/oracle/OPatch/opatch napply -silent -oh /u01/oracle -phBaseDir /tmp/imagetool/patches     && /u01/oracle/OPatch/opatch util cleanup -silent -oh /u01/oracle     && rm -rf /tmp/imagetool
 ---> Running in 3a0d751a2bc3
Oracle Interim Patch Installer version 13.9.4.2.2
Copyright (c) 2020, Oracle Corporation.  All rights reserved.


Oracle Home       : /u01/oracle
Central Inventory : /u01/oracle/oraInventory
   from           : /u01/oracle/oraInst.loc
OPatch version    : 13.9.4.2.2
OUI version       : 13.9.4.0.0
Log file location : /u01/oracle/cfgtoollogs/opatch/opatch2020-06-04_20-32-01PM_1.log


OPatch detects the Middleware Home as "/u01/oracle"

Verifying environment and performing prerequisite checks...
OPatch continues with these patches:   30761841

Do you want to proceed? [y|n]
Y (auto-answered by -silent)
User Responded with: Y
All checks passed.

Please shutdown Oracle instances running out of this ORACLE_HOME on the local system.
(Oracle Home = '/u01/oracle')


Is the local system ready for patching? [y|n]
Y (auto-answered by -silent)
User Responded with: Y
Backing up files...
Applying interim patch '30761841' to OH '/u01/oracle'
ApplySession: Optional component(s) [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.55.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.55.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.5.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.5.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.55.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.55.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.52.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.52.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.48.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.48.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.49.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.49.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.51.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.51.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.54.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.54.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.54.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.54.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.5.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.5.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.54.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.54.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.55.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.55.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.49.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.49.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.5.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.5.0.0.0 ]  not present in the Oracle Home or a higher version is found.

Patching component oracle.org.bouncycastle.bcprov.jdk15on, 1.60.0.0.0...

Patching component oracle.org.bouncycastle.bcprov.jdk15on, 1.60.0.0.0...

Patching component oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.60.0.0.0...

Patching component oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.60.0.0.0...

Patching component oracle.org.bouncycastle.bcpkix.jdk15on, 1.60.0.0.0...

Patching component oracle.org.bouncycastle.bcpkix.jdk15on, 1.60.0.0.0...
Patch 30761841 successfully applied.
Log file location: /u01/oracle/cfgtoollogs/opatch/opatch2020-06-04_20-32-01PM_1.log

OPatch succeeded.
Oracle Interim Patch Installer version 13.9.4.2.2
Copyright (c) 2020, Oracle Corporation.  All rights reserved.


Oracle Home       : /u01/oracle
Central Inventory : /u01/oracle/oraInventory
   from           : /u01/oracle/oraInst.loc
OPatch version    : 13.9.4.2.2
OUI version       : 13.9.4.0.0
Log file location : /u01/oracle/cfgtoollogs/opatch/opatch2020-06-04_20-33-49PM_1.log


OPatch detects the Middleware Home as "/u01/oracle"

Invoking utility "cleanup"
OPatch will clean up 'restore.sh,make.txt' files and 'scratch,backup' directories.
You will be still able to rollback patches after this cleanup.
Do you want to proceed? [y|n]
Y (auto-answered by -silent)
User Responded with: Y

Backup area for restore has been cleaned up. For a complete list of files/directories
deleted, Please refer log file.

OPatch succeeded.
Removing intermediate container 3a0d751a2bc3
 ---> 80b3778d61b1
Successfully built 80b3778d61b1
Successfully tagged phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4.0-30761841
[INFO   ] Build successful. Build time=181s. Image tag=phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4.0-30761841
```

Push the image to OCIR

docker push phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4.0-30761841

Output will be as below:
```bash
The push refers to repository [phx.ocir.io/tenancy-foo/oracle/soasuite]
b17116140d37: Pushed
8ac15d143100: Pushed
60a49db12ace: Layer already exists
4400cf675c99: Layer already exists
b25551798a11: Layer already exists
fa92a300d884: Layer already exists
e805661264a4: Layer already exists
919af1af2521: Layer already exists
f71fed3e47d2: Layer already exists
5361ff16e37e: Layer already exists
12.2.1.4.0-30761841: digest: sha256:c2a94349fbc226a0ae680f28138f36218600a49ee3571a3aa7df88142ed9c72f size: 2429
```

Update the domain image to new image created now with the patch.
```bash
$ kubectl patch domain soainfra -n soans --type merge  -p '{"spec":{"image":"phx.ocir.io/tenancy-foo/oracle/soasuite:12.2.1.4.0-30761841"}}'"
```

Verify the rolling restart of domain with new image, sample output is as below:
```bash
[opc@oke-bastion imagetool]$ kubectl get pods -n soans  -w
NAME                                         READY   STATUS        RESTARTS   AGE
oracle-db-78b7566996-vsg89                   1/1     Running       0          3d5h
rcu                                          1/1     Running       0          3d5h
soahelper                                    1/1     Running       0          9h
soainfra-adminserver                         1/1     Terminating   0          2d2h
soainfra-create-soa-infra-domain-job-9n89n   0/1     Completed     0          3d1h
soainfra-osb-server1                         1/1     Running       0          2d2h
soainfra-soa-server1                         1/1     Running       0          2d2h
soainfra-adminserver                         0/1     Terminating   0          2d2h
soainfra-adminserver                         0/1     Terminating   0          2d2h
soainfra-adminserver                         0/1     Terminating   0          2d2h
soainfra-adminserver                         0/1     Terminating   0          2d2h
soainfra-adminserver                         0/1     Pending       0          0s
soainfra-adminserver                         0/1     Pending       0          0s
soainfra-adminserver                         0/1     ContainerCreating   0          0s
soainfra-adminserver         .                0/1     Running             0          15s
.
.
```


 
  
