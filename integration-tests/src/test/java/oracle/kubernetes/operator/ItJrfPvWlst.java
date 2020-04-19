// Copyright (c) 2019, 2020, Oracle Corporation and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package oracle.kubernetes.operator;

import java.util.ArrayList;
import java.util.Map;
import java.util.logging.Level;

import oracle.kubernetes.operator.utils.DbUtils;
import oracle.kubernetes.operator.utils.JrfDomain;
import oracle.kubernetes.operator.utils.LoggerHelper;
import oracle.kubernetes.operator.utils.Operator;
import oracle.kubernetes.operator.utils.TestUtils;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.MethodOrderer.Alphanumeric;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@TestMethodOrder(Alphanumeric.class)

public class ItJrfPvWlst extends BaseTest {
  private static String rcuSchemaPrefix = "jrfdomain";
  private static Operator operator1;
  private static String domainNS;
  private static String domainUid = "";
  private static String restartTmpDir = "";
  private static boolean testCompletedSuccessfully;
  private static String testClassName;
  private static StringBuffer namespaceList;
  private static int dbPort;
  private static String dbNamespace;
  private static String dbUrl;

  /**
   * This method gets called only once before any of the test methods are executed. It does the
   * initialization of the integration test properties defined in OperatorIT.properties and setting
   * the resultRoot, pvRoot and projectRoot attributes.
   *
  * @throws Exception if initial setup fails
  */
  @BeforeAll
  public static void staticPrepare() throws Exception {
    namespaceList = new StringBuffer();
    testClassName = new Object() {
    }.getClass().getEnclosingClass().getSimpleName();
    // initialize test properties 
    initialize(APP_PROPS_FILE, testClassName);  
  }

  /**
   * This method gets called before every test. It creates the result/pv root directories
   * for the test. Creates RCU schema, operator if its not running.
   *
   * @throws Exception exception if result/pv/operator/RCU schema creation fails
   */
  @BeforeEach
  public void prepare() throws Exception {
    if (QUICKTEST) {
      createResultAndPvDirs(testClassName);
      
      TestUtils.exec(
          "cp -rf " 
          + BaseTest.getProjectRoot() 
          + "/kubernetes/samples/scripts " 
          + getResultDir(),
          true);
      
      //start DB and create RCU
      dbNamespace = "db" + String.valueOf(getNewSuffixCount());
      DbUtils.createNamespace(dbNamespace);
      dbPort = 30011 + getNewSuffixCount();
      dbUrl = "oracle-db." + dbNamespace + ".svc.cluster.local:1521/devpdb.k8s";
      LoggerHelper.getLocal().log(Level.INFO,"For test: " + testClassName 
          + " dbNamespace is: " + dbNamespace + " dbUrl:" + dbUrl + " dbPort: " + dbPort);
      DbUtils.createDbRcu(getResultDir(), dbPort, dbUrl, rcuSchemaPrefix, dbNamespace);
      
      // create operator1
      if (operator1 == null) {
        Map<String, Object> operatorMap = createOperatorMap(getNewSuffixCount(),
            true, testClassName);
        operator1 = TestUtils.createOperator(operatorMap, Operator.RestCertType.SELF_SIGNED);
        Assertions.assertNotNull(operator1);
        domainNS = ((ArrayList<String>) operatorMap.get("domainNamespaces")).get(0);
        namespaceList.append((String)operatorMap.get("namespace"));
        namespaceList.append(" ").append(domainNS);
      }
    }  
  }
  
  /**
   * This method will run once after all test methods are finished. It delete both RCU and DB pods
   *
   * @throws Exception - if any error occurs
   */
  @AfterEach
  public void unPrepare() throws Exception {
    DbUtils.deleteRcuPod(getResultDir());
    DbUtils.deleteDbPod(getResultDir());
  }
  
  /**
  * This method will run once after all test methods are finished. It Releases k8s cluster lease,
  * archives result, pv directories.
  *
  * @throws Exception - if any error occurs
  */
  @AfterAll
  public static void staticUnPrepare() throws Exception {
    tearDown(new Object() {
    }.getClass().getEnclosingClass().getSimpleName(), namespaceList.toString());

    LoggerHelper.getLocal().log(Level.INFO,"SUCCESS");
  }
 
  @Test
  public void testJrfDomainOnPvUsingWlst() throws Exception {
    if (QUICKTEST) {
      String testMethodName = new Object() {
      }.getClass().getEnclosingMethod().getName();
      logTestBegin(testMethodName);
      LoggerHelper.getLocal().log(Level.INFO,
          "Creating Operator & waiting for the script to complete execution");
      
      JrfDomain jrfdomain = null;
      boolean testCompletedSuccessfully = false;

      try {
        // create JRF domain
        Map<String, Object> domainMap = createDomainMap(getNewSuffixCount(), testClassName);
        domainMap.put("namespace", domainNS);
        domainMap.put("initialManagedServerReplicas", new Integer("2"));
        domainMap.put("clusterName", "infra-cluster");
        domainMap.put("managedServerNameBase", "infraserver");
        domainMap.put("domainHomeSourceType", "PersistentVolume");
        domainMap.put("rcuSchemaPrefix", "jrfdomain");
        LoggerHelper.getLocal().log(Level.INFO, "DEBUG " + testClassName + "domain: dbUrl: " + dbUrl);
        domainMap.put("rcuDatabaseURL", dbUrl);
        domainUid = (String) domainMap.get("domainUID");
        LoggerHelper.getLocal().log(Level.INFO,
            "Creating and verifying the domain creation with domainUid: " + domainUid);

        jrfdomain = new JrfDomain(domainMap);
        jrfdomain.verifyDomainCreated(80);
        
        // basic test cases
        testBasicUseCases(jrfdomain, false);

        testCompletedSuccessfully = true;
      } finally {
        if (jrfdomain != null  && (JENKINS || testCompletedSuccessfully)) {
          jrfdomain.shutdownUsingServerStartPolicy();
        }
      }

      LoggerHelper.getLocal().log(Level.INFO, "SUCCESS - " + testMethodName);
    }
  }
}
