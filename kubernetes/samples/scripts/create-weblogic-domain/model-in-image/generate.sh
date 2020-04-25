# TBD add copyright/description

SCRIPTDIR="$( cd "$(dirname "$0")" > /dev/null 2>&1 ; pwd -P )"

set -e

export WORKDIR=/tmp/tbarnes/prestaged
rm -fr /tmp/tbarnes/prestaged
mkdir -p /tmp/tbarnes/prestaged

#$SCRIPTDIR/stage-tooling.sh

export MODEL_IMAGE_NAME=model-in-image

stage-model-configmap.sh

# TBD add dry run output for create-model-configmap.sh
# TBD add dry run output for curl?
# TBD try get console to work via VNC + firefox + /etc/hosts

for type in WLS JRF
do
  export WDT_DOMAIN_TYPE=$type
  for version in v1 v2
  do
    export MODEL_IMAGE_NAME=model-in-image
    export MODEL_IMAGE_TAG=$type-$version
    model_image=$MODEL_IMAGE_NAME:$MODEL_IMAGE_TAG

    # Force generated app archive to have this as the owner directory - e.g. archives/app-$version
    # TBD Maybe rename to ARCHIVE_DIR so the naming convention corresponds with MODEL_DIR
    export TARGET_ARCHIVE_OVERRIDE="archive-$version"

    # Force generated app archive to replace SAMPLE_APP_VERSION in its index.jsp with $version
    export SAMPLE_APP_VERSION="$version"

    model_dir_suffix=files--$(basename $MODEL_IMAGE_NAME):${MODEL_IMAGE_TAG}
    export MODEL_DIR=$WORKDIR/models/$model_dir_suffix

    # Generate WORKDIR/archives app archive and its corresponding model files
    # in WORKDIR/models
    # TBD skip step for unzipping and instead make it part of the generated image build script
    stage-model-image.sh

    # Rename app directory in app archive, and update model to correspond
    # (TBD move this logic into the model/archive scripts respectively)

    if [ -d "$WORKDIR/archives/$TARGET_ARCHIVE_OVERRIDE/wlsdeploy/applications/myapp" ]; then
      # if /myapp doesn't exist, it's because myapp-$version was already created
      # in a previous iteration of this loop
      mv $WORKDIR/archives/$TARGET_ARCHIVE_OVERRIDE/wlsdeploy/applications/myapp \
         $WORKDIR/archives/$TARGET_ARCHIVE_OVERRIDE/wlsdeploy/applications/myapp-$version
    fi
    #sed -i -e "s/myapp/myapp-$version/g" \
    #        $WORKDIR/models/image--$MODEL_IMAGE_NAME:$MODEL_IMAGE_TAG/model.10.yaml
    sed -i -e "s/myapp/myapp-$version/g" $MODEL_DIR/model.10.yaml

    (
      savedir=$(pwd)
      cd $WORKDIR/models
      export WORKDIR=.
      #export MODEL_DIR=image--$model_image
      #export MODEL_DIR=files--$model_image
      export MODEL_DIR=$model_dir_suffix
      $SCRIPTDIR/build-model-image.sh -dry | grep dryrun | sed 's/dryrun://' >> build--$model_image.sh
      chmod +x build--$model_image.sh
      cd $savedir
    )

    for domain in sample-domain1 sample-domain2; do

      export DOMAIN_UID=$domain
      stage-and-create-ingresses.sh -nocreate

      for configmap in true false; do
        export INCLUDE_MODEL_CONFIGMAP=$configmap

        #domain_root=domains/$type/mii--uid-$DOMAIN_UID--image-$version--datasource-cm-$configmap
        if [ "$configmap" = "true" ]; then
          domain_root=domains/$type/uid-$DOMAIN_UID/imagetag-$MODEL_IMAGE_TAG/model-configmap-yes
        else
          domain_root=domains/$type/uid-$DOMAIN_UID/imagetag-$MODEL_IMAGE_TAG/model-configmap-no
        fi

        export DOMAIN_RESOURCE_FILE_NAME=$domain_root/mii-domain.yaml
        stage-domain-resource.sh

        create-secrets.sh -dry kubectl | grep dryrun | sed 's/dryrun://' > $WORKDIR/$domain_root/secrets.sh
        create-secrets.sh -dry yaml | grep dryrun | sed 's/dryrun://' > $WORKDIR/$domain_root/secrets.yaml
        chmod +x $WORKDIR/$domain_root/secrets.sh
   
        if [ "$configmap" = "true" ]; then
           mapdir=$WORKDIR/model-configmap
           utils/create-configmap.sh -dry kubectl -f $mapdir -c $domain-wdt-config-map | grep dryrun | sed 's/dryrun://' > $WORKDIR/$domain_root/model-configmap.sh
           utils/create-configmap.sh -dry yaml    -f $mapdir -c $domain-wdt-config-map | grep dryrun | sed 's/dryrun://' > $WORKDIR/$domain_root/model-configmap.yaml
#(
#set -x
#echo DEBUG
#utils/create-configmap.sh -dry kubectl -f $mapdir
#utils/create-configmap.sh -dry yaml    -f $mapdir 
#)
        fi

        # TBD generate yaml for secrets instead of commands?
        #     this depends on whether we want the sample doc to use commands or yaml...
      done
    done
  done
done

echo "GENERATE DONE! See target directory '$WORKDIR'."
