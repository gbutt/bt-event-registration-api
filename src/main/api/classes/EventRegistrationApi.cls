// https://sandbox-btdev-developer-edition.cs43.force.com/services/apexrest/gbutt/events/v1/event
@RestResource(urlMapping ='/events/v1/event/*/register')
global with sharing class EventRegistrationApi {
    // private static final Logger LOG = LoggerFactory.getInstance(EventRegistrationApi.class);
    @TestVisible
    private static final String NAMESPACE = PackageUtils.getNamespaceFromClass(
        EventRegistrationApi.class
    );
    private static final Pattern REGISTRATION_UUID_REGEX = Pattern.compile(
        String.format('/{0}/events/v1/event/(.*)/register', new List<String> { NAMESPACE })
    );

    @TestVisible
    private static ResponsePayload respPayload { get; set; }

    // create a new registration
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse resp = RestContext.response;
        respPayload = new ResponsePayload();

        RequestParameters requestParams = new RequestParameters(req);
        respPayload.setParams(requestParams);

        try {
            // parse the payload
            RequestPayload payload = parsePayload(req.requestBody.toString());
            // validate the payload
            List<String> errors = payload.validate();
            if (errors.isEmpty() == false) {
                throw new InvalidDataException(errors);
            }
            // complete registration
            String registrationNumber;
            // check for test event uuid
            if (requestParams.eventUuid == '_ping') {
                registrationNumber = 'test-uuid-ping';
            } else {
                registrationNumber = updateRegistration(requestParams.eventUuid, payload);
            }
            respPayload.registrationNumber = registrationNumber;
            resp.statusCode = 200;
        } catch (InvalidDataException ex) {
            resp.statusCode = 400;
            respPayload.errors = ex.errors;
        } catch (RegistrationNotAllowedException ex) {
            resp.statusCode = 405;
            respPayload.errors = new List<String> { 'Event registration is not open' };
        } catch (RegistrationNotFoundException ex) {
            resp.statusCode = 404;
            respPayload.errors = new List<String> { 'Registration not found' };
        } catch (Exception ex) {
            // LOG.error(ex);
            System.debug(LoggingLevel.ERROR, ex);
            resp.statusCode = 500;
            respPayload.errors = new List<String> { 'Unknown error' };
        }

        resp.addHeader('Content-Type', 'application/json');
        resp.responseBody = Blob.valueOf(JSON.serialize(respPayload));
    }

    private static RequestPayload parsePayload(String payloadJsonStr) {
        RequestPayload payload;
        try {
            payload = (RequestPayload)JSON.deserialize(payloadJsonStr, RequestPayload.class);
        } catch (Exception ex) {
            // LOG.error(ex);
            System.debug(LoggingLevel.ERROR, ex);
            throw new InvalidDataException(new List<String> {'Invalid Registration'});
        }
        return payload;
    }

    private static String updateRegistration(String eventUuid, RequestPayload payload) {
        EventRegistrationService svc = (EventRegistrationService)DependencyResolver.getInstance(
            EventRegistrationService.class
        );
        List<EventRegistration__c> foundRegistrations = svc.fetchRegistrationsByEmail(
            eventUuid,
            new List<String> {payload.email}
        );
        if (foundRegistrations.size() == 0) {
            throw new RegistrationNotFoundException();
        }
        EventRegistration__c registration = foundRegistrations[0];
        if (registration.Event__r.Status__c != EventRegistrationService.EVENT_STATUS_OPEN) {
            throw new RegistrationNotAllowedException();
        }

        EventRegistration__c registrationToUpdate = new EventRegistration__c(
            Id = registration.Id
            , FirstName__c = payload.firstName
            , LastName__c = payload.lastName
        );

        if (payload.isRegistered) {
            registrationToUpdate.Status__c = EventRegistrationService.REGISTRATION_STATUS_REGISTERED;
        }
        List<SObjectField> fieldsToUpdate = new List<SObjectField> {
            Schema.EventRegistration__c.FirstName__c
            , Schema.EventRegistration__c.LastName__c
            , Schema.EventRegistration__c.Status__c
        };
        svc.updateRegistrations(new List<EventRegistration__c> {registrationToUpdate}, fieldsToUpdate);
        return registration.Name;
    }

    public class InvalidDataException extends Exception {
        public List<String> errors { get; private set; }

        public InvalidDataException(List<String> errors) {
            this.errors = errors;
            String message = String.join(errors, '; ');
            setMessage(message);
        }
    }

    public class RegistrationNotAllowedException extends Exception {
    }
    public class RegistrationNotFoundException extends Exception {
    }

    public class RequestParameters {
        public String eventUuid { get; private set; }

        public RequestParameters(RestRequest req) {
            String requestPath = req.requestURI;
            Matcher regexMatcher = REGISTRATION_UUID_REGEX.matcher(requestPath);
            if (regexMatcher.matches()) {
                this.eventUuid = regexMatcher.group(1);
            }
        }
    }

    global class RequestPayload {
        global String firstName;
        global String lastName;
        global String email;
        global Boolean isRegistered;

        public List<String> validate() {
            List<String> errors = new List<String>();
            if (String.isBlank(this.firstName)) {
                errors.add('firstName is required');
            }
            if (String.isBlank(this.lastName)) {
                errors.add('lastName is required');
            }
            if (String.isBlank(this.email)) {
                errors.add('email is required');
            }
            return errors;
        }
    }

    public class ResponsePayload {
        public RequestParameters params { get; set; }
        public List<String> errors { get; set; }
        public String registrationNumber { get; set; }

        public void setParams(RequestParameters requestParams) {
            this.params = requestParams;
        }
    }
}