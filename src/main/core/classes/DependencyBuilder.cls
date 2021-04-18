/**
 * @author Greg Butt
 * @date 2021
 *
 * @group Core
 *
 * @description Provides a simple mechanism to inject dependencies in a Unit Test
 */
public class DependencyBuilder {
    private static Map<Type, Object> testCache { get; set; }

    static {
        testCache = new Map<Type, Object>();
    }

    /*******************************************************************************************************
     * @description builds a new instance of a class
     * @param classType the type of object to build
     * @return a new instance of the specified type
     * @example
     * Account a = DependencyBuilder.newInstance(Account.class);
     */
    public static Object newInstance(Type classType) {
        if (testCache.containsKey(classType)) {
            return testCache.get(classType);
        }
        return classType.newInstance();
    }

    public static void cacheInstance(Type classType, Object instance) {
        testCache.put(classType, instance);
    }
}