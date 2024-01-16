@isTest
public with sharing class InvoiceFilterBatchTest {
    @isTest
    private static void doTest(){
        Account acc = IntappTestObjectFactory.createaccount(true);
        Account billingAccount = IntappTestObjectFactory.createaccount(true);
        
        blng__BillingRule__c billRule = new blng__BillingRule__c();
        billRule.Name = 'Bill Rule1';
        billRule.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
        billRule.blng__PartialPeriodTreatment__c = 'Separate';
        billRule.blng__PeriodTreatmentForBTDO__c = 'Exclude Billing Day of Month';
        billRule.blng__GenerateInvoices__c = 'No';
        billRule.blng__Active__c = true;
        insert billRule;
        blng__BillingRule__c insertedBillingRule = [select id from blng__BillingRule__c where name = 'Bill Rule1' limit 1];
        system.assert(insertedBillingRule != Null, 'Billin Rule should be inserted successfully');
        
        blng__RevenueRecognitionRule__c rrObj = new blng__RevenueRecognitionRule__c();
        rrObj.blng__Active__c = true;
        rrObj.blng__CreateRevenueSchedule__c = 'No';
        insert rrObj;
        
        blng__TaxRule__c taxRuleObj = new blng__TaxRule__c();
        taxRuleObj.blng__Active__c = true;
        taxRuleObj.blng__TaxableYesNo__c = 'No';
        insert taxRuleObj;
        
        Product2 prodObj = (Product2) SmartFactory.createSObject('Product2');
        prodObj.Name = 'Testproduct';
        prodObj.IsActive = true;
        prodObj.ProductCode = '123462';
        prodObj.blng__BillingRule__c = billRule.Id;
        prodObj.blng__RevenueRecognitionRule__c = rrObj.Id;
        prodObj.blng__TaxRule__c = taxRuleObj.Id;
        prodObj.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        prodObj.SBQQ__SubscriptionTerm__c = 12;
        prodObj.SBQQ__SubscriptionType__c = 'Renewable';
        prodObj.SBQQ__ChargeType__c = 'Recurring';
        //prodObj.SBQQ__BillingFrequency__c = 'Quarterly';
        prodObj.SBQQ__BillingType__c = 'Arrears';
        insert prodObj;
        
        Contract con = IntappTestObjectFactory.createcontract(acc.Id);
        con.Billing_Account__c = billingAccount.Id;
        insert con;
        
        con.Status = 'Activated';
        update con;
        con.Status = 'In Force';
        con.Subsidiary__c = '05:400 TFG - US';
        con.Subsidiary__c = '05:400 TFG - US';
        con.Migration_Status__c = 'Ready';
        update con; 
        OP4I_Entitlement_View__c entitlement = new OP4I_Entitlement_View__c();
        entitlement.OSA_Text__c= '7485123522';
        entitlement.Associated_OSA__c = con.id;
        entitlement.Start_Date__c = Date.newInstance(2021, 4, 1);
        entitlement.End_Date__c = Date.newInstance(2022, 3, 31);
        entitlement.Sale_Price__c = 20.22;
        entitlement.Product_Type__c = 'Software';
        entitlement.DLI_Product__c = prodObj.id;
        entitlement.DLIP_Product__c = prodObj.id;
        entitlement.Billing_Frequency__c = 'Annual';
        insert entitlement;
        
        OP4I_Entitlement_View__c entitlement2 = new OP4I_Entitlement_View__c();
        entitlement2.OSA_Text__c= '7485123522';
        entitlement2.Associated_OSA__c = con.id;
        entitlement2.Start_Date__c = Date.newInstance(2021, 4, 1);
        entitlement2.End_Date__c = Date.newInstance(2022, 3, 31);
        entitlement2.Sale_Price__c = 20.22;
        entitlement2.Product_Type__c = 'Software';
        entitlement2.DLI_Product__c = prodObj.id;
        entitlement2.DLIP_Product__c = prodObj.id;
        entitlement2.Billing_Frequency__c = 'Annual';
        insert entitlement2;
        OP4I_Entitlement_View__c entitlement3 = new OP4I_Entitlement_View__c();
        entitlement3.OSA_Text__c= '7485123522';
        entitlement3.Associated_OSA__c = con.id;
        entitlement3.Start_Date__c = Date.newInstance(2021, 5, 1);
        entitlement3.End_Date__c = Date.newInstance(2022, 6, 31);
        entitlement3.Sale_Price__c = 20.22;
        entitlement3.Product_Type__c = 'Software';
        entitlement3.DLI_Product__c = prodObj.id;
        entitlement3.DLIP_Product__c = prodObj.id;
        entitlement3.Billing_Frequency__c = 'Annual';
        insert entitlement3;
        
        T_OSA__c temp = new T_OSA__c();
        temp.ContractNumber__c = '12345';
        insert temp;
        
        //Creating a T_qtc_Active_Invoice_Line__c Record  
        T_qtc_Active_Invoice_Line__c invLineTemp = new T_qtc_Active_Invoice_Line__c();
        invLineTemp.Internal_ID__c='123456';
        invLineTemp.Line_Sequence_Number__c=null;
        invLineTemp.Price_Level__c=null;
        invLineTemp.Amount_Foreign_Currency__c=null;
        invLineTemp.Tax_Item__c=null;
        invLineTemp.OSA_Contract_Number_RA__c=null;
        invLineTemp.Order_Type__c=null;
        invLineTemp.Tax_Amount__c=null;
        invLineTemp.Document_Number__c=null;
        invLineTemp.Item__c=null;
        invLineTemp.Item_Rate__c=null;
        invLineTemp.Amount_Foreign_Currency_without_Symbol__c=null;
        invLineTemp.Support_Level__c=null;
        invLineTemp.Rev_Rec_Start_Date__c=null;
        invLineTemp.Contract_Item_Start_Date__c=null;
        invLineTemp.Tax__c=null;
        invLineTemp.Line_ID__c=null;
        invLineTemp.Quantity__c=null;
        invLineTemp.Item_Rate_Amount_without_Symbol__c=null;
        invLineTemp.OSA_Contract_Number_from_Salesforce__c='123456';
        invLineTemp.Rev_Rec_End_Date__c=null;
        invLineTemp.Contract_Item_End_Date__c=null;
        invLineTemp.ProServe_Software__c=null;
        invLineTemp.of_Months__c=null;
        invLineTemp.T_OSAMatched__c= False; 
        
        insert invLineTemp;
        T_qtc_Active_Invoice_Line__c invLineTemp1 = new T_qtc_Active_Invoice_Line__c();
        invLineTemp1.Internal_ID__c='12345';
        invLineTemp1.Line_Sequence_Number__c=null;
        invLineTemp1.Price_Level__c=null;
        invLineTemp.Amount_Foreign_Currency__c=null;
        invLineTemp1.Tax_Item__c=null;
        invLineTemp1.OSA_Contract_Number_RA__c=null;
        invLineTemp1.Order_Type__c=null;
        invLineTemp1.Tax_Amount__c=null;
        invLineTemp1.Document_Number__c=null;
        invLineTemp1.Item__c=null;
        invLineTemp1.Item_Rate__c=null;
        invLineTemp1.Amount_Foreign_Currency_without_Symbol__c=null;
        invLineTemp1.Support_Level__c=null;
        invLineTemp1.Rev_Rec_Start_Date__c=null;
        invLineTemp1.Contract_Item_Start_Date__c=null;
        invLineTemp1.Tax__c=null;
        invLineTemp1.Line_ID__c=null;
        invLineTemp1.Quantity__c=null;
        invLineTemp1.Item_Rate_Amount_without_Symbol__c=null;
        invLineTemp1.OSA_Contract_Number_from_Salesforce__c='12345';
        invLineTemp1.Rev_Rec_End_Date__c=null;
        invLineTemp1.Contract_Item_End_Date__c=null;
        invLineTemp1.ProServe_Software__c=null;
        invLineTemp1.of_Months__c=null;
        invLineTemp1.T_OSAMatched__c= False; 
        
        insert invLineTemp1;
        
        
        List<T_Invoice_Sent__c> invoiceSentList = new List<T_Invoice_Sent__c>();
        T_Invoice_Sent__c invoiceSent = new T_Invoice_Sent__c();
        invoiceSent.Internal_Id__c = '12345';
        invoiceSent.count__c = 2;
        invoiceSentList.add(invoiceSent);
        
        T_Invoice_Sent__c invoiceSent2 = new T_Invoice_Sent__c();
        invoiceSent2.Internal_Id__c = '123456';
        invoiceSent2.count__c = 0;
        invoiceSentList.add(invoiceSent2);
        
        insert invoiceSentList;
        
        List<T_Invoice_NewTemp__c> invoiceList = new List<T_Invoice_NewTemp__c>();
        T_Invoice_NewTemp__c invoice = new T_Invoice_NewTemp__c();
        invoice.Internal_ID__c = '12345';
        invoice.OSA_Contract_Number_from_Salesforce__c = '7485123522';
        invoice.Term_Start_Date__c = '2023-01-01';
        invoiceList.add(invoice);
        
        T_Invoice_NewTemp__c invoice2 = new T_Invoice_NewTemp__c();
        invoice2.Internal_ID__c = '123456';
        invoice2.OA_Project_ID__c ='4152266';
        invoice2.Term_Start_Date__c = '2023-01-02';
        invoiceList.add(invoice2);
        
        insert invoiceList;
        
        test.startTest();
        Database.executeBatch(new InvoiceFilterBatch());
        test.stopTest();
    }
}