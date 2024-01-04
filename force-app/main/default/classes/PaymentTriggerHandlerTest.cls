@isTest
public class PaymentTriggerHandlerTest {
    @testSetup
    static void setup(){
        Account acc = IntappTestObjectFactory.createAccount(true);
        
        blng__Payment__c newPayment = IntappTestObjectFactory.createPayment();
        newPayment.blng__Account__c = acc.Id;
        newPayment.blng__Amount__c = 123;
        newPayment.CurrencyIsoCode = 'USD';
        insert newPayment;
    }
    
    @isTest static void setup1(){
        List<Account> acclist = [Select id,Industry,BillingCountry,OP4I_Sales_Segment__c From Account where OP4I_Sales_Segment__c != ''];
        List<blng__Payment__c> paylist =[Select id,name,blng__Account__c,blng__Amount__c,CurrencyIsoCode From blng__Payment__c];
        update paylist;
        
        System.assertNotEquals(paylist.size(), null);
    }
}