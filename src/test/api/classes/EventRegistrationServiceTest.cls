@IsTest
public class EventRegistrationServiceTest {
    private static final String EVENT_UUID = 'event-uuid-123';
    private static final String EMAIL = 'dolly@dollyparton.com';
    private static final String EMAIL2 = 'david@attenboroughfilm.com';
    private static final String EMAIL3 = 'morgan.freeman@gmail.com';

    @TestSetup
    static void makeData() {
        Event__c event = new Event__c(
            Uuid__c = EVENT_UUID
            , Status__c = EventRegistrationService.EVENT_STATUS_OPEN
        );
        EventRegistration__c registration = new EventRegistration__c(
            FirstName__c = 'Dolly'
            , LastName__c = 'Parton'
            , Email__c = EMAIL
            , Event__r = new Event__c(Uuid__c = EVENT_UUID)
        );
        EventRegistration__c registration2 = new EventRegistration__c(
            FirstName__c = 'David'
            , LastName__c = 'Attenborough'
            , Email__c = EMAIL2
            , Event__r = new Event__c(Uuid__c = EVENT_UUID)
        );
        EventRegistration__c registration3 = new EventRegistration__c(
            FirstName__c = 'Morgan'
            , LastName__c = 'Freeman'
            , Email__c = EMAIL3
            , Event__r = new Event__c(Uuid__c = EVENT_UUID)
        );
        insert new List<SObject> {event, registration, registration2, registration3};
    }

    @IsTest
    static void fetchRegistrationsByEmail_should_fetch_event_registrations_by_email() {
        EventRegistrationService svc = new EventRegistrationService();
        List<String> emails = new List<String> {EMAIL, EMAIL2};
        List<EventRegistration__c> results = svc.fetchRegistrationsByEmail(EVENT_UUID, emails);
        System.assertEquals(2, results.size());
        // List<String> resultEmails = (List<String>)SListApi.fromList(results).pluck('Email__c').toList(new List<String>());
        List<String> resultEmails = new List<String>();
        for (EventRegistration__c result : results) {
            resultEmails.add(result.Email__c);
        }
        emails.sort();
        resultEmails.sort();
        System.assertEquals(emails, resultEmails, resultEmails);

        System.assertNotEquals(null, results[0].Id);
        System.assertNotEquals(null, results[0].Name);
        System.assertNotEquals(null, results[0].Email__c);
        System.assertNotEquals(null, results[0].FirstName__c);
        System.assertNotEquals(null, results[0].LastName__c);
        System.assertNotEquals(null, results[0].Status__c);
        System.assertNotEquals(null, results[0].Event__r.Status__c);
        System.assertNotEquals(null, results[0].Event__r.Uuid__c);
    }

    @IsTest
    static void updateRegistrations_should_update_registrations() {
        List<EventRegistration__c> registrations = [SELECT Id FROM EventRegistration__c];
        for (EventRegistration__c registration : registrations) {
            registration.FirstName__c = 'Connie';
            registration.LastName__c = 'Chung';
            registration.Status__c = 'Invited';
            registration.IsNoShow__c = true;
        }
        EventRegistrationService svc = new EventRegistrationService();
        svc.updateRegistrations(registrations, new List<SObjectField>());
        List<EventRegistration__c> results = [
            SELECT Id
            , FirstName__c
            , LastName__c
            , Status__c
            , IsNoShow__c
            FROM EventRegistration__c
        ];
        for (EventRegistration__c result : results) {
            System.assertEquals('Connie', result.FirstName__c);
            System.assertEquals('Chung', result.LastName__c);
            System.assertEquals('Invited', result.Status__c);
            System.assertEquals(true, result.IsNoShow__c);
        }
    }
}