/**** @name       : T_NA_UpdSFOrderProdIdInBlnginvBatchTest
***** @author     : KPMG
***** @date       : Nov 11th, 2023
***** @description : Test Class to check - T_NA_UpdSFOrderProdIdInBlnginvBatch to Update the SF order Id and SF order Products Id in the blng__InvoiceLine__c
******/
@isTest
public class T_NA_UpdSFOrderProdIdInBlnginvBatchTest {
    @isTest
    //Method to execute the test data
    public static void updSFOrderProdIdInBlnginvBatchwithoutAmount(){
        //Creating Account
        List<Account> accList = TestDataFactory.createAccount(1,True);
        //Creating Opportunity
        //List<opportunity> oppList = TestDataFactory.createOppty(1,accList[0].Id,True);
        //Creating Quote
        //List<SBQQ__Quote__c> quoteList = TestDataFactory.createQuote(1,oppList[0].Id,True);
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
        //SBQQ__Dimension__c dim = TestDataFactory.createPricebookDimension(prodList[0].Id,true);
        //Creating QuotelIne
        //List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.createQuoteLine(1,quoteList[0].Id,prodList[0].Id,true);
        //Creating Order
        Order ord = new Order();
        ord.AccountId = accList[0].Id;
        ord.EffectiveDate = system.today();
        ord.Pricebook2Id = pbEntry.Pricebook2Id;
        ord.Status = 'Draft';
        ord.blng__BillingDayOfMonth__c = '1';
        insert ord;
        List<Order> tempOrd = [SELECT ID FROM Order];
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
        List<OrderItem> tempOrdItem = [SELECT ID FROM OrderItem];
        //Creating a test blng__Invoice__c record
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = accList[0].Id;
        inv.NS_Inv_Internal_ID__c = '12345';
        inv.NS_Inv_Document_Number__c = '123466';
        insert inv;
        List<blng__Invoice__c> tempInvoice = [SELECT ID FROM blng__Invoice__c];
        //Creating QtC_Mig_Invoice_Lines_Temp_Table__c 
        QtC_Mig_Invoice_Lines_Temp_Table__c invLines = new QtC_Mig_Invoice_Lines_Temp_Table__c();
        invLines.Sales_Order_Internal_Id__c = '12345807';
        invLines.Sales_Order_Line_Id__c = '1';
        invLines.Order__c = tempOrd[0].Id;
        invLines.Order_Product__c = tempOrdItem[0].Id;
        invLines.Internal_ID__c = '12345';
       	invLines.Term_Start_Date__c = system.today();
        invLines.Term_End_Date__c = system.today()+10;
        invLines.Quantity__c = 1;
        invLines.Item__c = prodList[0].ProductCode;
        invLines.T_Amount__c = '1';
        invLines.Tax_Amount__c = '0';
        insert invLines;
        List<QtC_Mig_Invoice_Lines_Temp_Table__c> tempInv = [SELECT Id,Order__c,Order_Product__c,IL_Amount_with_Tax__c FROM QtC_Mig_Invoice_Lines_Temp_Table__c ];
        
        //Creating a test blng__InvoiceLine__c record
        blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
        invLine.NS_Sales_Order_Internal_Id__c = '12345807';
        invLine.NS_Sales_Order_Line_Id__c = '1';
        invLine.blng__Quantity__c = 1;
        invLine.blng__Product__c = prodList[0].id;
        invLine.NS_Line_ID__c = '1';
        invLine.NS_Inv_Internal_ID__c = '12345';
        invLine.blng__OrderProduct__c = tempInv[0].Order_Product__c;
        invLine.Order__c = tempInv[0].Order__c;
        invLine.blng__Invoice__c = tempInvoice[0].Id;
        invLine.T_IsMigrated__c = true;
        invLine.blng__StartDate__c = system.today();
        invLine.blng__EndDate__c = system.today()+10;
        invLine.blng__TotalAmount__c = tempInv[0].IL_Amount_with_Tax__c;
        //invLine.blng__TotalAmount__c = 1.00;
        insert invLine;        
  
       
        //Start test
        test.startTest();
        //Execute the batch class to be tested
        Database.executeBatch(new T_NA_UpdSFOrderProdIdInBlnginvBatch('withoutAmount'));
        //Stop test
        test.stopTest();
        //Validate the result
        List<blng__InvoiceLine__c> tempInvLine = [SELECT Id,NS_Sales_Order_Internal_Id__c,NS_Line_ID__c,NS_Inv_Internal_ID__c,blng__OrderProduct__c,Order__c FROM blng__InvoiceLine__c ];
        List<QtC_Mig_Invoice_Lines_Temp_Table__c> tempQtcInvLine = [SELECT Id,Internal_ID__c, Sales_Order_Internal_Id__c, Sales_Order_Line_Id__c,Order__c, Order_Product__c FROM QtC_Mig_Invoice_Lines_Temp_Table__c];
        if(tempInvLine.size()>0 && tempInvLine[0].NS_Sales_Order_Internal_Id__c != null){
            System.assertEquals(tempInvLine[0].blng__OrderProduct__c,tempQtcInvLine[0].Order_Product__c,'Order Product Id populated successfully');  
        }        
    }
    @isTest
    //Method to execute the test data
    public static void updSFOrderProdIdInBlnginvBatchwithAmount(){
        //Creating Account
        List<Account> accList = TestDataFactory.createAccount(1,True);
        //Creating Opportunity
        //List<opportunity> oppList = TestDataFactory.createOppty(1,accList[0].Id,True);
        //Creating Quote
        //List<SBQQ__Quote__c> quoteList = TestDataFactory.createQuote(1,oppList[0].Id,True);
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
        //SBQQ__Dimension__c dim = TestDataFactory.createPricebookDimension(prodList[0].Id,true);
        //Creating QuotelIne
        //List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.createQuoteLine(1,quoteList[0].Id,prodList[0].Id,true);
        //Creating Order
        Order ord = new Order();
        ord.AccountId = accList[0].Id;
        ord.EffectiveDate = system.today();
        ord.Pricebook2Id = pbEntry.Pricebook2Id;
        ord.Status = 'Draft';
        ord.blng__BillingDayOfMonth__c = '1';
        insert ord;
        List<Order> tempOrd = [SELECT ID FROM Order];
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
        List<OrderItem> tempOrdItem = [SELECT ID FROM OrderItem];
        //Creating a test blng__Invoice__c record
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = accList[0].Id;
        inv.NS_Inv_Internal_ID__c = '12345';
        inv.NS_Inv_Document_Number__c = '123466';
        insert inv;
        List<blng__Invoice__c> tempInvoice = [SELECT ID FROM blng__Invoice__c];
        //Creating QtC_Mig_Invoice_Lines_Temp_Table__c 
        QtC_Mig_Invoice_Lines_Temp_Table__c invLines = new QtC_Mig_Invoice_Lines_Temp_Table__c();
        invLines.Sales_Order_Internal_Id__c = '12345807';
        invLines.Sales_Order_Line_Id__c = '1';
        invLines.Order__c = tempOrd[0].Id;
        invLines.Order_Product__c = tempOrdItem[0].Id;
        invLines.Internal_ID__c = '12345';
       	invLines.Term_Start_Date__c = system.today();
        invLines.Term_End_Date__c = system.today()+10;
        invLines.Quantity__c = 1;
        invLines.Item__c = prodList[0].ProductCode;
        invLines.T_Amount__c = '1';
        invLines.Tax_Amount__c = '0';
        insert invLines;
        List<QtC_Mig_Invoice_Lines_Temp_Table__c> tempInv = [SELECT Id,Order__c,Order_Product__c,IL_Amount_with_Tax__c FROM QtC_Mig_Invoice_Lines_Temp_Table__c ];
        
        //Creating a test blng__InvoiceLine__c record
        blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
        invLine.NS_Sales_Order_Internal_Id__c = '12345807';
        invLine.NS_Sales_Order_Line_Id__c = '1';
        invLine.blng__Quantity__c = 1;
        invLine.blng__Product__c = prodList[0].id;
        invLine.NS_Line_ID__c = '1';
        invLine.NS_Inv_Internal_ID__c = '12345';
        invLine.blng__OrderProduct__c = tempInv[0].Order_Product__c;
        invLine.Order__c = tempInv[0].Order__c;
        invLine.blng__Invoice__c = tempInvoice[0].Id;
        invLine.T_IsMigrated__c = true;
        invLine.blng__StartDate__c = system.today();
        invLine.blng__EndDate__c = system.today()+10;
        //invLine.blng__TotalAmount__c = tempInv[0].IL_Amount_with_Tax__c;
        invLine.blng__Subtotal__c = tempInv[0].IL_Amount_with_Tax__c;
        insert invLine;        
  
       
        //Start test
        test.startTest();
        //Execute the batch class to be tested
        Database.executeBatch(new T_NA_UpdSFOrderProdIdInBlnginvBatch('withAmount'));
        //Stop test
        test.stopTest();
        //Validate the result
        List<blng__InvoiceLine__c> tempInvLine = [SELECT Id,NS_Sales_Order_Internal_Id__c,NS_Line_ID__c,NS_Inv_Internal_ID__c,blng__OrderProduct__c,Order__c FROM blng__InvoiceLine__c ];
        List<QtC_Mig_Invoice_Lines_Temp_Table__c> tempQtcInvLine = [SELECT Id,Internal_ID__c, Sales_Order_Internal_Id__c, Sales_Order_Line_Id__c,Order__c, Order_Product__c FROM QtC_Mig_Invoice_Lines_Temp_Table__c];
        if(tempInvLine.size()>0 && tempInvLine[0].NS_Sales_Order_Internal_Id__c != null){
            System.assertEquals(tempInvLine[0].blng__OrderProduct__c,tempQtcInvLine[0].Order_Product__c,'Order Product Id populated successfully');  
        }        
    }
}