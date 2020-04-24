// Copyright (c) 2020, Oracle Corporation and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package oracle.weblogic.kubernetes.actions.impl;

import oracle.weblogic.kubernetes.actions.impl.primitive.Command;
import oracle.weblogic.kubernetes.actions.impl.primitive.CommandParams;
import oracle.weblogic.kubernetes.actions.impl.primitive.Helm;
import oracle.weblogic.kubernetes.actions.impl.primitive.HelmParams;
import oracle.weblogic.kubernetes.logging.LoggingFacade;
import oracle.weblogic.kubernetes.logging.LoggingFactory;

import static oracle.weblogic.kubernetes.TestConstants.OPERATOR_DOCKER_BUILD_SCRIPT;
import static oracle.weblogic.kubernetes.TestConstants.OPERATOR_IMAGE_NAME;
import static oracle.weblogic.kubernetes.TestConstants.REPO_NAME;

/**
 * Action class with implementation methods for Operator.
 */
public class Operator {
  private static final LoggingFacade logger = LoggingFactory.getLogger(Operator.class);

  /**
   * install helm chart.
   * @param params the helm parameters like namespace, release name, repo url or chart dir,
   *               chart name and chart values to override
   * @return true on success, false otherwise
   */
  public static boolean install(OperatorParams params) {
    return Helm.install(params.getHelmParams(), params.getValues());
  }

  /**
   * Upgrade a helm release.
   * @param params the helm parameters like namespace, release name, repo url or chart dir,
   *               chart name and chart values to override
   * @return true on success, false otherwise
   */
  public static boolean upgrade(OperatorParams params) {
    return Helm.upgrade(params.getHelmParams(), params.getValues());
  }

  /**
   * Uninstall a helm release.
   * @param params the parameters to helm uninstall command, release name and namespace
   * @return true on success, false otherwise
   */
  public static boolean uninstall(HelmParams params) {
    return Helm.uninstall(params);
  }

  public static boolean scaleDomain(String domainUid, String clusterName, int numOfServers) {
    return true;
  }

  /**
   * Image Name for the Operator. Uses branch name for tag in local runs
   * and branch name, build id for tag in Jenkins runs.
   * @return image name
   */
  public static String getImageName() {
    String image = "";

    String imageName = System.getenv("IMAGE_NAME_OPERATOR") != null
        ? System.getenv("IMAGE_NAME_OPERATOR") : OPERATOR_IMAGE_NAME;

    // use build id for Jenkins runs in image tag
    String buildID = System.getenv("BUILD_ID") != null
        ? System.getenv("BUILD_ID") : "";

    // get branch name
    String branchName = "";
    if (!buildID.isEmpty()) {
      branchName = System.getenv("BRANCH");
      imageName = REPO_NAME + imageName;
    } else  {
      CommandParams params = Command.defaultCommandParams()
          .command("git branch | grep \\* | cut -d ' ' -f2-")
          .saveResults(true)
          .redirect(false);

      if (Command.withParams(params)
          .execute()) {
        branchName = params.stdout();
      }
    }
    String imageTag = System.getenv("IMAGE_TAG_OPERATOR") != null
        ? System.getenv("IMAGE_TAG_OPERATOR") : branchName + buildID;
    image = imageName + ":" + imageTag;
    return image;
  }

  /**
   * Builds a Docker Image for the Oracle WebLogic Kubernetes Operator.
   * @param image image name and tag in 'name:tag' format
   * @return true on success
   */
  public static boolean buildImage(String image) {
    String command = String.format("%s -t %s", OPERATOR_DOCKER_BUILD_SCRIPT, image);
    return new Command()
        .withParams(new CommandParams()
            .command(command))
        .execute();
  }
}
