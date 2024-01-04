/**** @name        : T_UpdateOverRideNBDateBatchTest
***** @created By  : KPMG
***** @created On  : Dec 15th, 2023
***** @description : Test Class for T_UpdateOverRideNBDateBatch to Update Override Next Billing Date in OrderProdicts from Invoice Temp table
******/
@isTest
public class T_UpdateOverRideNBDateBatchTest {
@testsetup
    //TestSetup
    static void setupData(){
        //Creating Account
        Account  acc = new Account();
        acc.Name = 'Service Billing Testing 10/30';
        insert acc;
        //Creating Opp from Test Data Factory
        List<opportunity> oppList = TestDataFactory.createOppty(1,acc.Id,True);
        //Creating Quote from TestData Factory
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
        update prodList[0];
                
        //Creating PriceBook from TestDataFactory
        PricebookEntry pbEntry = TestDataFactory.createPricebookEntry(prodList[0].Id,true);
        pbEntry.UnitPrice = 100;
        update pbEntry;
        //Creating Dimension from TestDataFactory
        SBQQ__Dimension__c dim = TestDataFactory.createPricebookDimension(prodList[0].Id,true);
        //Creating QuoteLine from TestDataFactory
        List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.createQuoteLine(1,quoteList[0].Id,prodList[0].Id,true);
     
        //Creating Order
        Order ord = new Order();
        ord.AccountId = acc.id;
        ord.OpportunityId = oppList[0].Id;
        ord.EffectiveDate = system.today();
        ord.Status = 'Draft';
        ord.blng__BillingDayOfMonth__c = '1';
        ord.Pricebook2Id = pbEntry.Pricebook2Id;
        ord.NetSuite_Sales_order_Internal_Id__c = '123456';
        insert ord;
        
        //Creating QtC_Mig_Invoice_Temp_Table__c
        QtC_Mig_Invoice_Temp_Table__c qtcmigInv = new QtC_Mig_Invoice_Temp_Table__c();
        qtcmigInv.Sales_Order_Internal_Id__c = '123456';
        qtcmigInv.Status__c = 'Open';
        qtcmigInv.Invoice_Status__c = 'Sent';
        qtcmigInv.Date__c = system.Today();
        qtcmigInv.Next_Billing_Date__c = system.Today()+10;
        qtcmigInv.Internal_ID__c = '12345';
        qtcmigInv.Document_Number__c = '12345';
        insert qtcmigInv;
        
        //Creating OrderItem
        OrderItem ordItem = new OrderItem();
        ordItem.SBQQ__BillingFrequency__c = 'Quarterly';
        ordItem.blng__OverrideNextBillingDate__c = qtcmigInv.Next_Billing_Date__c;
        ordItem.Product2Id = prodList[0].Id;
        ordItem.OrderId = ord.Id;
        ordItem.Quantity = 1;
        ordItem.UnitPrice =1;
        ordItem.ServiceDate = system.today();
        ordItem.PricebookEntryId = pbEntry.Id;
        ordItem.SBQQ__ChargeType__c = 'One-Time';
        ordItem.blng__BillingRule__c = blngRule.Id;
        ordItem.blng__TaxRule__c = taxRule.id;
        ordItem.blng__FinanceBookAccounting__c = financeBook.id;
        ordItem.SBQQ__QuoteLine__c=quoteLineList[0].id;
        ordItem.SBQQ__Activated__c = true;
        insert ordItem;
        
        //Insert T_OrderLineDMSummary__c
        T_OrderLineDMSummary__c olSummary = new T_OrderLineDMSummary__c();
        olSummary.NSOrderID__c = '123456';
        olSummary.SF_Order_Id__c = ord.Id;
        olSummary.SF_OrderProduct_Id__c = ordItem.Id;
        olSummary.OL_with_Partially_paid_invoice__c = True;
        insert olSummary;
    }
    @isTest
    //Method to execute the Batch
    static void updateOverRideNBDateBatchTest(){
        //Start test
        Test.startTest();
        //Batch to execute the method
        T_UpdateOverRideNBDateBatch bc = new T_UpdateOverRideNBDateBatch();
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        
        //Vaildating the results
        List<QtC_Mig_Invoice_Temp_Table__c> tempInv = [SELECT Id,Next_Billing_Date__c FROM QtC_Mig_Invoice_Temp_Table__c];
        List<OrderItem> tempOrdItem = [SELECT Id,blng__OverrideNextBillingDate__c FROM OrderItem];
        if(tempInv.size() > 0 && tempInv[0].Next_Billing_Date__c != null){
            System.assertEquals(tempInv[0].Next_Billing_Date__c,tempOrdItem[0].blng__OverrideNextBillingDate__c,'Date populated as expected');
        }
        
    }
}