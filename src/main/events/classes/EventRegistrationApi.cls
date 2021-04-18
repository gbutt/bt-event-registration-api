/**
 * @author Greg Butt
 * @date 2021
 * @group Events
 * @description Public API for Event Registrations.
 * Example URL: https://sandbox-btdev-developer-edition.cs43.force.com/services/apexrest/namespace/events/v1/event
 */
@RestResource(urlMapping ='/events/v1/event/*/register')
global with sharing class EventRegistrationApi {
    // private static final Logger LOG = LoggerFactory.getInstance(EventRegistrationApi.class);

    // package namespace
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

        RequestParameters requestParams = new RequestParameters(req);
        respPayload = new ResponsePayload(requestParams);

        try {
            // parse the payload
            EventRegistrationModel payload = parsePayload(req.requestBody.toString());
            // validate the payload
            List<String> errors = payload.validate();
            if (errors.isEmpty() == false) {
                throw new InvalidDataException(errors);
            }

            String registrationNumber;
            if (requestParams.eventUuid == '_ping') {
                // return pong
                payload.registrationNumber = 'test-uuid-ping';
            } else {
                // complete registration
                payload = updateRegistration(requestParams.eventUuid, payload);
            }
            respPayload.registration = payload;
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

    private static EventRegistrationModel parsePayload(String payloadJsonStr) {
        EventRegistrationModel payload;
        try {
            payload = (EventRegistrationModel)JSON.deserialize(payloadJsonStr, EventRegistrationModel.class);
        } catch (Exception ex) {
            // LOG.error(ex);
            System.debug(LoggingLevel.ERROR, ex);
            throw new InvalidDataException(new List<String> {'Invalid Registration'});
        }
        return payload;
    }

    private static EventRegistrationModel updateRegistration(String eventUuid, EventRegistrationModel payload) {
        EventRegistration__c registrationToUpdate = new EventRegistration__c(
            FirstName__c = payload.firstName
            , LastName__c = payload.lastName
            , Email__c = payload.email
        );
        if (payload.isRegistered) {
            registrationToUpdate.Status__c = EventRegistrationService.REGISTRATION_STATUS_REGISTERED;
        }

        EventRegistrationService.I svc = (EventRegistrationService.I)DependencyBuilder.newInstance(
            EventRegistrationService.class
        );
        EventRegistration__c result = svc.updateRegistration(eventUuid, registrationToUpdate);
        payload.registrationNumber = result.Name;
        return payload;
    }

    /**
     * @description Error thrown when the provided input to the rest service was invalid or missing
     */
    public class InvalidDataException extends Exception {
        public List<String> errors { get; private set; }

        public InvalidDataException(List<String> errors) {
            this.errors = errors;
            String message = String.join(errors, '; ');
            setMessage(message);
        }
    }


    /**
     * @description The provided input parameters to the rest service
     */
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


    /**
     * @description The response payload
     */
    public class ResponsePayload {
        /*******************************************************************************************************
         * @description the request parameters received for this request
         */
        public RequestParameters params { get; private set; }
        /*******************************************************************************************************
         * @description a list of error messages to accompany the error status code
         */
        public List<String> errors { get; set; }
        /*******************************************************************************************************
         * @description the registration data of a successfully registered registrant
         */
        public EventRegistrationModel registration { get; set; }

        public ResponsePayload(RequestParameters params) {
            this.params = params;
            this.errors = new List<String>();
        }
    }
}