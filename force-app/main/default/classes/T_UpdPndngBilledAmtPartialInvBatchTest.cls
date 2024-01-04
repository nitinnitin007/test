/**** @name        : T_UpdPndngBilledAmtPartialInvBatchTest
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Test Class for T_UpdPndngAndBilledAmtForPartialInvBatch to Update OrderItem for Pending Billing Amount
******/
@isTest
public class T_UpdPndngBilledAmtPartialInvBatchTest {
    //Method to execute partially paid Invoice
    @isTest
    static void partiallyPaidTest(){
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
        ordItem.blng__PendingBillings__c = 1;
        ordItem.blng__BilledAmountwithouttax__c = 0;
        ordItem.T_IsUpdated__c = True;
        ordItem.T_NS_OP_Pending_Balance__c = 1;
        ordItem.T_NS_Sales_Order_Internal_ID__c = '12345';
        ordItem.T_NS_Sales_Order_Line_ID__c = 1;
        ordItem.T_NS_OP_Inv_Line_With_Tax__c = 1;
        ordItem.T_NS_OP_Invoice_Status__c = 'Partially Paid';
        insert ordItem;
        //Creating T_OrderLineDMSummary__c
        T_OrderLineDMSummary__c summary = new T_OrderLineDMSummary__c();
        summary.SF_OrderProduct_Id__c = ordItem.Id ;
        summary.SF_Order_Id__c = ord.Id;
        summary.NSOrderID__c = '12345';
        summary.OL_with_Partially_paid_invoice__c = True;
        summary.IL_Total_Amount__c = '1';
        summary.NS_IL_Amount_with_Tax__c = 1;
        summary.OL_Amount__c = 1;
        summary.NS_IL_Amount_Total__c = 1;
        summary.NSOrderLineitemID__c = '1';
        summary.NS_IL_Amount_with_Tax__c = 1;
        insert summary;

        //Start Test
        Test.startTest();
        //Execute the batch to be tested
        T_UpdPndngAndBilledAmtForPartialInvBatch bc = new T_UpdPndngAndBilledAmtForPartialInvBatch();
        Database.executeBatch(bc);
        //Stop Test
        Test.stopTest();
        //Validating the results
        List<OrderItem> tempList = [SELECT id,blng__PendingBillings__c,blng__BilledAmountwithouttax__c FROM OrderItem Limit 1];
        if(tempList.size() > 0 && tempList[0].blng__PendingBillings__c != null){
        System.assertEquals(tempList[0].blng__PendingBillings__c,1,'Amount populated successfully');    
        }
    }
    
    @isTest
    //Method to execute fully paid Invoice
    static void fullyPaidTest(){
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
        //Creating Product
        List<Product2> prodList = TestDataFactory.createProduct(1,True);
        
        prodList[0].blng__BillingRule__c = blngRule.Id;
        prodList[0].blng__TaxRule__c = taxRule.Id;
        prodList[0].blng__RevenueRecognitionRule__c = revRecogRule.Id;
        prodList[0].SBQQ__BillingFrequency__c = 'Annual';
        prodList[0].SBQQ__BillingType__c = 'Advance';
        prodList[0].SBQQ__ChargeType__c = 'Recurring';
        update prodList[0];
        //Creating PriceBook Entry
        PricebookEntry pbEntry = TestDataFactory.createPricebookEntry(prodList[0].Id,true);
        //Creating Dimensions
        SBQQ__Dimension__c dim = TestDataFactory.createPricebookDimension(prodList[0].Id,true);
        //Creating QuoteLine
        List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.createQuoteLine(1,quoteList[0].Id,prodList[0].Id,true);
        //Creating Order
        Order ord = new Order();
        ord.AccountId = accList[0].Id;
        ord.EffectiveDate = system.today();
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
        ordItem.blng__PendingBillings__c = 0;
        ordItem.T_NS_OP_Pending_Balance__c = 0;
        ordItem.T_NS_Sales_Order_Internal_ID__c = '12345';
        ordItem.T_NS_Sales_Order_Line_ID__c = 1;
        ordItem.T_NS_OP_Inv_Line_With_Tax__c = 1;
        ordItem.T_NS_OP_Invoice_Status__c = 'Paid in Full';
        insert ordItem;
        //Creating OrderLineSUmmary
        T_OrderLineDMSummary__c summary = new T_OrderLineDMSummary__c();
        summary.SF_OrderProduct_Id__c = ordItem.Id ;
        summary.SF_Order_Id__c = ord.Id;
        summary.NSOrderID__c = '12345';
        summary.IL_Total_Amount__c = '1';
        summary.NS_IL_Amount_with_Tax__c = 1;
        summary.OL_Amount__c = 1;
        summary.OL_Paid_in_Full_Indicator__c = True;
        summary.NS_IL_Amount_Total__c = 1;
        summary.NSOrderLineitemID__c = '1';
        summary.NS_IL_Amount_with_Tax__c = 1;
        insert summary;
        //Start Test
        Test.startTest();
        //Execute the batch to be tested
        T_UpdPndngAndBilledAmtForPartialInvBatch bc = new T_UpdPndngAndBilledAmtForPartialInvBatch();
        Database.executeBatch(bc);
        //Stop Test
        Test.stopTest();
        //Validating the results
        List<OrderItem> tempList = [SELECT id,blng__PendingBillings__c,blng__BilledAmountwithouttax__c FROM OrderItem Limit 1];
        if(tempList.size() > 0 && tempList[0].blng__PendingBillings__c != null ){
        System.assertEquals(tempList[0].blng__PendingBillings__c,0,'Amount populated successfully');    
        }
    }
    @isTest
    //Method to execute future Invoice
    static void futureInvTest(){
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
        //Creating Product
        List<Product2> prodList = TestDataFactory.createProduct(1,True);
        
        prodList[0].blng__BillingRule__c = blngRule.Id;
        prodList[0].blng__TaxRule__c = taxRule.Id;
        prodList[0].blng__RevenueRecognitionRule__c = revRecogRule.Id;
        prodList[0].SBQQ__BillingFrequency__c = 'Annual';
        prodList[0].SBQQ__BillingType__c = 'Advance';
        prodList[0].SBQQ__ChargeType__c = 'Recurring';
        update prodList[0];
        //Creating PriceBook Entry
        PricebookEntry pbEntry = TestDataFactory.createPricebookEntry(prodList[0].Id,true);
        //Creating Dimensions
        SBQQ__Dimension__c dim = TestDataFactory.createPricebookDimension(prodList[0].Id,true);
        //Creating QuoteLine
        List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.createQuoteLine(1,quoteList[0].Id,prodList[0].Id,true);
        //Creating Order
        Order ord = new Order();
        ord.AccountId = accList[0].Id;
        ord.EffectiveDate = system.today();
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
        ordItem.blng__PendingBillings__c = 0;
        ordItem.T_NS_OP_Pending_Balance__c = 0;
        ordItem.T_NS_Sales_Order_Internal_ID__c = '12345';
        ordItem.T_NS_Sales_Order_Line_ID__c = 1;
        ordItem.T_NS_OP_Inv_Line_With_Tax__c = 1;
        ordItem.T_NS_OP_Invoice_Status__c = 'Future Invoice';
        insert ordItem;
        //Creating OrderLineSUmmary
        T_OrderLineDMSummary__c summary = new T_OrderLineDMSummary__c();
        summary.SF_OrderProduct_Id__c = ordItem.Id ;
        summary.SF_Order_Id__c = ord.Id;
        summary.NSOrderID__c = '12345';
        summary.IL_Total_Amount__c = '1';
        summary.NS_IL_Amount_with_Tax__c = 1;
        summary.OL_Amount__c = 1;
        summary.OL_Future_Invoice_Indicator__c = True;
        summary.NS_IL_Amount_Total__c = 1;
        summary.NSOrderLineitemID__c = '1';
        summary.NS_IL_Amount_with_Tax__c = 1;
        insert summary;
        //Start Test
        Test.startTest();
        //Execute the batch to be tested
        T_UpdPndngAndBilledAmtForPartialInvBatch bc = new T_UpdPndngAndBilledAmtForPartialInvBatch();
        Database.executeBatch(bc);
        //Stop Test
        Test.stopTest();
        //Validating the results
        List<OrderItem> tempList = [SELECT id,blng__PendingBillings__c,blng__BilledAmountwithouttax__c FROM OrderItem ];
        if(tempList.size() > 0 && tempList[0].blng__PendingBillings__c != null ){
        System.assertEquals(tempList[0].blng__PendingBillings__c,0,'Amount populated successfully');    
        }
    }
}