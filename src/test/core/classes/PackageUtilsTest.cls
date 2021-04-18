@IsTest(IsParallel = true)
public class PackageUtilsTest {
    @IsTest
    static void it_should_parse_namespace_from_class_type() {
        ApexClass apexClass = [SELECT NamespacePrefix FROM ApexClass WHERE Name = 'PackageUtils'];
        String result = PackageUtils.getNamespaceFromClass(PackageUtils.class);
        System.assertEquals(apexClass.NamespacePrefix, result);
    }
}