@IsTest(IsParallel = true)
public class EventRegistrationServiceTest {
    private static final String EVENT_UUID = 'event-uuid-123';
    private static final String EMAIL = 'dolly@dollyparton.com';
    private static final String EMAIL2 = 'david@attenboroughfilm.com';
    private static final String EMAIL3 = 'morgan.freeman@gmail.com';

    @TestSetup
    static void makeData() {
        Event__c event = new Event__c(
            Name = 'Test Event'
            , Uuid__c = EVENT_UUID
            , Status__c = EventRegistrationService.EVENT_STATUS_OPEN
        );
        EventRegistration__c registration = new EventRegistration__c(
            FirstName__c = 'Dolly'
            , LastName__c = 'Parton'
            , Email__c = EMAIL
            , Status__c = EventRegistrationService.REGISTRATION_STATUS_INVITED
            , Event__r = new Event__c(Uuid__c = EVENT_UUID)
        );
        EventRegistration__c registration2 = new EventRegistration__c(
            FirstName__c = 'David'
            , LastName__c = 'Attenborough'
            , Email__c = EMAIL2
            , Status__c = EventRegistrationService.REGISTRATION_STATUS_INVITED
            , Event__r = new Event__c(Uuid__c = EVENT_UUID)
        );
        EventRegistration__c registration3 = new EventRegistration__c(
            FirstName__c = 'Morgan'
            , LastName__c = 'Freeman'
            , Email__c = EMAIL3
            , Status__c = EventRegistrationService.REGISTRATION_STATUS_REGISTERED
            , Event__r = new Event__c(Uuid__c = EVENT_UUID)
        );
        insert new List<SObject> {event, registration, registration2, registration3};
    }

    @IsTest
    static void updateRegistration_should_update_registration() {
        EventRegistration__c registrationTemplate = new EventRegistration__c(
            FirstName__c = 'Dolly2'
            , LastName__c = 'Parton2'
            , Email__c = EMAIL
            , Status__c = EventRegistrationService.REGISTRATION_STATUS_REGISTERED
        );

        // when
        EventRegistrationService svc = new EventRegistrationService();
        EventRegistration__c result = svc.updateRegistration(EVENT_UUID, registrationTemplate);

        // then
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.Name);

        result = [SELECT FirstName__c, LastName__c, Status__c FROM EventRegistration__c WHERE Id = :result.Id];
        System.assertEquals('Dolly2', result.FirstName__c);
        System.assertEquals('Parton2', result.LastName__c);
        System.assertEquals(EventRegistrationService.REGISTRATION_STATUS_REGISTERED, result.Status__c);
    }

    @IsTest
    static void updateRegistration_should_return_error_when_event_uuid_not_provided() {
        // given - unknown registrant
        EventRegistration__c registrationTemplate = new EventRegistration__c(
            Email__c = EMAIL
        );

        // when
        EventRegistrationService svc = new EventRegistrationService();
        Exception caught = null;
        try {
            svc.updateRegistration(null, registrationTemplate);
        } catch (Exception ex) {
            caught = ex;
        }

        // then
        System.assertNotEquals(null, caught);
        System.assert(caught instanceof EventRegistrationService.RegistrationNotFoundException, caught.getTypeName());

        // when
        caught = null;
        try {
            svc.updateRegistration(' ', registrationTemplate);
        } catch (Exception ex) {
            caught = ex;
        }

        // then
        System.assertNotEquals(null, caught);
        System.assert(caught instanceof EventRegistrationService.RegistrationNotFoundException, caught.getTypeName());
    }

    @IsTest
    static void updateRegistration_should_return_error_when_email_not_provided() {
        // given - unknown registrant
        EventRegistration__c registrationTemplate = new EventRegistration__c(
            Email__c = null
        );

        // when
        EventRegistrationService svc = new EventRegistrationService();
        Exception caught;
        try {
            svc.updateRegistration(EVENT_UUID, registrationTemplate);
        } catch (Exception ex) {
            caught = ex;
        }

        // then
        System.assertNotEquals(null, caught);
        System.assert(caught instanceof EventRegistrationService.RegistrationNotFoundException, caught.getTypeName());

        // when
        registrationTemplate.Email__c = ' ';
        caught = null;
        try {
            svc.updateRegistration(EVENT_UUID, registrationTemplate);
        } catch (Exception ex) {
            caught = ex;
        }

        // then
        System.assertNotEquals(null, caught);
        System.assert(caught instanceof EventRegistrationService.RegistrationNotFoundException, caught.getTypeName());

        // when
        registrationTemplate = null;
        caught = null;
        try {
            svc.updateRegistration(EVENT_UUID, registrationTemplate);
        } catch (Exception ex) {
            caught = ex;
        }

        // then
        System.assertNotEquals(null, caught);
        System.assert(caught instanceof EventRegistrationService.RegistrationNotFoundException, caught.getTypeName());
    }

    @IsTest
    static void updateRegistration_should_return_error_when_registration_not_found() {
        // given - unknown registrant
        EventRegistration__c registrationTemplate = new EventRegistration__c(
            FirstName__c = 'Chuck'
            , LastName__c = 'Jones'
            , Email__c = 'chuck.jones@looneytunes.co'
            , Status__c = EventRegistrationService.REGISTRATION_STATUS_REGISTERED
        );

        // when
        EventRegistrationService svc = new EventRegistrationService();
        Exception caught;
        try {
            svc.updateRegistration(EVENT_UUID, registrationTemplate);
        } catch (Exception ex) {
            caught = ex;
        }

        // then
        System.assertNotEquals(null, caught);
        System.assert(caught instanceof EventRegistrationService.RegistrationNotFoundException, caught.getTypeName());
    }

    @IsTest
    static void updateRegistration_should_return_error_when_event_registration_is_not_open() {
        // given - closed event
        Event__c myEvent = new Event__c(
            Uuid__c = EVENT_UUID
            , Status__c = EventRegistrationService.EVENT_STATUS_CLOSED
        );
        upsert myEvent Uuid__c;
        EventRegistration__c registrationTemplate = new EventRegistration__c(
            FirstName__c = 'Dolly'
            , LastName__c = 'Parton'
            , Email__c = EMAIL
            , Status__c = EventRegistrationService.REGISTRATION_STATUS_REGISTERED
        );

        // when
        EventRegistrationService svc = new EventRegistrationService();
        Exception caught;
        try {
            svc.updateRegistration(EVENT_UUID, registrationTemplate);
        } catch (Exception ex) {
            caught = ex;
        }

        // then
        System.assertNotEquals(null, caught);
        System.assert(caught instanceof EventRegistrationService.RegistrationNotAllowedException, caught.getTypeName());
    }

    @IsTest
    static void markUnregisteredAttendeesNoShow_should_mark_unregistered_registrations_as_no_show() {
        Event__c myEvent = [SELECT Id FROM Event__c];

        // when
        EventRegistrationService svc = new EventRegistrationService();
        svc.markUnregisteredAttendeesNoShow(new List<Id> {myEvent.Id});

        List<EventRegistration__c> results = [
            SELECT Id
            , IsNoShow__c
            FROM EventRegistration__c
            WHERE Status__c = :EventRegistrationService.REGISTRATION_STATUS_INVITED
        ];
        System.assertEquals(2, results.size());
        for (EventRegistration__c result : results) {
            System.assertEquals(true, result.IsNoShow__c);
        }
    }

    @IsTest
    static void fetchRegistrationsByEmail_should_fetch_event_registrations_by_email() {
        EventRegistrationService svc = new EventRegistrationService();
        List<String> emails = new List<String> {EMAIL, EMAIL2};
        List<EventRegistration__c> results = svc.fetchRegistrationsByEmail(new List<String> {EVENT_UUID}, emails);
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
    static void fetchRegistrationsByStatusNotIn_should_fetch_event_registrations_by_status() {
        Event__c myEvent = [SELECT Id FROM Event__c];
        EventRegistrationService svc = new EventRegistrationService();
        List<String> statuses = new List<String> {EventRegistrationService.REGISTRATION_STATUS_REGISTERED};
        List<EventRegistration__c> results = svc.fetchRegistrationsByStatusNotIn(new List<Id> {myEvent.Id}, statuses);
        System.assertEquals(2, results.size());
        // List<String> resultStatuses = (List<String>)SListApi.fromList(results).pluck('Status__c').toList(new List<String>());
        Set<String> resultStatuses = new Set<String>();
        for (EventRegistration__c result : results) {
            resultStatuses.add(result.Status__c);
        }
        System.assertNotEquals(true, resultStatuses.contains(EventRegistrationService.REGISTRATION_STATUS_REGISTERED), resultStatuses);

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