@isTest
public class IntegrationHandlerTest {
    
    @isTest
    public static void testSendRequest() {
        Intapp_Settings__c setting = new Intapp_Settings__c();
        setting.Name = 'All';
        setting.NS_customer_webhook_sbx__c = 'https://test.salesforce.com';
        setting.NS_Customer_webhook_PROD__c = 'https://login.salesforce.com';
        insert setting;
        Test.setMock(HttpCalloutMock.class, new IntegrationHandlerMock());
        Test.startTest();
        boolean actual = IntegrationHandler.IsSandbox();
        String body = '{"CustomerNumber" : "A-0001:18","Subsidiary" : "18"}';
        IntegrationHandler.SendRequest(body);
        Test.stopTest();

        boolean expected = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        System.assertEquals(expected,actual);
    }
}