@IsTest(IsParallel=true)
public class PackageUtilsTest {
    @IsTest
    static void it_should_parse_namespace_from_class_type() {
        String result = PackageUtils.getNamespaceFromClass(PackageUtils.class);
        System.assertEquals('gbutt', result.substringBefore('.'));
    }
}
