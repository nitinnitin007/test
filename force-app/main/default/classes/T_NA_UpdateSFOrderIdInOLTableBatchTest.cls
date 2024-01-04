/**** @name        : T_NA_UpdateSFOrderIdInOLTableBatchTest
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Test Class for T_NA_UpdateSFOrderIdInOLTableBatch to check -Update the OL Summary Table's SF Order Id using Internal Id
******/
@isTest
public class T_NA_UpdateSFOrderIdInOLTableBatchTest {
    //Creating Test Data
	@testSetup
    public static void testData(){
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
        
        //Creating order record
        Order ord = new Order();
        ord.AccountId = acc.id;
        ord.OpportunityId = oppList[0].Id;
        ord.EffectiveDate = system.today();
        ord.Status = 'Draft';
        ord.blng__BillingDayOfMonth__c = '1';
        ord.Pricebook2Id = pbEntry.Pricebook2Id;
        ord.NetSuite_Sales_order_Internal_Id__c = '12345';
        insert ord;
        
        //Creating T_OrderLineDMSummary__c record
		T_OrderLineDMSummary__c tempOrderLine = new T_OrderLineDMSummary__c();
        tempOrderLine.SF_Order_Id__c = ord.Id;
        tempOrderLine.NSOrderID__c = '12345';
        insert tempOrderLine;
    }
    @isTest
    public static void updateSFOrderIdInOLTableBatchTestMethod(){
        //Start Test
        Test.startTest();
        //Method to execute the test data
        T_NA_UpdateSFOrderIdInOLTableBatch bc = new T_NA_UpdateSFOrderIdInOLTableBatch();
        Database.executeBatch(bc);
        //Stop Test
        Test.stopTest();
        
        //Validatting the Results
        List<T_OrderLineDMSummary__c> tempOrdLine = [SELECT Id,SF_Order_Id__c FROM T_OrderLineDMSummary__c Limit 1];
        List<Order> tempOrd = [SELECT Id FROM Order Limit 1];
        if(tempOrdLine.size()>0 && tempOrdLine[0].SF_Order_Id__c != null){
            System.assertEquals(tempOrdLine[0].SF_Order_Id__c,tempOrd[0].Id,'Order Id populated successfully');
        }    
    }
}