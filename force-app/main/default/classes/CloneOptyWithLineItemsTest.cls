/**
 * @description       : This test class will cover CloneOptyWithLineItems class.
 * @author            : Pankaj Kumar
 * @last modified on  : 09-21-2023
 * @last modified by  : Pankaj Kumar
 * Modifications Log
 * Ver   Date         Author         Modification
 * 1.0   07-07-2023   Pankaj Kumar   Initial Version
**/
@isTest
public class CloneOptyWithLineItemsTest {
   
    @testSetup
    public static void setup(){
        List<Account> createAccountsList = TestDataFactory.createAccount(1,true);
        List<Opportunity> createOpptyList = TestDataFactory.createOppty(1,createAccountsList[0].id,true);
        Id pricebookId = Test.getStandardPricebookId();
        List<SBQQ__Quote__c> createQuoteList = TestDataFactory.createQuote(1,createOpptyList[0].id,false);
        /*createQuoteList[0].SBQQ__SubscriptionTerm__c=36;
        createQuoteList[0].SBQQ__Primary__c=true;
        //createQuoteList[0].SBQQ__BillingFrequency__c='Annual';
        createQuoteList[0].SBQQ__ProrationDayOfMonth__c='5';*/
        createQuoteList[0].SBQQ__Primary__c=true;
        createQuoteList[0].SBQQ__BillingFrequency__c='Annual';
        createQuoteList[0].SBQQ__PricebookId__c=pricebookId;
        insert createQuoteList;
        List<Product2> productList = TestDataFactory.createProduct(1,true);        
        /*productList[0].SBQQ__ChargeType__c = 'Recurring';
        productList[0].SBQQ__BillingType__c='Advance';
        productList[0].SBQQ__BillingFrequency__c='Annual';
        productList[0].blng__BillingRule__c='aGfD70000000AVCKA2';
        productList[0].blng__RevenueRecognitionRule__c='aHPD70000008PaNOAU';
        productList[0].blng__TaxRule__c='aHXD700000000VWOAY';
        productList[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        productList[0].SBQQ__SubscriptionTerm__c=1;
        productList[0].SBQQ__SubscriptionBase__c='List';
        productList[0].SBQQ__SubscriptionType__c='Renewable';
        productList[0].SBQQ__ConfigurationType__c='Required';*/
            
        PricebookEntry createPricebookEntry= TestDataFactory.createPricebookEntry(productList[0].id,true);
        SBQQ__Dimension__c createPricebookDimension= TestDataFactory.createPricebookDimension(productList[0].id,true);
        List<SBQQ__QuoteLine__c> createQuoteLineList = TestDataFactory.createQuoteLine(5,createQuoteList[0].id,productList[0].id,false);
        createQuoteLineList[0].SBQQ__PricebookEntryId__c=createPricebookEntry.Id;
        insert createQuoteLineList;
    }
    @isTest
    public static void testOptyClosedWon(){
        List<Opportunity> opList = [Select Id,StageName From Opportunity Limit 1];
        List<SBQQ__Quote__c> qlList = [Select Id,Quote_Stage__c From SBQQ__Quote__c Limit 1];
        Test.startTest();        
        //qlList[0].Quote_Stage__c='Contract Executed';
        //update qlList;
        List<Id> newId= new List<Id>();
        newId.add(opList[0].id);
        CloneOptyWithLineItems.cloneOpp(newId);
        Test.stopTest();        
        List<Opportunity> clonedOpp = [Select id,Related_Opportunity__c from Opportunity where Related_Opportunity__c=:opList[0].id];
        System.assertEquals(clonedOpp.size()==1,true);
    }
}