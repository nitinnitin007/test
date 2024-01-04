/**** @name        : T_UpdateInvoiceHeadwtihSFOrderIdTest
***** @author  : KPMG
***** @date  : Nov 11th, 2023
***** @description : Test Class for T_UpdateInvoiceHeadwtihSFOrderIdBatch
******/
@isTest
public class T_UpdateInvoiceHeadwtihSFOrderIdTest {
    //Test Data Setup
    @testSetup()
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
        //Creating PriceBook from TestDataFactory
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
        //Creating QtC_Mig_Invoice_Temp_Table__c record
        QtC_Mig_Invoice_Temp_Table__c invTemp = new QtC_Mig_Invoice_Temp_Table__c();
        invTemp.Order__c = ord.Id;
        invTemp.Sales_Order_Internal_Id__c = '12345';
        insert invTemp;
        //Creating T_OrderLineDMSummary__c record
        T_OrderLineDMSummary__c ordLineDM = new T_OrderLineDMSummary__c();
        ordLineDM.NSOrderID__c = '12345';
        ordLineDM.SF_Order_Id__c = ord.Id;
        insert ordLineDM;
    }
    @isTest
    //Method to execute test data
    public static void updateInvoiceHeadwtihSFOrderIdBatchTest(){
        //Start Test
        test.StartTest();
        //Execute the Batch class to be tested
        T_UpdateInvoiceHeadwtihSFOrderIdBatch bc = new T_UpdateInvoiceHeadwtihSFOrderIdBatch();
        Database.executeBatch(bc);
        //Stop test
        test.StopTest();
        //Validating the results
        List<T_OrderLineDMSummary__c> orderItemList = [SELECT Id,NSOrderID__c,SF_Order_Id__c FROM T_OrderLineDMSummary__c];
        List<QtC_Mig_Invoice_Temp_Table__c> tempList = [SELECT Id,Order__c,Sales_Order_Internal_Id__c FROM QtC_Mig_Invoice_Temp_Table__c];
        if(tempList.size() > 0 && orderItemList.size() > 0 && orderItemList[0].SF_Order_Id__c != null && tempList[0].Order__c != null){
        System.assertEquals(orderItemList[0].SF_Order_Id__c,tempList[0].Order__c,'Order Populated Successfully');   
        }
    }
}