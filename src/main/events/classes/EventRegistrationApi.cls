/**
 * @author Greg Butt
 * @date 2021
 *
 * @group Events
 *
 * @description Public API for Event Registrations.
 * Example URL: https://sandbox-btdev-developer-edition.cs43.force.com/services/apexrest/namespace/events/v1/event
 */
@RestResource(urlMapping ='/events/v1/event/*/register')
global with sharing class EventRegistrationApi {
    // private static final Logger LOG = LoggerFactory.getInstance(EventRegistrationApi.class);
    @TestVisible
    private static final String NAMESPACE;
    private static final Pattern REGISTRATION_UUID_REGEX;

    static {
        NAMESPACE = PackageUtils.getNamespaceFromClass(EventRegistrationApi.class);

        String regexPattern = '/events/v1/event/(.*)/register';
        if (NAMESPACE != null) {
            regexPattern = '/' + NAMESPACE + regexPattern;
        }
        REGISTRATION_UUID_REGEX = Pattern.compile(regexPattern);
    }

    @TestVisible
    private static ResponsePayload respPayload { get; set; }

    // update registration
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

            String registrationNumber;
            if (requestParams.eventUuid == '_ping') {
                // check for ping
                registrationNumber = 'test-uuid-ping';
            } else {
                // complete registration
                registrationNumber = updateRegistration(requestParams.eventUuid, payload);
            }
            respPayload.registrationNumber = registrationNumber;
            resp.statusCode = 200;
        } catch (InvalidDataException ex) {
            resp.statusCode = 400;
            respPayload.errors = ex.errors;
        } catch (EventRegistrationService.RegistrationNotAllowedException ex) {
            resp.statusCode = 405;
            respPayload.errors = new List<String> { 'Event registration is not open' };
        } catch (EventRegistrationService.RegistrationNotFoundException ex) {
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
        EventRegistration__c registrationToUpdate = new EventRegistration__c(
            FirstName__c = payload.firstName
            , LastName__c = payload.lastName
            , Email__c = payload.email
        );

        if (payload.isRegistered) {
            registrationToUpdate.Status__c = EventRegistrationService.REGISTRATION_STATUS_REGISTERED;
        }
        EventRegistrationService svc = (EventRegistrationService)DependencyResolver.getInstance(
            EventRegistrationService.class
        );
        EventRegistration__c result = svc.updateRegistration(eventUuid, registrationToUpdate);
        return result.Name;
    }

    public class InvalidDataException extends Exception {
        public List<String> errors { get; private set; }

        public InvalidDataException(List<String> errors) {
            this.errors = errors;
            String message = String.join(errors, '; ');
            setMessage(message);
        }
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