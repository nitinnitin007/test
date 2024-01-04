/**** @name        : T_NA_UpdateSFOrderInBlngInvoiceBatchTest
***** @author      : KPMG
***** @created On  : Nov 11th, 2023
***** @description : Test Class for T_NA_UpdateSFOrderInBlngInvoiceBatch to check - Update the Billing Invoice Lines
******/
@istest
public class T_NA_UpdateSFOrderInBlngInvoiceBatchTest {
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
        QtC_Mig_Invoice_Temp_Table__c inv = new QtC_Mig_Invoice_Temp_Table__c();
        inv.Internal_ID__c = '12345';
        inv.Order__c = ord.Id;
        insert inv;
        
        //Creating blng__Invoice__c record
        blng__Invoice__c blngInv = new blng__Invoice__c();
        blngInv.NS_Inv_Internal_ID__c = '12345';
        blngInv.blng__Account__c = acc.Id;
        blngInv.blng__Order__c = ord.Id;
        blngInv.T_IsMigrated__c = true;
        insert blngInv;
    }
    @isTest
    //Method to test the batch
    public static void updateSFOrderInBlngInvoiceBatchTestMethod(){
        //Start test
        Test.starttest();
        //Method to execute the Batch
        T_NA_UpdateSFOrderInBlngInvoiceBatch bc = new T_NA_UpdateSFOrderInBlngInvoiceBatch();
        Id batchId = Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        
        //Validating the results
        List<blng__Invoice__c> tempInvList = [SELECT Id,blng__Order__c FROM blng__Invoice__c Limit 1];
        List<Order> tempOrd = [SELECT Id FROM Order Limit 1];
        if(tempInvList.size() > 0 && tempOrd.size() > 0 && tempInvList[0].blng__Order__c != null){
            system.assertEquals(tempInvList[0].blng__Order__c,tempOrd[0].Id,'Order Populated successfully');
        }
    }
}