/**
 * @author Greg Butt
 * @date 2021
 *
 * @group Events
 *
 * @description Service class for Event Registrations. See https://trailhead.salesforce.com/en/content/learn/modules/apex_patterns_sl
 */
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

    // TODO: bulkify
    public EventRegistration__c updateRegistration(String eventUuid, EventRegistration__c registrationTemplate) {
        if (String.isBlank(eventUuid) || registrationTemplate == null || String.isBlank(registrationTemplate.Email__c)) {
            throw new RegistrationNotFoundException();
        }
        List<EventRegistration__c> foundRegistrations = fetchRegistrationsByEmail(
            new List<String> {eventUuid},
            new List<String> {registrationTemplate.Email__c}
        );
        if (foundRegistrations.size() == 0) {
            throw new RegistrationNotFoundException();
        }
        EventRegistration__c registration = foundRegistrations[0];
        if (registration.Event__r.Status__c != EventRegistrationService.EVENT_STATUS_OPEN) {
            throw new RegistrationNotAllowedException();
        }

        List<SObjectField> fieldsToUpdate = new List<SObjectField> {
            Schema.EventRegistration__c.FirstName__c
            , Schema.EventRegistration__c.LastName__c
            , Schema.EventRegistration__c.Status__c
        };
        Map<String, Object> fieldMap = registrationTemplate.getPopulatedFieldsAsMap();
        for (SObjectField field : fieldsToUpdate) {
            String name = field.getDescribe().getName();
            if (fieldMap.containsKey(name)) {
                registration.put(name, registrationTemplate.get(name));
            }
        }

        updateRegistrations(new List<EventRegistration__c> {registration}, fieldsToUpdate);
        return registration;
    }

    public void markUnregisteredAttendeesNoShow(List<Id> eventIds) {
        List<EventRegistration__c> foundRegistraitons = this.wosSelector.fetchRegistrationsByStatusNotIn(eventIds, new List<String> {
            EventRegistrationService.REGISTRATION_STATUS_REGISTERED
        });
        List<EventRegistration__c> registrationsToUpdate = new List<EventRegistration__c>();
        for (EventRegistration__c registration : foundRegistraitons) {
            registrationsToUpdate.add(
                new EventRegistration__c(
                    Id = registration.Id
                    , IsNoShow__c = true
            ));
        }
        updateRegistrations(registrationsToUpdate, new List<SObjectField> {
            Schema.EventRegistration__c.IsNoShow__c
        });
    }

    @TestVisible
    private List<EventRegistration__c> fetchRegistrationsByEmail(List<String> eventUuids, List<String> emails) {
        return this.wosSelector.fetchRegistrationsByEmail(eventUuids, emails);
    }

    @TestVisible
    private List<EventRegistration__c> fetchRegistrationsByStatusNotIn(List<String> eventUuids, List<String> statuses) {
        return this.wosSelector.fetchRegistrationsByStatusNotIn(eventUuids, statuses);
    }

    @TestVisible
    private void updateRegistrations(List<EventRegistration__c> registrations, List<SObjectField> fieldsToUpdate) {
        this.uow.registerDirty(registrations, fieldsToUpdate);
        this.wosSelector.commitWork(this.uow);
    }

    public class RegistrationNotAllowedException extends Exception {}
    public class RegistrationNotFoundException extends Exception {}

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