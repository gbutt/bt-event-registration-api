public with sharing class EventDomain extends DomainBase {
    public static Boolean disabled {get; set;}

    List<Event__c> newList;
    Map<Id, Event__c> newMap;
    Map<Id, Event__c> oldMap;

    public EventDomain(List<Event__c> newList, Map<Id, Event__c> newMap, Map<Id, Event__c> oldMap, TriggerOperation operationType) {
        super(operationType);
        this.newList = newList;
        this.newMap = newMap;
        this.oldMap = oldMap;
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
        markUnregisteredAttendeesNoShow(recentlyCompletedEventIds);
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
            SObjectComparator comparator = new SObjectComparator(newEvent, oldEvent);
            if (comparator.hasFieldChanged(Schema.Event__c.Status__c) && newEvent.Status__c == EventRegistrationService.EVENT_STATUS_COMPLETED) {
                recentlyCompletedEventIds.add(newEvent.Id);
            }
        }
        return recentlyCompletedEventIds;
    }

    private static void markUnregisteredAttendeesNoShow(List<Id> recentlyCompletedEventIds) {
        EventRegistrationService svc = (EventRegistrationService)DependencyResolver.getInstance(EventRegistrationService.class);
        List<EventRegistration__c> foundRegistraitons = svc.fetchRegistrationsByStatusNotIn(recentlyCompletedEventIds, new List<String> {
            EventRegistrationService.REGISTRATION_STATUS_REGISTERED
        });
        List<EventRegistration__c> registrationsToUpdate = new List<EventRegistration__c>();
        for (EventRegistration__c registration : foundRegistraitons) {
            if (registration.Status__c != EventRegistrationService.REGISTRATION_STATUS_REGISTERED) {
                registrationsToUpdate.add(
                    new EventRegistration__c(
                        Id = registration.Id
                        , IsNoShow__c = true
                ));
            }
        }
        svc.updateRegistrations(registrationsToUpdate, new List<SObjectField> {
            Schema.EventRegistration__c.IsNoShow__c
        });
    }
}