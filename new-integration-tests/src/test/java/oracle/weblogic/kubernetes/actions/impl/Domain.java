// Copyright 2020, Oracle Corporation and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package oracle.weblogic.kubernetes.actions.impl;

public class Domain {

    public static boolean createDomainCustomResource(String domainUID, String namespace, String domainYAML) {
        return true;
    }

    public static boolean shutdown(String domainUID, String namespace) {
        return true;
    }

    public static boolean restart(String domainUID, String namespace) {
        return true;
    }

    public static boolean deleteDomainCustomResource(String domainUID, String namespace) {
        return true;
    }
}