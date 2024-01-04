/**** @name        :T_PayAllocIdLookupBatchTest
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Test Class for T_PayAllocIdLookupBatch to update the blng__Payment__c and Account in the QtC_Mig_PaymentAlloc_Temp_Table__c
******/
@isTest
public class T_PayAllocIdLookupBatchTest {
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
        
        //Creating PriceBookEntry
        PricebookEntry pbEntry = TestDataFactory.createPricebookEntry(prodList[0].Id,true);
        
        //Create Dimensions
        SBQQ__Dimension__c dim = TestDataFactory.createPricebookDimension(prodList[0].Id,true);
        
        //Creating QuoteLines
        List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.createQuoteLine(1,quoteList[0].Id,prodList[0].Id,true);
        
        //Creating Order
        Order ord = new Order();
        ord.AccountId = accList[0].Id;
        ord.EffectiveDate = System.today();
        ord.Pricebook2Id = pbEntry.Pricebook2Id;
        ord.Status = 'Draft';
        ord.blng__BillingDayOfMonth__c = '1';
        insert ord;
        
        //Creating OrderItems
        OrderItem ordItem = new OrderItem();
        ordItem.Product2Id = prodList[0].Id;
        ordItem.OrderId = ord.Id;
        ordItem.Quantity = 1;
        ordItem.UnitPrice =1;
        ordItem.PricebookEntryId = pbEntry.Id;
        ordItem.SBQQ__ChargeType__c = 'One-Time';
        ordItem.blng__BillingRule__c = blngRule.Id;
        ordItem.blng__TaxRule__c = taxRule.id;
        ordItem.blng__FinanceBookAccounting__c = financeBook.id;
        ordItem.SBQQ__QuoteLine__c=quoteLineList[0].id;
        ordItem.SBQQ__Activated__c = true;
        insert ordItem;
        
        //Creating blng__Invoice__c record
        blng__Invoice__c blngInv = new blng__Invoice__c();
        blngInv.NS_Inv_Internal_ID__c = '1234';
        blngInv.blng__Account__c = accList[0].Id;
        blngInv.blng__InvoiceStatus__c = 'Posted';
        blngInv.T_IsMigrated__c = True;
        insert blngInv;
        
        //Create Billing Inv Lines
        blng__InvoiceLine__c blngInLine = new blng__InvoiceLine__c();
        blngInLine.NS_Inv_Internal_ID__c = '1234';
        blngInLine.NS_Line_ID__c = '1';
        blngInLine.T_IsMigrated__c = true;
        blngInLine.blng__Invoice__c = blngInv.Id;
        insert blngInLine;
        
        //Creating test blng__Payment__c records
        blng__Payment__c pay = new blng__Payment__c();
        pay.blng__Account__c = accList[0].id;
        pay.NS_Payment_Internal_ID__c = '12345';
        pay.blng__Amount__c = 1234.00;
        pay.T_IsMigrated__c = True;
        insert pay;// Insert the blng__Payment__c record
        
        //Creating test QtC_Mig_PaymentAlloc_Temp_Table__c records
        QtC_Mig_PaymentAlloc_Temp_Table__c paymentAlloc = new QtC_Mig_PaymentAlloc_Temp_Table__c();
        paymentAlloc.Internal_ID__c = '12345';
        paymentAlloc.T_Account__c = accList[0].id;
        paymentAlloc.T_Payment__c = pay.Id;
        paymentAlloc.T_Invoice__c = blngInv.Id;
        paymentAlloc.Invoice_Internal_ID__c = '12345';
        insert paymentAlloc; // Insert the QtC_Mig_PaymentAlloc_Temp_Table__c record
    }
    @isTest
    //Method to execute test data
    static void execute(){
        //Start Test
        Test.startTest();
        //Execute the Batch class to be tested
        T_PayAllocIdLookupBatch bc = new T_PayAllocIdLookupBatch();
        Database.executeBatch(bc);
        //Stop Test
        Test.stopTest();
        //Validate the results
        List<QtC_Mig_PaymentAlloc_Temp_Table__c> tempPayalloc = [SELECT Id,T_Payment__c,T_Account__c FROM QtC_Mig_PaymentAlloc_Temp_Table__c Limit 1];
        List<blng__Payment__c> tempPayment = [SELECT Id,blng__Account__c FROM blng__Payment__c Limit 1]; 
        if(tempPayalloc.size() > 0 && tempPayment.size() > 0 && tempPayalloc[0].T_Account__c != null && tempPayment[0].blng__Account__c != null){
            System.assertEquals(tempPayalloc[0].T_Account__c,tempPayment[0].blng__Account__c,'Payment Populated successfully' );
        }
    }
    
    
}