public with sharing class EventRegistrationService {
    public static final String EVENT_STATUS_NEW = 'New';
    public static final String EVENT_STATUS_OPEN = 'Open';
    public static final String EVENT_STATUS_CLOSED = 'Closed';
    public static final String EVENT_STATUS_COMPLETED = 'Completed';
    public static final String REGISTRATION_STATUS_INVITED = 'Invited';
    public static final String REGISTRATION_STATUS_REGISTERED = 'Registered';

    private WosSelector wosSelector {get; set;}

    private SObjectUnitOfWork uow {get; set;}

    public EventRegistrationService() {
        this.wosSelector = new WosSelector();
        this.uow = new SObjectUnitOfWork(new List<Schema.SObjectType> {
            EventRegistration__c.getSobjectType()
        });
    }

    public List<EventRegistration__c> fetchRegistrationsByEmail(String eventUuid, List<String> emails) {
        return fetchRegistrationsByEmail(new List<String> {eventUuid}, emails);
    }

    public List<EventRegistration__c> fetchRegistrationsByEmail(List<String> eventUuids, List<String> emails) {
        return this.wosSelector.fetchRegistrationsByEmail(eventUuids, emails);
    }

    public List<EventRegistration__c> fetchRegistrationsByStatusNotIn(List<Id> eventIds, List<String> statuses) {
        return this.wosSelector.fetchRegistrationsByStatusNotIn(eventIds, statuses);
    }

    public void updateRegistrations(List<EventRegistration__c> registrations, List<SObjectField> fieldsToUpdate) {
        this.uow.registerDirty(registrations, fieldsToUpdate);
        this.wosSelector.commitWork(this.uow);
    }

    private without sharing class WosSelector {
        private List<EventRegistration__c> fetchRegistrationsByEmail(List<String> eventUuids, List<String> emails) {
            return [
                SELECT Id
                , Name
                , Email__c
                , FirstName__c
                , LastName__c
                , Status__c
                , Event__r.Status__c
                , Event__r.Uuid__c
                FROM EventRegistration__c
                WHERE Event__r.Uuid__c IN : eventUuids
                AND Email__c IN : emails
            ];
        }

        private List<EventRegistration__c> fetchRegistrationsByStatusNotIn(List<Id> eventIds, List<String> statuses) {
            return [
                SELECT Id
                , Name
                , Email__c
                , FirstName__c
                , LastName__c
                , Status__c
                , Event__r.Status__c
                , Event__r.Uuid__c
                FROM EventRegistration__c
                WHERE Event__c IN : eventIds
                AND Status__c NOT IN : statuses
            ];
        }

        private void commitWork(SObjectUnitOfWork uow) {
            uow.commitWork();
        }
    }
}