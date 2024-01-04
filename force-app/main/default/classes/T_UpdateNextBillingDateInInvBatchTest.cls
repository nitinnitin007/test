/**** @name        : T_UpdateNextBillingDateInInvBatchTest
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Test Class for T_UpdateNextBillingDateInInvBatch
******/
@isTest
//Test Cass 
public class T_UpdateNextBillingDateInInvBatchTest {
	@testSetup
    // Test Data Setup
    static void setupData(){
        // Create QtC_Mig_Invoice_Temp_Table__c
        QtC_Mig_Invoice_Temp_Table__c invTemp1 = new QtC_Mig_Invoice_Temp_Table__c();
        invTemp1.Sales_Order_Internal_Id__c = '1234';
        invTemp1.Internal_ID__c = '1234';
        invTemp1.Status__c = 'Open';
        invTemp1.Invoice_Status__c = 'Sent';
        invTemp1.Date__c = System.today();
        invTemp1.Next_Billing_Date__c = System.today()+10;
        insert invTemp1;
        
        // Create QtC_Mig_Invoice_Temp_Table__c
        QtC_Mig_Invoice_Temp_Table__c invTemp2 = new QtC_Mig_Invoice_Temp_Table__c();
        invTemp2.Sales_Order_Internal_Id__c = '1234';
        invTemp2.Internal_ID__c = '1235';
        invTemp2.Status__c = 'Open';
        invTemp2.Invoice_Status__c = Null;
        invTemp2.Date__c = System.today();
        invTemp2.Next_Billing_Date__c = System.today()+10;
        insert invTemp2; 
        
        // Create QtC_Mig_Invoice_Temp_Table__c
        QtC_Mig_Invoice_Temp_Table__c invTemp3 = new QtC_Mig_Invoice_Temp_Table__c();
        invTemp3.Sales_Order_Internal_Id__c = '1234';
        invTemp3.Internal_ID__c = '1234';
        invTemp3.Status__c = 'Open';
        invTemp3.Invoice_Status__c = Null;
        invTemp3.Date__c = System.today();
        invTemp3.Next_Billing_Date__c = System.today()+10;
        insert invTemp3;    
    }
    @isTest
    //Method to execute the test data
    static void updateNextBillingDateInInvBatchTest(){
        //Start test
        Test.startTest();
        //Executing the batch for test data
        T_UpdateNextBillingDateInInvBatch bc = new T_UpdateNextBillingDateInInvBatch();
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        
        //Validating the results
        List<QtC_Mig_Invoice_Temp_Table__c> invList = [Select Id,Next_Billing_Date__c from QtC_Mig_Invoice_Temp_Table__c];
        if(invList.size() > 0 && invList[1].Next_Billing_Date__c != null ){
        System.assertEquals(invList[1].Next_Billing_Date__c,System.today()+10,'Validation Successful');}
    }
}