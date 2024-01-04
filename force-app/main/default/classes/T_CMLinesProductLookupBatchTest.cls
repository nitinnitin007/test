/**** @name       	: T_CMLinesProductLookupBatchTest
***** @author  		: KPMG
***** @date 		: Nov 11th, 2023
***** @description  : Test Class for T_CMLinesProductLookupBatch - Updating the Product in QTC CMLines Temp Table
*/
@isTest
public class T_CMLinesProductLookupBatchTest {
//Method to execute T_DupProdCode__c to True
       @isTest
       static void productLookupBatchTest(){
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
        Product2 prod = new Product2();
        prod.Name='Intapp Risk & Compliance';
        prod.ProductCode='BU-01670-2';
        prod.IsActive=true;
        prod.blng__BillingRule__c = blngRule.Id;
        prod.blng__TaxRule__c = taxRule.Id;
        prod.blng__RevenueRecognitionRule__c = revRecogRule.Id;
        prod.SBQQ__BillingFrequency__c = 'Annual';
        prod.SBQQ__BillingType__c = 'Advance';
        prod.SBQQ__ChargeType__c = 'Recurring';
        insert prod;  
           
        //Creating Record QtC_Mig_CreditMemoLines_Temp_Table__c
        QtC_Mig_CreditMemoLines_Temp_Table__c tempCML = new QtC_Mig_CreditMemoLines_Temp_Table__c();
        tempCML.Item__c = 'LEGACY. BU-01670-2';
        tempCML.T_ProductName__c = prod.Name;
        tempCML.Internal_ID__c = '1234';
        tempCML.T_Product__c = prod.Id;
        tempCML.T_DupProdCode__c = false;
        insert tempCML;
        
        //Start Test
        Test.startTest();
        //Executing the method to be tested
        T_CMLinesProductLookupBatch bc = new T_CMLinesProductLookupBatch();
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        //Validating the results
        List<QtC_Mig_CreditMemoLines_Temp_Table__c> tempCreditRec = [SELECT Id,T_ProductName__c,T_Product__c FROM QtC_Mig_CreditMemoLines_Temp_Table__c Limit 1];
        if(tempCreditRec.size() > 0 && tempCreditRec[0].T_ProductName__c != null){
            System.assertEquals(tempCreditRec[0].T_ProductName__c,'Intapp Risk & Compliance','Id Populated Successfully');
        }
    }
    @isTest
    //Method to execute T_DupProdCode__c to True
    static void dupProdCodeTest(){
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
        //Creating Record QtC_Mig_CreditMemoLines_Temp_Table__c
        QtC_Mig_CreditMemoLines_Temp_Table__c tempCML = new QtC_Mig_CreditMemoLines_Temp_Table__c();
        tempCML.Item__c = 'Test';
        tempCML.T_ProductName__c = prodList[0].Name;
        tempCML.Internal_ID__c = '1234';
        tempCML.T_Product__c = prodList[0].Id;
        insert tempCML;
        
        //Start Test
        Test.startTest();
        //Executing the method to be tested
        T_CMLinesProductLookupBatch bc = new T_CMLinesProductLookupBatch();
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        //Validating the results
        List<QtC_Mig_CreditMemoLines_Temp_Table__c> tempCreditRec = [SELECT Id,T_ProductName__c,T_Product__c,T_DupProdCode__c FROM QtC_Mig_CreditMemoLines_Temp_Table__c ];
        if(tempCreditRec.size() > 0 && tempCreditRec[0].T_ProductName__c != null && tempCreditRec[0].T_DupProdCode__c != null){
            System.assertEquals(false,tempCreditRec[0].T_DupProdCode__c,'Duplicate Flag is false');
        }
    }
}