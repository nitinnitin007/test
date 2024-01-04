/**** @name        : T_PaymentLookupBatchTest
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Test Class for T_PaymentLookupBatch to populate the Invoice Id and Account
******/
@isTest
public class T_PaymentLookupBatchTest {
    //Test Data Setup
   @isTest
    static void setupData(){
         //Creating Account record
        Account acc = new Account();
        acc.name='Test';
        insert acc;
        List<Account> tempAccount = [Select Id,IntApp_Account_Number__c FROM Account];
        
        //Creating QtC_Mig_Payments_Temp_Table__c record
        QtC_Mig_Payments_Temp_Table__c payTemp = new QtC_Mig_Payments_Temp_Table__c();
        payTemp.Account__c = tempAccount[0].IntApp_Account_Number__c;
        payTemp.T_Account__c = tempAccount[0].Id;
        insert payTemp;
        
    	//Method to execute test data
        //Start Test
        Test.startTest();
        //Execute the Batch class to be tested
        T_PaymentLookupBatch bc = new T_PaymentLookupBatch();
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        //Validate Results
        List<QtC_Mig_Payments_Temp_Table__c> tempPayment = [SELECT Id,T_Account__c FROM QtC_Mig_Payments_Temp_Table__c Limit 1];
        List<Account> tempAcc = [SELECT Id FROM Account Limi];
        if(tempAcc.size() > 0 && tempPayment.size() > 0 && tempPayment[0].T_Account__c != null){
            System.assertEquals(tempPayment[0].T_Account__c,tempAcc[0].Id,'Account Id populated successfully');}
    }
}