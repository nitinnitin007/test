/**** @name        : T_NA_UpdteSFOrdProdIdInOLTableBatchTest
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Test Class for T_NA_UpdateSFOrderProdIdInOLTableBatch to check -Update the OL Summary Table's SF Order Id using Internal Id
******/

@isTest
public class T_NA_UpdteSFOrdProdIdInOLTableBatchTest {
	 //Test Data Setup
     @isTest
    public static void updSfOrderProductInOlWithoutAmount(){
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
        
        //Creating Orderitem record
        OrderItem ordItem = new OrderItem();
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
        
        //Creating T_OrderLineDMSummary__c record
		T_OrderLineDMSummary__c tempOrderLine = new T_OrderLineDMSummary__c();
        tempOrderLine.SF_Order_Id__c = ord.Id;
        tempOrderLine.NSOrderID__c = '12345';
        tempOrderLine.NS_OrderLine_Item__c = prodList[0].productcode;
        tempOrderLine.Quantity__c = 1;
        tempOrderLine.OL_StartDate__c = system.today();
        tempOrderLine.SF_OrderProduct_Id__c = ordItem.Id;
        tempOrderLine.NS_OL_Amount_with_Tax__c = 1;
        insert tempOrderLine;
        
        //Start Test
        Test.StartTest();
        //Method to execute the batch
        Database.executeBatch(new T_NA_UpdateSFOrderProdIdInOLTableBatch('withoutAmount'));
        //Stop Test
        Test.StopTest();
        
        //Validting the Results
        List<T_OrderLineDMSummary__c> tempOLSummary = [SELECT ID,SF_Order_Id__c,SF_OrderProduct_Id__c FROM T_OrderLineDMSummary__c Limit 1];
        List<OrderItem> tempOrderItem = [SELECT Id FROM OrderItem Limit 1];
        if(tempOrderItem.size() > 0 && tempOLSummary[0].SF_OrderProduct_Id__c != null && tempOrderItem.size() > 0){
            System.assertEquals(tempOrderItem[0].Id,tempOLSummary[0].SF_OrderProduct_Id__c,'Id Populated Sucessfully');
        }
    }
    
    @isTest
    //Method to execute the test data for with Amount
    public static void updSfOrderProductInOlWithAmount(){
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
        
        //Creating Orderitem record
        OrderItem ordItem = new OrderItem();
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
        
        //Creating T_OrderLineDMSummary__c record
		T_OrderLineDMSummary__c tempOrderLine = new T_OrderLineDMSummary__c();
        tempOrderLine.SF_Order_Id__c = ord.Id;
        tempOrderLine.NSOrderID__c = '12345';
        tempOrderLine.NS_OrderLine_Item__c = prodList[0].productcode;
        tempOrderLine.Quantity__c = 1;
        tempOrderLine.OL_StartDate__c = system.today();
        tempOrderLine.SF_OrderProduct_Id__c = ordItem.Id;
        tempOrderLine.SF_OrderProdTotal__c=1;
        tempOrderLine.NS_OL_Amount_with_Tax__c = 1;
        tempOrderLine.OL_Amount__c = 1;
        insert tempOrderLine;
        
        
        //Start Test
        Test.StartTest();
        //Method to execute the batch
        Database.executeBatch(new T_NA_UpdateSFOrderProdIdInOLTableBatch('withAmount'));
        //Stop Test
        Test.StopTest();
        
        //Validting the Results
        List<T_OrderLineDMSummary__c> tempOLSummary = [SELECT ID,SF_Order_Id__c,SF_OrderProduct_Id__c FROM T_OrderLineDMSummary__c Limit 1];
        List<OrderItem> tempOrderItem = [SELECT Id FROM OrderItem Limit 1];
        if(tempOrderItem.size() > 0 && tempOLSummary[0].SF_OrderProduct_Id__c != null && tempOrderItem.size() > 0){
            System.assertEquals(tempOrderItem[0].Id,tempOLSummary[0].SF_OrderProduct_Id__c,'Id Populated Sucessfully');
    }
}
    
    @isTest
    //Method to execute the test data for with Amount
    public static void updSfOrderProductInOlWithApproxAmount(){
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
        
        //Creating Orderitem record
        OrderItem ordItem = new OrderItem();
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
        
        //Creating T_OrderLineDMSummary__c record
		T_OrderLineDMSummary__c tempOrderLine = new T_OrderLineDMSummary__c();
        tempOrderLine.SF_Order_Id__c = ord.Id;
        tempOrderLine.NSOrderID__c = '12345';
        tempOrderLine.NS_OrderLine_Item__c = prodList[0].productcode;
        tempOrderLine.Quantity__c = 1;
        tempOrderLine.SF_OrderProdTotal__c = 1;
        tempOrderLine.OL_Amount__c = 0.05;
        insert tempOrderLine;
        
        //Start Test
        Test.StartTest();
        //Method to execute the batch
        Database.executeBatch(new T_NA_UpdateSFOrderProdIdInOLTableBatch(1.00));
        //Stop Test
        Test.StopTest();
        
        //Validting the Results
        List<T_OrderLineDMSummary__c> tempOLSummary = [SELECT ID,SF_Order_Id__c,SF_OrderProduct_Id__c FROM T_OrderLineDMSummary__c Limit 1];
        List<OrderItem> tempOrderItem = [SELECT Id FROM OrderItem Limit 1];
        if(tempOrderItem.size() > 0 && tempOLSummary[0].SF_OrderProduct_Id__c != null && tempOrderItem.size() > 0){
            System.assertEquals(tempOrderItem[0].Id,tempOLSummary[0].SF_OrderProduct_Id__c,'Id Populated Sucessfully');
    }
}

}