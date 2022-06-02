package org.nuvindu.pubsub.utils;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Module;

/**
 * This class includes the utility functions related to the PubSub module.
 */
public class ModuleUtils {

    private static Module module;
    private static Environment currentEnvironment;

    private ModuleUtils() {}

    public static void setModule(Environment environment) {
        module = environment.getCurrentModule();
        currentEnvironment = environment;
    }

    public static Module getModule() {
        return module;
    }

    public static Environment getEnvironment() {
        return currentEnvironment;
    }
}
