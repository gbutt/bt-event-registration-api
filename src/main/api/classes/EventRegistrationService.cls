public with sharing class EventRegistrationService {
    public static final String EVENT_STATUS_OPEN = 'Open';
    public static final String EVENT_STATUS_CLOSED = 'Closed';
    public static final String REGISTRATION_STATUS_INVITED = 'Invited';
    public static final String REGISTRATION_STATUS_REGISTERED = 'Registered';

    private WosSelector wosSelector {get; set;}

    private SObjectUnitOfWork uow {get; set;}

    public EventRegistrationService() {
        this.wosSelector = new WosSelector();
        this.uow = new SObjectUnitOfWork(new List<Schema.SObjectType> {EventRegistration__c.getSobjectType()});
    }

    public List<EventRegistration__c> fetchRegistrationsByEmail(String eventUuid, List<String> emails) {
        return this.wosSelector.fetchRegistrationsByEmail(eventUuid, emails);
    }

    public void updateRegistrations(List<EventRegistration__c> registrations, List<SObjectField> fieldsToUpdate) {
        this.uow.registerDirty(registrations, fieldsToUpdate);
        this.wosSelector.commitWork(this.uow);
    }

    private without sharing class WosSelector {
        private List<EventRegistration__c> fetchRegistrationsByEmail(String eventUuid, List<String> emails) {
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
                WHERE Event__r.Uuid__c = : eventUuid
                    AND Email__c IN : emails
            ];
        }

        private void commitWork(SObjectUnitOfWork uow) {
            uow.commitWork();
        }
    }
}