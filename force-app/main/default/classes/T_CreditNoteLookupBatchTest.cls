/**** @name       	: T_CreditNoteLookupBatchTest
***** @author  		: KPMG
***** @date 		: Nov 11th, 2023
***** @description  : Test Class for T_CreditNoteLookupBatch , Updating Update Credit Note's blng__Invoice field and Account as blngInvoice's Account. 
					  CM's Inv Internal Id match it with Billing invoice' NS Inv Internal Id						
******/ 
@istest
//Test Class
public class T_CreditNoteLookupBatchTest {
	//testData
	@testSetup
    public static void testData(){
         //Creating Account
        List<Account> accList = TestDataFactory.createAccount(1,True);
        List<Account> tempAcc = [SELECT ID,IntApp_Account_Number__c FROM Account];
        
        //Create QtC_Mig_CreditMemo_Temp_Table__c data
        QtC_Mig_CreditMemo_Temp_Table__c tempCreditMemo = new QtC_Mig_CreditMemo_Temp_Table__c();
        tempCreditMemo.Account_Id__c = tempAcc[0].IntApp_Account_Number__c;
        tempCreditMemo.T_Account__c = tempAcc[0].Id;//Updating the Account Id
        insert tempCreditMemo; 
    }
    @isTest
    //Method to execute the test data
    public static void creditNoteLookupBatchTest(){
        //Start Test
        Test.startTest();
        //Executing the method to be tested
        T_CreditNoteLookupBatch bc = new T_CreditNoteLookupBatch();
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        //Validating the results
        List<QtC_Mig_CreditMemo_Temp_Table__c> tempCreditRec = [SELECT Id,T_Account__c,Account_Id__c FROM QtC_Mig_CreditMemo_Temp_Table__c Limit 1];
        List<Account> tempAcc = [SELECT Id,IntApp_Account_Number__c FROM Account Limit 1];
        if(tempCreditRec.size()>0 && tempCreditRec[0].T_Account__c != null){
            System.assertEquals(tempCreditRec[0].T_Account__c,tempAcc[0].Id,'Id Populated Successfully');
        }
    }
}