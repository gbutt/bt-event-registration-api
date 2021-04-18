@IsTest(IsParallel = true)
public class EventRegistrationModelTest {
    @IsTest
    static void it_should_validate_payload_firstName() {
        EventRegistrationModel payload = new EventRegistrationModel();

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
        EventRegistrationModel payload = new EventRegistrationModel();

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
        EventRegistrationModel payload = new EventRegistrationModel();

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