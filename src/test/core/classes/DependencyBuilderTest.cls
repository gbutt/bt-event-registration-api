@IsTest(IsParallel = true)
public class DependencyBuilderTest {
    @IsTest
    static void it_should_build_new_instance() {
        TestDependency result = (TestDependency)DependencyBuilder.newInstance(TestDependency.class);
        System.assertEquals(false, result.state);
    }

    @IsTest
    static void it_should_resolve_cached_instance() {
        TestDependency instance = new TestDependency();
        instance.state = true;
        DependencyBuilder.cacheInstance(TestDependency.class, instance);

        TestDependency result = (TestDependency)DependencyBuilder.newInstance(TestDependency.class);
        System.assertEquals(instance, result);
        System.assertEquals(true, result.state);
    }

    public class TestDependency {
        public Boolean state = false;
    }
}