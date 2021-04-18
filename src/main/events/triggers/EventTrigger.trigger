trigger EventTrigger on Event__c(before insert, before update, after update) {
    new EventDomain(Trigger.new, Trigger.newMap, Trigger.oldMap, Trigger.operationType).execute();
}