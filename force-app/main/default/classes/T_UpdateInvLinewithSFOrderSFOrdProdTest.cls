/**** @name        : T_UpdateInvLinewithSFOrderSFOrdProdTest
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Test Class to check - T_UpdateInvLinewithSFOrderSFOrdProdBatch
******/
@isTest
public class T_UpdateInvLinewithSFOrderSFOrdProdTest {
@testSetup
    //Test Data Setup
    public static void setupData(){
        //Creating Account
        List<Account> accList = TestDataFactory.createAccount(1,True);
        //Creating Opportunity
        List<opportunity> oppList = TestDataFactory.createOppty(1,accList[0].Id,True);
        //Creating Quote
        List<SBQQ__Quote__c> quoteList = TestDataFactory.createQuote(1,oppList[0].Id,True);
        //Billing rule
        blng__BillingRule__c blngRule = new blng__BillingRule__c();
        blngRule.Name = 'Test';
        blngRule.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
        blngRule.blng__PartialPeriodTreatment__c = 'Separate';
        blngRule.blng__PeriodTreatmentForBTDO__c = 'Separate';
        blngRule.blng__GenerateInvoices__c = 'Yes';
        blngRule.blng__Active__c = True;
        insert blngRule;
        //Creating Tax Rule
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Test';
        taxRule.blng__Active__c = True;
        taxRule.blng__TaxableYesNo__c ='No';
        insert taxRule;
        //Revenue Recog Rule
        blng__RevenueRecognitionRule__c revRecogRule = new blng__RevenueRecognitionRule__c();
        revRecogRule.blng__Active__c = true;
        revRecogRule.blng__CreateRevenueSchedule__c = 'No';
        insert revRecogRule;
        //Creating Billing Finance Book
        blng__FinanceBook__c financeBook = new blng__FinanceBook__c();
        financeBook.blng__FinancePeriodDuration__c = 'Monthly';
        financeBook.Name = 'Test';
        financeBook.blng__PeriodType__c = 'Accounting';
        financeBook.blng__Active__c = true;
        insert financeBook;
        //Creating Product from Test Data Factory
        List<Product2> prodList = TestDataFactory.createProduct(1,True);
        prodList[0].blng__BillingRule__c = blngRule.Id;
        prodList[0].blng__TaxRule__c = taxRule.Id;
        prodList[0].blng__RevenueRecognitionRule__c = revRecogRule.Id;
        prodList[0].SBQQ__BillingFrequency__c = 'Annual';
        prodList[0].SBQQ__BillingType__c = 'Advance';
        prodList[0].SBQQ__ChargeType__c = 'Recurring';
        update prodList[0];
        
        //Creating Pricebook Entry
        PricebookEntry pbEntry = TestDataFactory.createPricebookEntry(prodList[0].Id,true);
        //Creating Dimension
        SBQQ__Dimension__c dim = TestDataFactory.createPricebookDimension(prodList[0].Id,true);
        //Creating QuotelIne
        List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.createQuoteLine(1,quoteList[0].Id,prodList[0].Id,true);
        //Creating Order
        Order ord = new Order();
        ord.AccountId = accList[0].Id;
        ord.EffectiveDate = system.today();
        ord.Pricebook2Id = pbEntry.Pricebook2Id;
        ord.Status = 'Draft';
        ord.blng__BillingDayOfMonth__c = '1';
        insert ord;
        //Creating Order Item
        OrderItem ordItem = new OrderItem();
        ordItem.Product2Id = prodList[0].Id;
        ordItem.OrderId = ord.Id;
        ordItem.Quantity = 1; 
        ordItem.ServiceDate = system.today();
        ordItem.EndDate = system.today()+10;
        ordItem.PricebookEntryId = pbEntry.Id;
        ordItem.UnitPrice = 100;
        insert ordItem;
        //Creating Invoice Lines 
        QtC_Mig_Invoice_Lines_Temp_Table__c invLines = new QtC_Mig_Invoice_Lines_Temp_Table__c();
        invLines.Sales_Order_Internal_Id__c = '12345';
        invLines.Order__c = ord.Id;
        invLines.Order_Product__c = ordItem.Id;
        invLines.Item__c = prodList[0].ProductCode;
        invLines.Quantity__c = 1;
        invLines.Sales_Order_Line_Id__c = '1';
        insert invLines;
        //Creating T_OrderLineDMSummary__c record
        T_OrderLineDMSummary__c ordProdDM = new T_OrderLineDMSummary__c();
        ordProdDM.NSOrderID__c = '12345';
        ordProdDM.SF_Order_Id__c = invLines.Order__c;
        ordProdDM.SF_OrderProduct_Id__c = invLines.Order_Product__c;
        ordProdDM.NS_OrderLine_Item__c = prodList[0].ProductCode;
        ordProdDM.NSOrderLineitemID__c = '1';
        ordProdDM.Quantity__c = 1;
   		insert ordProdDM;
    }
    @isTest
    //Method to execute the test data
    public static void updateInvLinewithSFOrderSFOrdProdBatchTest(){
        //Start test
        Test.startTest();
        //Execute the batch class to be tested
        T_UpdateInvLinewithSFOrderSFOrdProdBatch bc = new T_UpdateInvLinewithSFOrderSFOrdProdBatch();
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        
        //Validating the results
        list<QtC_Mig_Invoice_Lines_Temp_Table__c> tempInvLine = [Select Id,Order__c FROM QtC_Mig_Invoice_Lines_Temp_Table__c];
        List<Order> ordList = [Select Id from Order Limit 1];
        if(tempInvLine.size()>0 && ordList.size() > 0 && tempInvLine[0].Order__c != null){
        System.assertEquals(tempInvLine[0].Order__c,ordList[0].Id,'Order Populated Successfully');    
        }
    }
}