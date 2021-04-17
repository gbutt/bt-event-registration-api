@IsTest
public class UniversalMockerTestService {
    public UniversalMockerTestService() {
    }

    public String generateRandomKey(Integer size) {
        return Crypto.generateAesKey(size).toString();
    }
}
