/**** @name        : T_InvoiceLinesLookupBatchTest
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Test Class for T_InvoiceLinesLookupBatch
******/
@isTest
public class T_InvoiceLinesLookupBatchTest {
@testSetup
    // Test Data Setup
    static void setupData(){
        //Create QtC_Mig_Invoice_Lines_Temp_Table__c
        QtC_Mig_Invoice_Lines_Temp_Table__c qtcmigInvLines = new QtC_Mig_Invoice_Lines_Temp_Table__c();
        qtcmigInvLines.Internal_ID__c = '123456';
		qtcmigInvLines.T_Invoice__c = Null;
        insert qtcmigInvLines;
        //Create Account
        Account acc = new Account();
        acc.name='Test';
        insert acc;
        //Create Billing Invoice
        blng__Invoice__c blngInvoice = new blng__Invoice__c();
        blngInvoice.NS_Inv_Internal_ID__c = qtcmigInvLines.Internal_ID__c;
        blngInvoice.T_IsMigrated__c = true;
        blngInvoice.blng__Account__c = acc.Id;
        insert blngInvoice;
    }
@isTest
    //Method to execute the testData
    static void invoiceLinesLookupBatchTest(){
        //Start test
        Test.startTest();
        //Executing the batch for test data
        T_InvoiceLinesLookupBatch bc = new T_InvoiceLinesLookupBatch();
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        
        //Validating the results
        List<QtC_Mig_Invoice_Lines_Temp_Table__c> tempList = [SELECT Id,T_Invoice__c FROM QtC_Mig_Invoice_Lines_Temp_Table__c Limit 1];
        List<blng__Invoice__c> billingInv = [SELECT Id from blng__Invoice__c Limit 1];
        if(tempList.size() > 0 && billingInv.size() >0  && tempList[0].T_Invoice__c != null){
            System.assertEquals(tempList[0].T_Invoice__c,billingInv[0].Id,'Invoice Id populated successfully');
        }
    }
}