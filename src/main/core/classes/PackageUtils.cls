public class PackageUtils {
    public static String getNamespaceFromClass(Type classType) {
        return classType.getName().substringBefore('.');
    }
}
