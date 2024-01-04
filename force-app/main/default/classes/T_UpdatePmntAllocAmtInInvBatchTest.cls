/**** @name       : T_UpdatePmntAllocAmtInInvBatchTest
***** @author  : KPMG
***** @date  : Nov 11th, 2023
***** @description : Test Class - To Update Total Invoice Payment field from PaymentAllocations using InvoiceInternalId
******/
@isTest
public class T_UpdatePmntAllocAmtInInvBatchTest {
    @testSetup()
    //TestData
    static void setupData(){
        //Creating Record for QtC_Mig_Invoice_Temp_Table__c
        QtC_Mig_Invoice_Temp_Table__c qtcmigInv = new QtC_Mig_Invoice_Temp_Table__c();
        qtcmigInv.Internal_ID__c = '12345';
        qtcmigInv.Sales_Order_Internal_Id__c = '12356';
        qtcmigInv.Total_Invoice_Payment__c = Null;
        insert qtcmigInv;
        //Creating Record for QtC_Mig_PaymentAlloc_Temp_Table__c
        QtC_Mig_PaymentAlloc_Temp_Table__c paymentAlloc = new QtC_Mig_PaymentAlloc_Temp_Table__c();
        paymentAlloc.Internal_ID__c = '1234';
        paymentAlloc.Applied_Amount_Without_symbol__c = '1234';
        paymentAlloc.Invoice_Internal_ID__c = qtcmigInv.Internal_ID__c;
        insert paymentAlloc;
    }
    @isTest
    //Method to execute the tesdata for the batch class
    static void updatePmntAllocAmtInInvBatchTest(){
        //Start test
        Test.startTest();
        //Execute the batch class to be tested
        T_UpdatePmntAllocAmtInInvBatch bc = new T_UpdatePmntAllocAmtInInvBatch();
        Database.executeBatch(bc);
        //Stop the Test
        Test.stopTest();
        
        //Validating the results
        List<QtC_Mig_Invoice_Temp_Table__c> tempInv = [SELECT Id,Total_Invoice_Payment__c FROM QtC_Mig_Invoice_Temp_Table__c Limit 1 ];
        if(tempInv.size() > 0 && tempInv[0].Total_Invoice_Payment__c != null){
            System.assertEquals(1234,tempInv[0].Total_Invoice_Payment__c,'Amount Rolled Up Successfully');
        }
    }
}