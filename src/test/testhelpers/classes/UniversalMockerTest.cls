@IsTest
public class UniversalMockerTest {
    @IsTest
    static void it_should_mock_method_on_class() {
        // setup - create a mock instance of our test service
        UniversalMocker mock = UniversalMocker.mock(UniversalMockerTestService.class);

        // setup - mock method 'generateRandomKey' and have it return a known value
        mock.when('generateRandomKey').thenReturn('123');

        // when
        UniversalMockerTestService svc = (UniversalMockerTestService) mock.createStub();
        String result = svc.generateRandomKey(128);

        // then - assert mocked value is returned
        System.assertEquals('123', result);

        // then - assert the method was called as expected
        mock.assertThat().method('generateRandomKey').wasCalled();
        Integer sizeParam = (Integer) mock.forMethod('generateRandomKey').getValueOf('size');
        System.assertEquals(128, sizeParam);
    }
}
