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

    EventRegistrationService.I eventRegistrationSvc;

    public EventDomain(List<Event__c> newList, Map<Id, Event__c> newMap, Map<Id, Event__c> oldMap, TriggerOperation operationType) {
        super(operationType);
        this.newList = newList;
        this.newMap = newMap;
        this.oldMap = oldMap;
        this.eventRegistrationSvc = (EventRegistrationService.I)DependencyBuilder.newInstance(EventRegistrationService.class);
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
        // mark no-shows on completed events
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

    private List<Id> findRecentlyCompletedEvents(List<Event__c> newList, Map<Id, Event__c> oldMap) {
        List<Id> recentlyCompletedEventIds = new List<Id>();

        for (Event__c newEvent : newList) {
            Event__c oldEvent = oldMap.get(newEvent.Id);

            if (newEvent.Status__c == EventRegistrationService.EVENT_STATUS_COMPLETED) {
                if (isRecentChange(Schema.Event__c.Status__c, newEvent, oldEvent)) {
                    recentlyCompletedEventIds.add(newEvent.Id);
                }
            }
        }

        return recentlyCompletedEventIds;
    }


    private Boolean isRecentChange(SObjectField field, Event__c newEvent, Event__c oldEvent) {
        SObjectComparator comparator = getComparatorForEvents(newEvent, oldEvent);
        return comparator.hasFieldChanged(field);
    }

    Map<Id, SObjectComparator> comparatorCache = new Map<Id, SObjectComparator>();
    private SObjectComparator getComparatorForEvents(Event__c newEvent, Event__c oldEvent) {
        SObjectComparator comparator = comparatorCache.get(newEvent.Id);
        if (comparator == null) {
            comparator = new SObjectComparator(newEvent, oldEvent);
            comparatorCache.put(newEvent.Id, comparator);
        }
        return comparator;
    }
}