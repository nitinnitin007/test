/****  Name :T_UpdateOrderLineSummaryBatchTest
***** Created By : KPMG
***** Created On : Nov 11th, 2023
***** Description : Test Class to check - T_UpdateOrderLineSummaryBatch
******/
@isTest
public class T_UpdateOrderLineSummaryBatchTest {
    //Test Data Setup
    @testSetup
    public static void setupData(){
        //Creating Account
        Account  acc = new Account();
        acc.Name = 'Service Billing Testing 10/30';
        insert acc;
        //Creating Opp from Test Data Factory
        List<opportunity> oppList = TestDataFactory.createOppty(1,acc.Id,True);
        //Creating Quote from TestData Factory
        List<SBQQ__Quote__c> quoteList = TestDataFactory.createQuote(1,oppList[0].Id,True);
        //Creating Product from Test Data Factory
        List<Product2> prodList = TestDataFactory.createProduct(1,True);
        //Creating PrizeBook from TestDataFactory
        PricebookEntry pbEntry = TestDataFactory.createPricebookEntry(prodList[0].Id,true);
        pbEntry.UnitPrice = 100;
        update pbEntry;
        //Creating Dimension from TestDataFactory
        SBQQ__Dimension__c dim = TestDataFactory.createPricebookDimension(prodList[0].Id,true);
        //Creating QuoteLine from TestDataFactory
        List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.createQuoteLine(1,quoteList[0].Id,prodList[0].Id,true);
        //Creating order record
        Order ord = new Order();
        ord.AccountId = acc.id;
        ord.OpportunityId = oppList[0].Id;
        ord.EffectiveDate = system.today();
        ord.Status = 'Draft';
        ord.blng__BillingDayOfMonth__c = '1';
        ord.Pricebook2Id = pbEntry.Pricebook2Id;
        insert ord;
        //Creating Orderitem record
        OrderItem ordItem = new OrderItem();
        ordItem.Product2Id = prodList[0].Id;
        ordItem.OrderId = ord.Id;
        //ordItem.OrderId = '1234';
        ordItem.Quantity = 1; 
        ordItem.ServiceDate = system.today();
        ordItem.EndDate = system.today()+10;
        ordItem.SBQQ__ChargeType__c = 'Recurring';
        ordItem.PricebookEntryId = pbEntry.Id;
        system.debug('ordItem: ' + ordItem);
        insert ordItem;
        //Creating OrderLine DM Summary
        T_OrderLineDMSummary__c ordLineSummary = new T_OrderLineDMSummary__c();
        ordLineSummary.NS_AccountId__c =  acc.IntApp_Account_Number__c ;
        ordLineSummary.NS_OrderLine_Item__c = 'BU-01670-2';
        ordLineSummary.Quantity__c = 1;
        ordLineSummary.OL_StartDate__c = system.today();
        ordLineSummary.OL_End_Date__c = system.today()+10;
        ordLineSummary.SF_Order_Id__c = ord.Id;
        ordLineSummary.SF_OrderProduct_Id__c = ordItem.Id;
        insert ordLineSummary;
    }        
    @istest
    //Method to execute the test data
    public static void execute(){
        //Start Test
        Test.startTest();
        //Executing the method to be tested
        T_UpdateOrderLineSummaryBatch bc = new T_UpdateOrderLineSummaryBatch();
        Id batchId = Database.executeBatch(bc);
        System.assert(batchId!=null);
        //Stop test
        Test.stopTest();
    }
    
}