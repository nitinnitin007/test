/**
 * @description       : Test class for QuoteSaveAndForecastController
 * @author            : Kesav Das
 * Jira story : BIZ-45100
**/
@isTest
private class QuoteSaveAndForecastControllerTest {

@testsetup
public static void testsetup(){
    List<Account> createdAccountsList = TestDataFactory.createAccount(1,true);
    List<Opportunity> createOpptyList = TestDataFactory.createOppty(1,createdAccountsList[0].id,true);
    List<SBQQ__Quote__c> createQuoteList = TestDataFactory.createQuote(1,createOpptyList[0].id,true);
    List<Product2> productList = TestDataFactory.createProduct(1,true);
    List<SBQQ__QuoteLine__c> createQuoteLineList = TestDataFactory.createQuoteLine(1,createQuoteList[0].id,productList[0].id,true);
}

@isTest
static void testUpdateQuote() {
    SBQQ__Quote__c testQuote = [SELECT Id, Quote_Stage__c, OP4I_Status__c, SBQQ__LineItemCount__c FROM SBQQ__Quote__c limit 1];
    Test.startTest();
    QuoteSaveAndForecastController.updateQuote(testQuote.Id);
    testQuote.Quote_Stage__c= System.Label.Configure_Products;
    update testQuote;
    QuoteSaveAndForecastController.updateQuote(testQuote.Id);
    Assert.isTrue(testQuote.Quote_Stage__c == System.Label.Configure_Products, 'Quote Updated');
    Test.stopTest();
}

}