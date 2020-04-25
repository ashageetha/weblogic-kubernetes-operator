# Copyright (c) 2020, Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Description:
#   This file can be modified to customize the behavior of the
#   other scripts in this sample.
#
#   It is copied to WORKDIR from the sample directory by 'stage-workdir.sh',
#   and is automatically loaded from its WORKDIR location by every script
#   in this sample (except for 'stage-workdir.sh').
# 

# export DOMAIN_UID=
# ::: Domain UID
#  Default is 'sample-domain1'. This is the name of the sample's deployed 
#  domain resource and must be unique within a Kubernetes cluster.

# export DOMAIN_NAMESPACE=
# ::: Domain Namespace
#  Default is 'sample-domain1-ns'.

# export CUSTOM_DOMAIN_NAME=
# ::: WebLogic Domain Name
#  This is the configured WebLogic domain name (not the domain UID). The domain
#  name is set at runtime using an '@@ENV:CUSTOM_DOMAIN_NAME@@' model macro in
#  the model image's model files staged by 'stage-model-image.sh'. The
#  environment variable is passed to the model at runtime by the domain resource
#  that's generated by 'stage-domain-resource.sh'. Default is 'domain1'.

# export WDT_DOMAIN_TYPE=
# ::: WDT domain type.
#  Set to 'WLS' (default) for a standard WLS domain, 'RestrictedJRF', or 'JRF. 
#  This value is used by './build-model-image.sh' as a WIT parameter and
#  also to help choose the base image default. It's also used by 
#  './stage-domain-resource.sh' to set the 'configuration.model.domainType'
#  domain resource field.

# export BASE_IMAGE_NAME=
# ::: Base image name.
#  Used by './build-model-image.sh'.
#  Defaults to 'container-registry.oracle.com/middleware/weblogic' for the 
#  'WLS' WDT_DOMAIN_TYPE, and otherwise defaults to 
#  'container-registry.oracle.com/middleware/fmw-infrastructure'.

# export BASE_IMAGE_TAG=
# ::: Base image tag.
#  Defaults to 12.2.1.4. Used by the './build-model-image.sh' script. 

# export MODEL_IMAGE_BUILD=
# ::: When to build model image.
#  Set to 'when-missing' (default) to tell './build-model-image.sh' to skip
#  building a model image when MODEL_IMAGE_NAME:MODEL_IMAGE_TAG already
#  exists in your docker image cache. Set to 'always' to always build.

# export MODEL_IMAGE_NAME=
# ::: Model image name.
#  Used for the model image that's generated by './build-model-image.sh', 
#  and also by the './stage-domain-resource.sh' script to set the
#  domain resource 'spec.image' setting. 
#  Defaults to 'model-in-image'.

# export MODEL_IMAGE_TAG=
# ::: Model image tag.
#  Defaults to 'v1'. See MODEL_IMAGE_NAME for more info.

# export MODEL_DIR=
# ::: Location of staged model files for the model image.
#  Location of staged model .zip, .properties, and .yaml files that are
#  copied into the model image by the './build-model-image.sh' script.
#  Default is:
#   'WORKDIR/models/image--$(basename $MODEL_IMAGE_NAME):${MODEL_IMAGE_TAG}'
#  which is populated by the './stage-model-image.sh' script.

# export INCLUDE_MODEL_CONFIGMAP
# ::: Tell sample to include a configuration.model.configMap
#  Used by './stage-domain-resource.sh' to add a reference to a configMap
#  in the domain resource, and to add a configuration.model.secrets reference
#  to a secret that's used by the configMap. Also used by 'create-secrets.sh' to
#  deploy a secret the configMap uses. See also MODEL_CONFIGMAP_DIR.
#  Valid values are 'false' (default), and 'true'.

# export MODEL_CONFIGMAP_DIR=
# ::: Configmap model files.
#  Location of staged model files that will be loaded at runtime from a
#  configmap specified by the domain resource. Default is 
#  'WORKDIR/model-configmap', which is populated by the 
#  './stage-model-configmap.sh' script and used by
#  'create-model-configmap.sh'.  See also INCLUDE_MODEL_CONFIGMAP.

# export DOWNLOAD_WDT=
# ::: When to download the WDT installer zip.
#  Set to 'always' to always download WDT even if WORKDIR already has 
#  a download, default is 'when-missing'. Used by './stage-tooling.sh'.

# export WDT_INSTALLER_URL=
# ::: WDT installer URL
#  Used by './stage-tooling.sh' to obtain the WDT installer.
#  Set to a specific zip loc to download specific version, for example:
#   'https://github.com/oracle/weblogic-deploy-tooling/releases/download/weblogic-deploy-tooling-1.7.1/weblogic-deploy.zip'
#  TBD before releasing 3.0, update example version above to correspond to latest and greatest version - and/or point to where we document the supported version 
#  Defaults to 'https://github.com/oracle/weblogic-deploy-tooling/releases/latest'

# export DOWNLOAD_WIT=
# ::: When to download the WIT installer zip.
#  Set to 'always' to always download WIT even if WORKDIR already has 
#  a download, default is 'when-missing'. Used by './stage-tooling.sh'.

# export WIT_INSTALLER_URL=
# ::: WIT installer URL
#  Used by './stage-tooling.sh' to obtain the WIT installer.
#  Set to zip loc to download specific version, for example:
#   'https://github.com/oracle/weblogic-image-tool/releases/download/release-1.8.1/imagetool.zip'
#  TBD before releasing 3.0, update example version above to correspond to latest and greatest version - and/or point to where we document the supported version 
#  Defaults to 'https://github.com/oracle/weblogic-image-tool/releases/latest'

# export DOMAIN_RESOURCE_TEMPLATE=
# ::: Domain resource template
#  Used by './stage-domain-resource.sh' as a template for generating a domain
#  resource yaml file in WORKDIR. Defaults to 
#  'sample-domain-resource/mii-domain.yaml.template-WDT_DOMAIN_TYPE'

# TBD add DB_NAMESPACE (used for setting up the DB urls), can the DB port change?
