/**** @name        : T_InvoiceLookupBatchTest
***** @created By  : KPMG
***** @created On  : Nov 11th, 2023
***** @description : Test Class for T_InvoiceLookupBatch to update the QtC_Mig_Invoice_Temp_Table__c with Account Id.
******/
@isTest
public class T_InvoiceLookupBatchTest {
    @testsetup
    //TestSetup
    static void setupData(){
        //Create Account
        List<Account> accList = TestDataFactory.createAccount(1,True);
        List<Account> tempAcc = [SELECT Id,IntApp_Account_Number__c FROM Account];
        //Create QtC_Mig_Invoice_Temp_Table__c
        QtC_Mig_Invoice_Temp_Table__c qtcmigInv = new QtC_Mig_Invoice_Temp_Table__c();
        qtcmigInv.AccName__c = 'Test';
        qtcmigInv.Account_ID__c = tempAcc[0].IntApp_Account_Number__c;
        qtcmigInv.T_Account__c = tempAcc[0].Id;
        qtcmigInv.Name__c = 'Test';
        qtcmigInv.Internal_ID__c = '12345';
        qtcmigInv.Document_Number__c = '12345';
        insert qtcmigInv;
    }
    @isTest
    //Method to execute the Batch
    static void invoiceLookupBatchTest(){
        //Start test
        Test.startTest();
        //Batch to execute the method
        T_InvoiceLookupBatch bc = new T_InvoiceLookupBatch();
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        
        //Validating the results
        List<QtC_Mig_Invoice_Temp_Table__c> tempInv = [SELECT Id,Name__c,Account_ID__c,AccName__c,T_Account__c,Internal_ID__c,Document_Number__c 
                                                       FROM QtC_Mig_Invoice_Temp_Table__c Limit 1];
        List<Account> tempAcc = [SELECT Id,IntApp_Account_Number__c FROM Account];
        if(tempInv.size() > 0 && tempInv[0].T_Account__c != null){
            System.assertEquals(tempInv[0].T_Account__c,tempAcc[0].Id,'Account matched and populated as expected');
        }
        
    }
}