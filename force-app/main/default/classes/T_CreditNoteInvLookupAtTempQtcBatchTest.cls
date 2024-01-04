/**** @name        : T_CreditNoteInvLookupAtTempQtcBatchTest
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Test Class for T_CreditNoteInvLookupAtTempQtcBatch 
                     Update the CM temp table' New field - Inv Internal Id , based on the Applied to internal id(Inv Id) from CM Alloc.
******/
@isTest
public class T_CreditNoteInvLookupAtTempQtcBatchTest {
    //Test Data Setup
    @testSetup
    public static void setupData(){
        
        //Test Record For QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c
        QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c creditNoteLine = new QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c();
        creditNoteLine.Applied_To_Internal_ID__c = '1234567';
        creditNoteLine.Internal_ID__c = '12345';
        insert creditNoteLine;
         //Test Record for QtC_Mig_CreditMemo_Temp_Table__c
        QtC_Mig_CreditMemo_Temp_Table__c creditNote = new QtC_Mig_CreditMemo_Temp_Table__c();
        creditNote.Internal_ID__c = '12345';
        //creditNote.Invoice_Internal_Id__c = creditNoteLine.Applied_To_Internal_ID__c;
        insert creditNote;
    }
    @isTest
    //Method to execute the test data
    public static void creditNoteInvLookupAtTempQtcBatchTest(){
        //Start Test
        Test.startTest();
        //Executing the method to be tested
        T_CreditNoteInvLookupAtTempQtcBatch bc = new T_CreditNoteInvLookupAtTempQtcBatch();
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        //Validating the results
        List<QtC_Mig_CreditMemo_Temp_Table__c> tempCreditRec = [SELECT Id,Internal_ID__c,Invoice_Internal_Id__c FROM QtC_Mig_CreditMemo_Temp_Table__c Limit 1];
        List<QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c> tempCreditLineAlloc = [SELECT id,Applied_To_Internal_ID__c,Internal_ID__c FROM QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c Limit 1];
        if(tempCreditRec.size() > 0 && tempCreditRec[0].Invoice_Internal_Id__c != null && tempCreditLineAlloc.size() > 0 && tempCreditLineAlloc[0].Applied_To_Internal_ID__c != null){
            System.assertEquals(tempCreditRec[0].Invoice_Internal_Id__c,tempCreditLineAlloc[0].Applied_To_Internal_ID__c,'Invoice Internal Id Populated Successfully');
        }
    }
    

}