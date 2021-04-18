/**
 * @author Greg Butt
 * @date 2021
 *
 * @group Core
 *
 * @description Utility methods for managed packages
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