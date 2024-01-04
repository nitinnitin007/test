/**** @name       	: T_CreditNoteInvLookupAtTempQtcBatch
***** @author  	  	: KPMG
***** @date 	  	: Nov 11th, 2023
***** @description 	: Update the CM temp table' New field - Inv Internal Id  - based on the Applied to internal id(Inv Id) from CM Alloc.
******/ 
public class T_CreditNoteInvLookupAtTempQtcBatch implements Database.Batchable<sObject>,Database.Stateful {
    //Database.executeBatch(new ('Invoice'),200);
    public database.querylocator start(Database.BatchableContext bc){
        //Get the QtC_Mig_CreditMemo_Temp_Table__c records
        String query = 'Select Id,Invoice_Internal_Id__c,Internal_ID__c from QtC_Mig_CreditMemo_Temp_Table__c '
                        + 'Where Invoice_Internal_Id__c = null' ;
        return Database.getQueryLocator(query);
    }
    //Method to execute the query
     public void execute(Database.BatchableContext bc,List<QtC_Mig_CreditMemo_Temp_Table__c> creditMemoList)
     {
      //tempInternalIdCreditMemoMap Storing InternalId and List<QtC_Mig_CreditMemo_Temp_Table__c>
      Map<String,List<QtC_Mig_CreditMemo_Temp_Table__c>> tempInternalIdCreditMemoMap = new Map<String,List<QtC_Mig_CreditMemo_Temp_Table__c>>();
         //Storing the records in tempInternalIdCreditMemoMap
         for(QtC_Mig_CreditMemo_Temp_Table__c tempCreditMemo :creditMemoList){
             if(tempInternalIdCreditMemoMap.containsKey(tempCreditMemo.Internal_ID__c)){
                 tempInternalIdCreditMemoMap.get(tempCreditMemo.Internal_ID__c).add(tempCreditMemo);
             } else{
                 tempInternalIdCreditMemoMap.put(tempCreditMemo.Internal_ID__c, new List<QtC_Mig_CreditMemo_Temp_Table__c> {tempCreditMemo});
             }
         }
         //Collecting the QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c records using Applied_To_Internal_ID__c
         List<QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c> tempCreditMemoAllocList = [SELECT Id,Applied_To_Internal_ID__c,Internal_ID__c 
                                                                                      FROM QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c
                                                                                      WHERE Internal_ID__c in :tempInternalIdCreditMemoMap.keyset()
                                                                                      AND Applied_To_Internal_ID__c != null];
		 //Collect the QtC_Mig_CreditMemo_Temp_Table__c for update. 
         List<QtC_Mig_CreditMemo_Temp_Table__c> recordToUpdate = new List<QtC_Mig_CreditMemo_Temp_Table__c>();
         //Updating the InvoiceInternal Id in QtC_Mig_CreditMemo_Temp_Table__c
         for(QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c tempCreditMemoAlloc :tempCreditMemoAllocList ){
             if(tempInternalIdCreditMemoMap.containsKey(tempCreditMemoAlloc.Internal_ID__c)){
                 List<QtC_Mig_CreditMemo_Temp_Table__c> tempCMList = tempInternalIdCreditMemoMap.get(tempCreditMemoAlloc.Internal_ID__c);
                 //Update the Invoid id in CM temp table.
                 if(tempCMList != null){
                 for(QtC_Mig_CreditMemo_Temp_Table__c tempCM : tempCMList){
                     tempCM.Invoice_Internal_Id__c = tempCreditMemoAlloc.Applied_To_Internal_ID__c;
                     recordToUpdate.add(tempCM); 
                 }
                 }
             }
         }
         //Updating the QtC_Mig_CreditMemo_Temp_Table__c
         if(recordToUpdate.size()>0){
             update recordToUpdate;
         }
     }
      //Finishing the batch process
    public void finish(Database.BatchableContext bc){
    }

}