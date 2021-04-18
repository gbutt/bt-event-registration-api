@IsTest(IsParallel = true)
public class EventDomainTest {
    private static final String EVENT_UUID = 'event-uuid-123';
    private static final String EMAIL = 'dolly@dollyparton.com';
    private static final String EMAIL2 = 'david@attenboroughfilm.com';
    private static final String EMAIL3 = 'morgan.freeman@gmail.com';

    @TestSetup
    static void makeData() {
        Event__c event = new Event__c(
            Name = 'Test Event'
            , Uuid__c = EVENT_UUID
            , Status__c = EventRegistrationService.EVENT_STATUS_NEW
        );
        EventRegistration__c registration = new EventRegistration__c(
            FirstName__c = 'Dolly'
            , LastName__c = 'Parton'
            , Email__c = EMAIL
            , IsNoShow__c = false
            , Status__c = EventRegistrationService.REGISTRATION_STATUS_INVITED
            , Event__r = new Event__c(Uuid__c = EVENT_UUID)
        );
        EventRegistration__c registration2 = new EventRegistration__c(
            FirstName__c = 'David'
            , LastName__c = 'Attenborough'
            , Email__c = EMAIL2
            , IsNoShow__c = false
            , Status__c = EventRegistrationService.REGISTRATION_STATUS_INVITED
            , Event__r = new Event__c(Uuid__c = EVENT_UUID)
        );
        EventRegistration__c registration3 = new EventRegistration__c(
            FirstName__c = 'Morgan'
            , LastName__c = 'Freeman'
            , Email__c = EMAIL3
            , IsNoShow__c = false
            , Status__c = EventRegistrationService.REGISTRATION_STATUS_REGISTERED
            , Event__r = new Event__c(Uuid__c = EVENT_UUID)
        );
        insert new List<SObject> {event, registration, registration2, registration3};
    }

    @IsTest
    static void it_should_generate_uuid_when_null() {
        Event__c myEvent = [SELECT Id, Uuid__c FROM Event__c];
        System.assertNotEquals(null, myEvent.Uuid__c);

        myEvent = new Event__c(
            Id = myEvent.Id
            , Name = 'Test Event'
            , Uuid__c = null
        );

        EventDomain domain = new EventDomain(new List<Event__c> {myEvent}, null, null, TriggerOperation.BEFORE_INSERT);
        domain.execute();

        System.assertNotEquals(null, myEvent.Uuid__c);

        myEvent.Uuid__c = null;
        domain = new EventDomain(new List<Event__c> {myEvent}, new Map<Id, Event__c> {myEvent.Id => myEvent}, new Map<Id, Event__c> {myEvent.Id => myEvent}, TriggerOperation.BEFORE_UPDATE);
        domain.execute();

        System.assertNotEquals(null, myEvent.Uuid__c);
    }

    @IsTest
    static void it_should_mark_invited_registrations_no_show_when_completed() {
        Event__c myEvent = [SELECT Id FROM Event__c];
        myEvent.Status__c = EventRegistrationService.EVENT_STATUS_COMPLETED;
        update myEvent;

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
    static void it_should_not_mark_no_shows_when_event_already_completed() {
        Event__c myEvent = [SELECT Id FROM Event__c];
        myEvent.Status__c = EventRegistrationService.EVENT_STATUS_COMPLETED;

        EventDomain domain = new EventDomain(new List<Event__c> {myEvent}, new Map<Id, Event__c> {myEvent.Id => myEvent}, new Map<Id, Event__c> {myEvent.Id => myEvent}, TriggerOperation.AFTER_UPDATE);
        domain.execute();

        List<EventRegistration__c> results = [
            SELECT Id
            , IsNoShow__c
            FROM EventRegistration__c
            WHERE Status__c = :EventRegistrationService.REGISTRATION_STATUS_INVITED
        ];
        System.assertEquals(2, results.size());
        for (EventRegistration__c result : results) {
            System.assertEquals(false, result.IsNoShow__c);
        }
    }
}