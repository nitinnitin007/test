/**
 * @description       : Test class for SingleQuoteSingleDealController
 * @author            : Keerthan N
 * Jira story : BIZ-45097,BIZ-46504
**/
@isTest
public class SingleQuoteSingleDealControllerTest {
    
    @testSetup
    public static void setup(){
        List<Account> accList = TestDataFactory.createAccount(1,True);
    }
    
    @istest
    private static void checkAndCreateQuoteTest(){
        List<Account> accList = [Select Id,Name From Account Limit 1];
        Test.startTest();
        SingleQuoteSingleDealController.checkAndCreateQuote('deal123',accList[0].Id,'New_Software','USD','Y');
        SingleQuoteSingleDealController.checkAndCreateQuote('deal123',accList[0].Id,'New_Software','USD','Y');
        SingleQuoteSingleDealController.checkAndCreateQuote('test123','deal123','New_Software','USD','Y');
        Test.stopTest();
        List<Opportunity> oppList = [Select Id,Name From Opportunity Limit 1];
        List<SBQQ__Quote__c> quoteList = [Select Id,Name From SBQQ__Quote__c Limit 1];
        Assert.isTrue(quoteList.size() > 0, 'Quote Inserted');
    }
    @istest
    private static void checkAndCreateQuoteUpdateTest(){
        List<Account> accList = [Select Id,Name From Account Limit 1];
        Test.startTest();
        SingleQuoteSingleDealController.checkAndCreateQuote('deal123',accList[0].Id,'New_Software','','N');
        SingleQuoteSingleDealController.checkAndCreateQuote('deal123',accList[0].Id,'Renewal','','N');
        Test.stopTest();
        List<SBQQ__Quote__c> quoteList = [Select Id,Name, Deal_Type__c From SBQQ__Quote__c Limit 1];
        Assert.isTrue(quoteList.size() > 0, 'Quote Inserted');
        Assert.areEqual('Renewal', quoteList[0].Deal_Type__c);
    }
}