/****@name : T_InvLineProductLookupBatchTest
*****@author : KPMG
*****@date : Nov 11th, 2023
*****@description : Test Class for T_InvLineProductLookupBatch
******/
@isTest
public class T_InvLineProductLookupBatchTest {
    //Test datasetup
    @isTest
    //Method to execute the test data
    static void invLineProductLookupBatchTest(){
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
        
        // Create QtC_Mig_Invoice_Lines_Temp_Table__c
        QtC_Mig_Invoice_Lines_Temp_Table__c qtcmigInvLines = new QtC_Mig_Invoice_Lines_Temp_Table__c();
        qtcmigInvLines.Internal_ID__c = '123456';
        qtcmigInvLines.T_DupProdCode__c = False;
        qtcmigInvLines.Item__c = prodList[0].ProductCode;
        qtcmigInvLines.T_Product__c = prodList[0].Id;
        qtcmigInvLines.T_ProductName__c = prodList[0].Name ;
        insert qtcmigInvLines;
        //Start Test
        Test.startTest();
        //Execute the method to be tested
        T_InvLineProductLookupBatch bc = new T_InvLineProductLookupBatch();
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        //Validate result
        List<QtC_Mig_Invoice_Lines_Temp_Table__c> tempInvLine = [SELECT Id,T_Product__c,T_Product__r.Name from QtC_Mig_Invoice_Lines_Temp_Table__c ];
        if(tempInvLine.size() > 0  && tempInvLine[0].T_Product__c != null)
        {System.assertEquals(prodList[0].Name,tempInvLine[0].T_Product__r.Name,'Product name populated succesfully');}
    }
}