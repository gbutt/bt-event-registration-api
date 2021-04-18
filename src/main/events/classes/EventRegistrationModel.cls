/**
 * @author Greg Butt
 * @date 2021
 * @group Events
 * @description an event registration
 */
public with sharing class EventRegistrationModel {
    public String registrationNumber {get; set;}
    public String firstName {get; set;}
    public String lastName {get; set;}
    public String email {get; set;}
    public Boolean isRegistered {get; set;}

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