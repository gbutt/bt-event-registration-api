@IsTest(IsParallel = true)
public class EventDomainTest {
    private static final String EVENT_UUID = 'event-uuid-123';

    @TestSetup
    static void makeData() {
        Event__c event = new Event__c(
            Name = 'Test Event'
            , Uuid__c = EVENT_UUID
            , Status__c = EventRegistrationService.EVENT_STATUS_NEW
        );
        insert event;
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
        // setup - create a stub for service class
        UniversalMocker stubSvc = UniversalMocker.mock(EventRegistrationService.class);
        DependencyBuilder.cacheInstance(EventRegistrationService.class, stubSvc.createStub());

        // when
        Event__c myEvent = [SELECT Id FROM Event__c];
        myEvent.Status__c = EventRegistrationService.EVENT_STATUS_COMPLETED;
        update myEvent;

        // then
        stubSvc.assertThat().method('markUnregisteredAttendeesNoShow').wasCalledExactly(1);
        List<Id> eventIds = (List<Id>)stubSvc.forMethod('markUnregisteredAttendeesNoShow').getValueOf('eventids');
        System.assertEquals(new List<Id> {myEvent.Id}, eventIds);
    }

    @IsTest
    static void it_should_not_mark_no_shows_when_event_already_completed() {
        // setup - create a stub for service class
        UniversalMocker stubSvc = UniversalMocker.mock(EventRegistrationService.class);
        DependencyBuilder.cacheInstance(EventRegistrationService.class, stubSvc.createStub());

        Event__c myEvent = [SELECT Id FROM Event__c];
        myEvent.Status__c = EventRegistrationService.EVENT_STATUS_COMPLETED;

        EventDomain domain = new EventDomain(new List<Event__c> {myEvent}, new Map<Id, Event__c> {myEvent.Id => myEvent}, new Map<Id, Event__c> {myEvent.Id => myEvent}, TriggerOperation.AFTER_UPDATE);
        domain.execute();

        // then
        stubSvc.assertThat().method('markUnregisteredAttendeesNoShow').wasNeverCalled();
    }
}