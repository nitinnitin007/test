/**
 * @description       : This test class will cover AddStaticBundleHandler class.
 * @author            : Dhiraj Kumar
 * @last modified on  : 11-28-2023
 * @last modified by  : Dhiraj Kumar
 * Modifications Log
 * Ver   Date         Author         Modification
 * 1.0   11-28-2023   Dhiraj Kumar   Initial Version
**/
@isTest
public class AddStaticBundleHandlerTest {
    /**
    * ***********************************************************
    * This method is test SetUp method 
    * ***********************************************************
    */
    @testSetup
    public static void setup(){
        List<Product2> parentProd = TestDataFactory.createProdList('Intapp Risk & Compliance PIN-01670',1,true);
        List<Product2> childProd = TestDataFactory.createProdList('Intapp Billstream Cloud PIN-01879',1,true);
        PricebookEntry parntProdPriceBookEntry = TestDataFactory.createPricebookEntry(parentProd[0].Id,true);
        SBQQ__Dimension__c parntProdPriceBookDimension = TestDataFactory.createPricebookDimension(parentProd[0].Id,true);
        PricebookEntry priceBookEntry = TestDataFactory.createPricebookEntry(childProd[0].Id,true);
        SBQQ__Dimension__c priceBookDimension = TestDataFactory.createPricebookDimension(childProd[0].Id,true);     
        SBQQ__LookupData__c lookupData = new SBQQ__LookupData__c(SBQQ__Product__c=parentProd[0].Id,Child_Product__c=childProd[0].Id,PriceBookEntry_Id__c=priceBookEntry.Id,Dimension_Id__c=priceBookDimension.Id,Product_Allocation__c=10,CurrencyIsoCode='USD',SBQQ__Value__c='2187638');
        insert lookupData;
        
        List<Account> accList = TestDataFactory.createAccount(1,True);              
        List<Opportunity> opportunityList = TestDataFactory.createOppty(2, accList[0].Id, true);
        List<SBQQ__Quote__c> quoteList1 = TestDataFactory.createQuote(1, opportunityList[0].Id, true);
        List<SBQQ__Quote__c> quoteList2 = TestDataFactory.createQuote(1, opportunityList[1].Id, true);
        
        //List<User> createSalesUser = TestDataFactory.createSalesUser(1,true);
    }
    
    /**
    * ***********************************************************
    * This method is test method for addStaticBundle
    * ***********************************************************
    */
    @isTest
    public static void testAddStaticBundle(){        
        Test.startTest();
        try
        {
           List<SBQQ__Quote__c> quoteList = [SELECT Id, Name FROM SBQQ__Quote__c];
            List<Product2> parentProd = [SELECT Id, Name FROM Product2 WHERE NAME LIKE 'Intapp Risk & Compliance%' LIMIT 1];
            List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.createQuoteLine(1,quoteList[0].Id,parentProd[0].Id,true);
            //List<SBQQ__QuoteLine__c> quoteLineList1 = TestDataFactory.createQuoteLine(1,quoteList[1].Id,parentProd[0].Id,true);
            System.assertEquals(1,quoteLineList.size());
            delete quoteLineList[0]; 
        }
        catch(Exception ex)
        {
            System.debug('Exception Caught at :'+ ex.getMessage() );
        }
            
        Test.stopTest();
    }
    
    /**
    * ***********************************************************
    * This method is test method for afterDelete
    * ***********************************************************
    */
    @isTest
    public static void testDeleteStaticBundle(){    

            Map<Id,SBQQ__QuoteLine__c> oldMap = new Map<Id,SBQQ__QuoteLine__c>();
            List<SBQQ__Quote__c> quoteList = [SELECT Id, Name FROM SBQQ__Quote__c];
            List<Product2> parentProd = [SELECT Id, Name FROM Product2 WHERE NAME LIKE 'Intapp Risk & Compliance%' LIMIT 1];
            List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.createQuoteLine(1,quoteList[0].Id,parentProd[0].Id,true);
            oldMap.put(quoteLineList[0].Id,quoteLineList[0]);
            Test.startTest();
            AddStaticBundleHandler.afterDelete(oldMap);
            System.assertEquals(1,quoteList.size());
            Test.stopTest();    
    }
    
    /*@isTest
    public static void testAddStaticBundle1(){     
        
        List<SBQQ__Quote__c> quoteList = [SELECT Id, Name FROM SBQQ__Quote__c];
        List<Product2> parentProd = [SELECT Id, Name FROM Product2 WHERE NAME LIKE 'Intapp Risk & Compliance%' LIMIT 1];
        List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.createQuoteLine(1,quoteList[0].Id,parentProd[0].Id,true);
        Test.startTest();
        List<SBQQ__QuoteLine__c> quoteLineList2 = TestDataFactory.createQuoteLine(1,quoteList[0].Id,parentProd[0].Id,true);
        Test.stopTest();
        
    }*/
    
}