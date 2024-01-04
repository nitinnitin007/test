/**** @Name :T_UpdateOrderProdWithInvLineDtBatchTest
***** @Created By : KPMG
***** @Created On : Dec 11th, 2023
***** @description : Test class for T_UpdateOrderProdWithInvLineDateBatch to update the max date to the order products.
******/
@isTest
public class T_UpdateOrderProdWithInvLineDtBatchTest {
    @isTest
    //Method to execute the test data
    public static void updSFOrderProdIdWithInvLineDt(){
        //Creating Account
        List<Account> accList = TestDataFactory.createAccount(1,True);
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
        //Creating Order
        Order ord = new Order();
        ord.AccountId = accList[0].Id;
        ord.EffectiveDate = system.today();
        ord.Pricebook2Id = pbEntry.Pricebook2Id;
        ord.Status = 'Draft';
        ord.blng__BillingDayOfMonth__c = '1';
        ord.NetSuite_Sales_order_Internal_Id__c='123456789';
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
        QtC_Mig_Invoice_Lines_Temp_Table__c invLine = new QtC_Mig_Invoice_Lines_Temp_Table__c();
        invLine.Sales_Order_Internal_Id__c = '12345807';
        invLine.Sales_Order_Line_Id__c = '1';
        invLine.Order__c = tempOrd[0].Id;
        invLine.Order_Product__c = tempOrdItem[0].Id;
        invLine.Internal_ID__c = '12345';
       	invLine.Term_Start_Date__c = system.today();
        invLine.Term_End_Date__c = system.today()+10;
        invLine.Quantity__c = 1;
        invLine.Item__c = prodList[0].ProductCode;
        invLine.T_Amount__c = '1';
        invLine.Tax_Amount__c = '0';
        insert invLine;
        List<QtC_Mig_Invoice_Lines_Temp_Table__c> tempInv = [SELECT Id,Order__c,Order_Product__c,IL_Amount_with_Tax__c FROM
                                                             QtC_Mig_Invoice_Lines_Temp_Table__c ];
        
        //Creating a test blng__InvoiceLine__c record
        blng__InvoiceLine__c blngInvLine = new blng__InvoiceLine__c();
        blngInvLine.NS_Sales_Order_Internal_Id__c = '12345807';
        blngInvLine.NS_Sales_Order_Line_Id__c = '1';
        blngInvLine.blng__Quantity__c = 1;
        blngInvLine.blng__Product__c = prodList[0].id;
        blngInvLine.NS_Line_ID__c = '1';
        blngInvLine.NS_Inv_Internal_ID__c = '12345';
        blngInvLine.blng__OrderProduct__c = tempInv[0].Order_Product__c;
        blngInvLine.Order__c = tempInv[0].Order__c;
        blngInvLine.blng__Invoice__c = tempInvoice[0].Id;
        blngInvLine.T_IsMigrated__c = True;
        blngInvLine.blng__StartDate__c = system.today();
        blngInvLine.blng__EndDate__c = system.today()+10;
        blngInvLine.blng__TotalAmount__c = tempInv[0].IL_Amount_with_Tax__c;
        insert blngInvLine;
        
         //Start test
        Test.startTest();
        //Execute the batch class to be tested
        Database.executeBatch(new T_UpdateOrderProdWithInvLineDateBatch()); 
        //Stop test
        Test.stopTest();
        
        ordItem = [SELECT Id,T_Mig_InvLines_Max_StartDate__c FROM OrderItem WHERE Id =:ordItem.Id];
        if(ordItem != null && ordItem.T_Mig_InvLines_Max_StartDate__c != null)
        {System.assertEquals(ordItem.T_Mig_InvLines_Max_StartDate__c,SYSTEM.TODAY(),'Max Date updated successfully');}
        
    }
}