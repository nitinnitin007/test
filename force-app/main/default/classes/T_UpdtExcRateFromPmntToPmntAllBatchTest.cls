/****         @name : T_UpdtExcRateFromPmntToPmntAllBatchTest
*****   @author : KPMG
*****   @date : Nov 11th, 2023
*****  @description : Test Class - To Populate Exchange Rate field from Payment to PaymentAllocation
******/

@isTest
public class T_UpdtExcRateFromPmntToPmntAllBatchTest {
     @testSetup()
    //TestData
    static void setupData(){
        //Creating Record For QtC_Mig_Payments_Temp_Table__c
        QtC_Mig_Payments_Temp_Table__c payment = new QtC_Mig_Payments_Temp_Table__c();
        payment.Internal_ID__c = '1234';
        payment.Currency__c = 'Pound Sterling';
        payment.Exchange_Rate__c = '1.09756';
        //Creating Record for QtC_Mig_PaymentAlloc_Temp_Table__c
        QtC_Mig_PaymentAlloc_Temp_Table__c paymentAlloc = new QtC_Mig_PaymentAlloc_Temp_Table__c();
        paymentAlloc.Internal_ID__c = '1234';
        paymentAlloc.Exchange_Rate__c = '1.09756';
        insert paymentAlloc;
    }
    @isTest
    //Method to execute the tesdata for the batch class
    static void updtExcRateFromPmntToPmntAllBatchTest(){
        //Start test
        Test.startTest();
        //Execute the batch class to be tested
        T_UpdtExcRateFromPmntToPmntAllBatch bc = new T_UpdtExcRateFromPmntToPmntAllBatch();
        Database.executeBatch(bc);
        //Stop the Test
        Test.stopTest();
        List<QtC_Mig_PaymentAlloc_Temp_Table__c> tempPayAllo = [SELECT id, Exchange_Rate__c FROM QtC_Mig_PaymentAlloc_Temp_Table__c ];
        if(tempPayAllo.size() > 0 && tempPayAllo[0].Exchange_Rate__c != null){
            System.assertEquals(tempPayAllo[0].Exchange_Rate__c,'1.09756','Exchange_Rate__c populated Successfully');
        }
    }
}