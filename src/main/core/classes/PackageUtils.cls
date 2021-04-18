/*
   System.debug(PackageUtils.getNamespaceFromClass(EventRegistrationApi.class));
   System.debug(EventRegistrationApi.class.getName());
 */

public class PackageUtils {
    // Doesn't work for inner classes. Ensuring proper usage is the responsibility of the caller.
    public static String getNamespaceFromClass(Type classType) {
        List<String> classNameParts = classType.getName().split('\\.');
        if (classNameParts.size() > 1) {
            return classNameParts[0];
        }
        return null;
    }
}