/**
 * @author Greg Butt
 * @date 2021
 *
 * @group Core
 *
 * @description Provides a simple mechanism to inject dependencies in a Unit Test
 */
public class DependencyResolver {
    @TestVisible
    private static Map<Type, Object> cachedDependencies { get; set; }

    static {
        cachedDependencies = new Map<Type, Object>();
    }

    // core methods abstract the core logic
    public static Object getInstance(Type classType) {
        if (cachedDependencies.containsKey(classType)) {
            return cachedDependencies.get(classType);
        }
        return classType.newInstance();
    }

    public static void cacheInstance(Type classType, Object instance) {
        cachedDependencies.put(classType, instance);
    }

    public static void mockInstance(UniversalMocker stubProvider) {
        cacheInstance(stubProvider.getStubbedType(), stubProvider.createStub());
    }
}