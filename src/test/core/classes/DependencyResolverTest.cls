@IsTest
public class DependencyResolverTest {
    @IsTest
    static void it_should_resolve_new_instance() {
        TestDependency result = (TestDependency)DependencyResolver.getInstance(TestDependency.class);
        System.assertEquals(false, result.state);
    }

    @IsTest
    static void it_should_resolve_cached_instance() {
        TestDependency instance = new TestDependency();
        instance.state = true;
        DependencyResolver.cachedDependencies.put(TestDependency.class, instance);

        TestDependency result = (TestDependency)DependencyResolver.getInstance(TestDependency.class);
        System.assertEquals(instance, result);
        System.assertEquals(true, result.state);
    }

    public class TestDependency {
        public Boolean state = false;
    }
}