@IsTest
public class TestUtils {
    public static SObject attachListToParent(SObject parent, List<SObject> children, String parentSideRelationshipName) {
        String targetJson = JSON.serialize(parent);

        String childrenJson = '"' + parentSideRelationshipName + '" : {';
        childrenJson += '"totalSize" : ' + children.size() + ',';
        childrenJson += '"done" : true,';
        childrenJson += '"records" : ' + JSON.serialize(children);
        childrenJson += '}';

        targetJson = targetJson.substring(0, targetJson.length() - 1) + ',' + childrenJson + '}';

        return (SObject)JSON.deserialize(targetJson, SObject.class);
    }

    public static SObject setReadOnlyField(SObject sobj, String fieldName, Object value) {
        return setReadOnlyField(sobj, new Map<String, Object> { fieldName => value });
    }

    public static SObject setReadOnlyField(SObject sobj, Map<String, Object> changesToFields) {
        String serializedRecord = JSON.serialize(sobj);
        Map<String, Object> deserializedRecordMap = (Map<String, Object>)JSON.deserializeUntyped(serializedRecord);

        // Loop through the deserialized record map and put the field & value
        // Since it's a map, if the field already exists on the SObject, it's updated (or added if it wasn't there already)
        for (String sobjectField : changesToFields.keySet()) {
            deserializedRecordMap.put(sobjectField, changesToFields.get(sobjectField));
        }

        serializedRecord = JSON.serialize(deserializedRecordMap);
        return (SObject)JSON.deserialize(serializedRecord, SObject.class);
    }
    public static Id id(Integer i, Schema.SObjectType sobType) {
        String num = String.valueOf(i);
        return sobType.getDescribe().getKeyPrefix() + '0'.repeat(12 - num.length()) + num;
    }
}