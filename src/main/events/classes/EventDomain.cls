/**
 * @author Greg Butt
 * @date 2021
 *
 * @group Events
 *
 * @description Domain class for Event__c. See https://trailhead.salesforce.com/en/content/learn/modules/apex_patterns_dsl
 * Example URL: https://sandbox-btdev-developer-edition.cs43.force.com/services/apexrest/namespace/events/v1/event
 */
public with sharing class EventDomain extends DomainBase {
    public static Boolean disabled {get; set;}

    List<Event__c> newList;
    Map<Id, Event__c> newMap;
    Map<Id, Event__c> oldMap;

    EventRegistrationService eventRegistrationSvc;

    public EventDomain(List<Event__c> newList, Map<Id, Event__c> newMap, Map<Id, Event__c> oldMap, TriggerOperation operationType) {
        super(operationType);
        this.newList = newList;
        this.newMap = newMap;
        this.oldMap = oldMap;
        this.eventRegistrationSvc = (EventRegistrationService)DependencyResolver.getInstance(EventRegistrationService.class);
    }

    public override Boolean isDisabled() {
        return EventDomain.disabled == true;
    }

    public override void beforeInsert() {
        populateUuids(this.newList);
    }

    public override void beforeUpdate() {
        populateUuids(this.newList);
    }

    public override void afterUpdate() {
        List<Id> recentlyCompletedEventIds = findRecentlyCompletedEvents(this.newList, this.oldMap);
        if (recentlyCompletedEventIds.size() > 0) {
            this.eventRegistrationSvc.markUnregisteredAttendeesNoShow(recentlyCompletedEventIds);
        }
    }

    private static void populateUuids(List<Event__c> newList) {
        for (Event__c newEvent : newList) {
            if (String.isBlank(newEvent.Uuid__c)) {
                newEvent.Uuid__c = DomainBase.createUuid();
            }
        }
    }

    private static List<Id> findRecentlyCompletedEvents(List<Event__c> newList, Map<Id, Event__c> oldMap) {
        List<Id> recentlyCompletedEventIds = new List<Id>();
        for (Event__c newEvent : newList) {
            Event__c oldEvent = oldMap.get(newEvent.Id);
            if (isRecentlyCompleted(newEvent, oldEvent)) {
                recentlyCompletedEventIds.add(newEvent.Id);
            }
        }
        return recentlyCompletedEventIds;
    }

    private static Boolean isRecentlyCompleted(Event__c newEvent, Event__c oldEvent) {
        Boolean isCompleted = newEvent.Status__c == EventRegistrationService.EVENT_STATUS_COMPLETED;
        if (isCompleted == false) {
            return false;
        }

        SObjectComparator comparator = new SObjectComparator(newEvent, oldEvent);
        Boolean isRecentlyCompleted = comparator.hasFieldChanged(Schema.Event__c.Status__c);
        return isRecentlyCompleted;
    }
}