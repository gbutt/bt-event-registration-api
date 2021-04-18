@IsTest(IsParallel = true)
public class EventRegistrationApiTest {
    static final String EVENT_UUID = '999';
    static final String REGISTRATION_NUMBER = 'REG-2020-01-01-1234';

    private static EventRegistration__c buildRegistration() {
        EventRegistration__c registration = (EventRegistration__c)TestUtils.setReadOnlyField(new EventRegistration__c(), 'Name', REGISTRATION_NUMBER);
        registration.Event__r = new Event__c(
            Status__c = EventRegistrationService.EVENT_STATUS_OPEN
        );
        return registration;
    }

    private static void setUriNamespace(RestRequest req) {
        if (EventRegistrationApi.NAMESPACE != null) {
            req.requestURI = '/' + EventRegistrationApi.NAMESPACE + req.requestURI;
        }
    }

    @IsTest
    static void it_should_register_valid_payload() {
        // setup - RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        // setup - create a stub for service class
        UniversalMocker stubSvc = UniversalMocker.mock(EventRegistrationService.class);
        DependencyResolver.mockInstance(stubSvc);

        // return registration when load by email is called
        EventRegistration__c registration = buildRegistration();
        System.assertEquals(REGISTRATION_NUMBER, registration.Name);
        stubSvc.when('fetchRegistrationsByEmail').thenReturn(new List<EventRegistration__c> {registration});

        // given - valid request
        RestContext.request.requestURI = String.format(
            '/events/v1/event/{0}/register',
            new List<Object> { EVENT_UUID }
        );
        setUriNamespace(RestContext.request);

        // given - valid payload
        EventRegistrationApi.RequestPayload payload = new EventRegistrationApi.RequestPayload();
        payload.firstName = 'Chuck';
        payload.lastName = 'Jones';
        payload.email = 'chuck.jones@looneytunes.co';
        payload.isRegistered = true;
        System.assertEquals(true, payload.validate().isEmpty(), payload.validate());

        // when
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(payload));
        EventRegistrationApi.doPost();

        // then - service is called with correct parameters
        stubSvc.assertThat().method('fetchRegistrationsByEmail').wasCalledExactly(1);
        Map<String, Object> params = stubSvc.forMethod('fetchRegistrationsByEmail').getArgumentsMap();
        System.assertEquals(EVENT_UUID, (String)params.get('eventuuid'), params);
        System.assertEquals(payload.email, ((List<String>)params.get('emails'))[0], params);

        stubSvc.assertThat().method('updateRegistrations').wasCalledExactly(1);
        params = stubSvc.forMethod('updateRegistrations').getArgumentsMap();
        EventRegistration__c regToUpdate = ((List<EventRegistration__c>)params.get('registrations'))[0];

        System.assertEquals(registration.Id, regToUpdate.Id);
        System.assertEquals(payload.firstName, regToUpdate.FirstName__c);
        System.assertEquals(payload.lastName, regToUpdate.LastName__c);
        System.assertEquals(EventRegistrationService.REGISTRATION_STATUS_REGISTERED, regToUpdate.Status__c);
        List<SObjectField> fieldsToUpdate = (List<SObjectField>)params.get('fieldstoupdate');
        List<SObjectField> expectedFieldsToUpdate = new List<SObjectField> {
            Schema.EventRegistration__c.FirstName__c
            , Schema.EventRegistration__c.LastName__c
            , Schema.EventRegistration__c.Status__c
        };
        System.assertEquals(expectedFieldsToUpdate, fieldsToUpdate);

        // then - response has registrastion number
        System.assertEquals(200, RestContext.response.statusCode);
        String respBodyStr = RestContext.response.responseBody.toString();
        EventRegistrationApi.ResponsePayload response = EventRegistrationApi.respPayload;
        System.assertEquals(JSON.serialize(response), respBodyStr);
        System.assertEquals(REGISTRATION_NUMBER, response.registrationNumber, response);
    }

    @IsTest
    static void it_should_return_400_error_when_payload_is_malformed() {
        // setup - RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        // given - valid request
        RestContext.request.requestURI = String.format(
            '/events/v1/event/{0}/register',
            new List<Object> { EVENT_UUID }
        );
        setUriNamespace(RestContext.request);

        // given - maformed payload
        RestContext.request.requestBody = Blob.valueOf('not json');

        // when
        EventRegistrationApi.doPost();

        // then - response has error
        System.assertEquals(400, RestContext.response.statusCode);
        String respBodyStr = RestContext.response.responseBody.toString();
        EventRegistrationApi.ResponsePayload response = EventRegistrationApi.respPayload;
        System.assertEquals(JSON.serialize(response), respBodyStr);
        System.assertEquals(
            'Invalid Registration',
            response.errors[0]
        );
    }

    @IsTest
    static void it_should_return_400_error_when_payload_is_invalid() {
        // setup - RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        // given - valid request
        RestContext.request.requestURI = String.format(
            '/events/v1/event/{0}/register',
            new List<Object> { EVENT_UUID }
        );
        setUriNamespace(RestContext.request);

        // given - invalid payload
        EventRegistrationApi.RequestPayload payload = new EventRegistrationApi.RequestPayload();
        System.assertEquals(false, payload.validate().isEmpty());
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(payload));

        // when
        EventRegistrationApi.doPost();

        // then - response has error
        System.assertEquals(400, RestContext.response.statusCode);
        String respBodyStr = RestContext.response.responseBody.toString();
        EventRegistrationApi.ResponsePayload response = (EventRegistrationApi.ResponsePayload)JSON.deserialize(
            respBodyStr,
            EventRegistrationApi.ResponsePayload.class
        );
        System.assertEquals(true, response.errors.size() > 0);
    }

    @IsTest
    static void it_should_return_ping() {
        // setup - RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        // setup - create a stub for service class
        UniversalMocker stubSvc = UniversalMocker.mock(EventRegistrationService.class);
        DependencyResolver.mockInstance(stubSvc);
        // return registration id when register is called
        stubSvc.when('fetchRegistrationsByEmail').thenReturn(new List<EventRegistration__c>());

        // given - valid request
        RestContext.request.requestURI = String.format(
            '/events/v1/event/{0}/register',
            new List<Object> { '_ping' }
        );
        setUriNamespace(RestContext.request);

        // given - valid payload
        EventRegistrationApi.RequestPayload payload = new EventRegistrationApi.RequestPayload();
        payload.firstName = 'Chuck';
        payload.lastName = 'Jones';
        payload.email = 'chuck.jones@looneytunes.co';
        payload.isRegistered = true;
        System.assertEquals(true, payload.validate().isEmpty(), payload.validate());

        // when
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(payload));
        EventRegistrationApi.doPost();

        // then - response has error
        System.assertEquals(200, RestContext.response.statusCode);
        String respBodyStr = RestContext.response.responseBody.toString();
        EventRegistrationApi.ResponsePayload response = (EventRegistrationApi.ResponsePayload)JSON.deserialize(
            respBodyStr,
            EventRegistrationApi.ResponsePayload.class
        );
        System.assertEquals(null, response.errors);
        System.assertEquals('test-uuid-ping', response.registrationNumber);
    }

    @IsTest
    static void it_should_return_404_error_when_registration_not_found() {
        // setup - RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        // setup - create a stub for service class
        UniversalMocker stubSvc = UniversalMocker.mock(EventRegistrationService.class);
        DependencyResolver.mockInstance(stubSvc);
        // return registration id when register is called
        stubSvc.when('fetchRegistrationsByEmail').thenReturn(new List<EventRegistration__c>());

        // given - valid request
        RestContext.request.requestURI = String.format(
            '/events/v1/event/{0}/register',
            new List<Object> { EVENT_UUID }
        );
        setUriNamespace(RestContext.request);

        // given - valid payload
        EventRegistrationApi.RequestPayload payload = new EventRegistrationApi.RequestPayload();
        payload.firstName = 'Chuck';
        payload.lastName = 'Jones';
        payload.email = 'chuck.jones@looneytunes.co';
        payload.isRegistered = true;
        System.assertEquals(true, payload.validate().isEmpty(), payload.validate());

        // when
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(payload));
        EventRegistrationApi.doPost();

        // then - response has error
        System.assertEquals(404, RestContext.response.statusCode);
        String respBodyStr = RestContext.response.responseBody.toString();
        EventRegistrationApi.ResponsePayload response = (EventRegistrationApi.ResponsePayload)JSON.deserialize(
            respBodyStr,
            EventRegistrationApi.ResponsePayload.class
        );
        System.assertEquals('Registration not found', response.errors[0]);
    }

    @IsTest
    static void it_should_return_405_error_when_event_registration_is_not_open() {
        // setup - RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        // setup - create a stub for service class
        UniversalMocker stubSvc = UniversalMocker.mock(EventRegistrationService.class);
        DependencyResolver.mockInstance(stubSvc);
        // return registration id when register is called
        EventRegistration__c registration = new EventRegistration__c(Event__r = new Event__c(Status__c = EventRegistrationService.EVENT_STATUS_CLOSED));
        stubSvc.when('fetchRegistrationsByEmail').thenReturn(new List<EventRegistration__c> {registration});

        // given - valid request
        RestContext.request.requestURI = String.format(
            '/events/v1/event/{0}/register',
            new List<Object> { EVENT_UUID }
        );
        setUriNamespace(RestContext.request);

        // given - valid payload
        EventRegistrationApi.RequestPayload payload = new EventRegistrationApi.RequestPayload();
        payload.firstName = 'Chuck';
        payload.lastName = 'Jones';
        payload.email = 'chuck.jones@looneytunes.co';
        payload.isRegistered = true;
        System.assertEquals(true, payload.validate().isEmpty(), payload.validate());

        // when
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(payload));
        EventRegistrationApi.doPost();

        // then - response has error
        System.assertEquals(405, RestContext.response.statusCode);
        String respBodyStr = RestContext.response.responseBody.toString();
        EventRegistrationApi.ResponsePayload response = (EventRegistrationApi.ResponsePayload)JSON.deserialize(
            respBodyStr,
            EventRegistrationApi.ResponsePayload.class
        );
        System.assertEquals('Event registration is not open', response.errors[0]);

        stubSvc.assertThat().method('fetchRegistrationsByEmail').wasCalledExactly(1);
    }

    @IsTest
    static void it_should_return_500_error_when_service_fails() {
        // setup - RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        // setup - create a stub for service class
        UniversalMocker stubSvc = UniversalMocker.mock(EventRegistrationService.class);
        DependencyResolver.mockInstance(stubSvc);
        // return registration id when register is called
        stubSvc.when('fetchRegistrationsByEmail').thenThrow(new GeneralException('panic!'));

        // given - valid request
        RestContext.request.requestURI = String.format(
            '/events/v1/event/{0}/register',
            new List<Object> { EVENT_UUID }
        );
        setUriNamespace(RestContext.request);

        // given - valid payload
        EventRegistrationApi.RequestPayload payload = new EventRegistrationApi.RequestPayload();
        payload.firstName = 'Chuck';
        payload.lastName = 'Jones';
        payload.email = 'chuck.jones@looneytunes.co';
        payload.isRegistered = true;
        System.assertEquals(true, payload.validate().isEmpty(), payload.validate());

        // when
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(payload));
        EventRegistrationApi.doPost();

        // then - response has error
        System.assertEquals(500, RestContext.response.statusCode);
        String respBodyStr = RestContext.response.responseBody.toString();
        EventRegistrationApi.ResponsePayload response = EventRegistrationApi.respPayload;
        System.assertEquals(JSON.serialize(response), respBodyStr);
        System.assertEquals('Unknown error', response.errors[0]);
    }

    @IsTest
    static void it_should_parse_event_uuid_from_path() {
        // given

        RestRequest req = new RestRequest();
        req.requestURI = '/events/v1/event/123/register';
        setUriNamespace(req);

        // when
        EventRegistrationApi.RequestParameters result = new EventRegistrationApi.RequestParameters(
            req
        );

        // then
        System.assertEquals('123', result.eventUuid);
    }

    @IsTest
    static void it_should_validate_payload_firstName() {
        EventRegistrationApi.RequestPayload payload = new EventRegistrationApi.RequestPayload();

        // when
        List<String> errors = payload.validate();

        // then
        System.assertEquals(true, errors.indexOf('firstName is required') > -1);

        // when
        payload.firstName = '';
        errors = payload.validate();

        // then
        System.assertEquals(true, errors.indexOf('firstName is required') > -1);

        // when
        payload.firstName = ' ';
        errors = payload.validate();

        // then
        System.assertEquals(true, errors.indexOf('firstName is required') > -1);

        // when
        payload.firstName = 'test';
        errors = payload.validate();

        // then
        System.assertEquals(-1, errors.indexOf('firstName is required'));
    }

    @IsTest
    static void it_should_validate_payload_lastName() {
        EventRegistrationApi.RequestPayload payload = new EventRegistrationApi.RequestPayload();

        // when
        List<String> errors = payload.validate();

        // then
        System.assertEquals(true, errors.indexOf('lastName is required') > -1);

        // when
        payload.lastName = '';
        errors = payload.validate();

        // then
        System.assertEquals(true, errors.indexOf('lastName is required') > -1);

        // when
        payload.lastName = ' ';
        errors = payload.validate();

        // then
        System.assertEquals(true, errors.indexOf('lastName is required') > -1);

        // when
        payload.lastName = 'test';
        errors = payload.validate();

        // then
        System.assertEquals(-1, errors.indexOf('lastName is required'));
    }

    @IsTest
    static void it_should_validate_payload_email() {
        EventRegistrationApi.RequestPayload payload = new EventRegistrationApi.RequestPayload();

        // when
        List<String> errors = payload.validate();

        // then
        System.assertEquals(true, errors.indexOf('email is required') > -1);

        // when
        payload.email = '';
        errors = payload.validate();

        // then
        System.assertEquals(true, errors.indexOf('email is required') > -1);

        // when
        payload.email = ' ';
        errors = payload.validate();

        // then
        System.assertEquals(true, errors.indexOf('email is required') > -1);

        // when
        payload.email = 'test';
        errors = payload.validate();

        // then
        System.assertEquals(-1, errors.indexOf('email is required'));
    }
}