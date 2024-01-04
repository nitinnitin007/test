/**** @name        : T_PayAllocLookupBatchTest
***** @author      : KPMG
***** @date        : Dec 11th, 2023
***** @description : Test Class for T_PayAllocLookupBatch to update Temp Payment Alloc with blng__Account__c and blng__Invoice__c
******/
@isTest
public class T_PayAllocLookupBatchTest {
    //Test Data Setup
    @testSetup()
    static void setupData(){
        
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
        
        //Creating a test blng__Invoice__c record
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = accList[0].Id;
        inv.NS_Inv_Internal_ID__c = '12345';
        inv.NS_Inv_Document_Number__c = '123466';
        inv.T_IsMigrated__c = True;
        insert inv;//Insert the blng__Invoice__c record
        
        //Creating a test QtC_Mig_PaymentAlloc_Temp_Table__c record
        QtC_Mig_PaymentAlloc_Temp_Table__c paymentAlloc = new QtC_Mig_PaymentAlloc_Temp_Table__c();
        paymentAlloc.Invoice_Internal_ID__c = '12345';
        paymentAlloc.T_Account__c = Null; 
        paymentAlloc.T_Invoice__c = Null;
        insert paymentAlloc;// Insert the QtC_Mig_PaymentAlloc_Temp_Table__c record
    }
    @isTest
    //Method to execute test data
    static void payAllocLookupBatchTest(){
        //Start Test
        Test.startTest();
        //Execute the Batch class to be tested
        T_PayAllocLookupBatch bc = new T_PayAllocLookupBatch();
        Database.executeBatch(bc);
        //Stop Test
        Test.stopTest();
        //Validating the Results
        List<QtC_Mig_PaymentAlloc_Temp_Table__c> tempPayAlloc = [SELECT Id,T_Invoice__c FROM QtC_Mig_PaymentAlloc_Temp_Table__c Limit 1];
        List<blng__Invoice__c> tempInv = [SELECT Id,NS_Inv_Internal_ID__c FROM blng__Invoice__c Limit 1];
        if(tempPayAlloc.size() > 0 && tempInv.size() >0 ){
            System.assertEquals(tempPayAlloc[0].T_Invoice__c,tempInv[0].Id,'Invoice Id populated successfully');
        }
    }
}