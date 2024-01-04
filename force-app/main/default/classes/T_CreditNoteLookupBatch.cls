/**** @name       	: T_CreditNoteLookupBatch
***** @author  		: KPMG
***** @date 		: Nov 11th, 2023
***** @description  : Update Credit Note's blngInvoice's Account. 
					  Using Account Intappaccount Number					
******/ 
public class T_CreditNoteLookupBatch implements Database.Batchable<sObject>,Database.Stateful {
    //Database.executeBatch(new T_CreditNoteLookupBatch(),200);
     public database.querylocator start(Database.BatchableContext bc)
	{	//Get the Temp Credit Momo records 
        //String query = 'SELECT Id,T_Invoice__c,T_Account__c,Invoice_Internal_Id__c FROM QtC_Mig_CreditMemo_Temp_Table__c '+' WHERE Invoice_Internal_Id__c != null';
        String query = 'SELECT Id, Account_Id__c,T_Account__c FROM QtC_Mig_CreditMemo_Temp_Table__c WHERE Account_Id__c != Null';
        return Database.getQueryLocator(query);
    }
    //Method to execute the query
    public void execute(Database.BatchableContext bc,List<QtC_Mig_CreditMemo_Temp_Table__c> creditMemoList)
    {	
        //AccountNumber and List<QtC_Mig_CreditMemo_Temp_Table__c>
        Map<String,List<QtC_Mig_CreditMemo_Temp_Table__c>> tempCreditMemoMap =new Map<String,List<QtC_Mig_CreditMemo_Temp_Table__c>>();
        List<QtC_Mig_CreditMemo_Temp_Table__c> tempCreditMemoList = new List<QtC_Mig_CreditMemo_Temp_Table__c>();
        //Removing the AccountNumber subsidary
        for(QtC_Mig_CreditMemo_Temp_Table__c tempCM :creditMemoList)
        {
            if (tempCM.Account_Id__c != null) 
            {	
                //Cleaning the Account Number
            	String accIdWithoutSpecChars = tempCM.Account_Id__c.contains(':') ? tempCM.Account_Id__c.Split(':')[0] : 
            													tempCM.Account_Id__c.contains('_') ? tempCM.Account_Id__c.Split('_')[0] : tempCM.Account_Id__c;
            	tempCM.Account_Id__c = accIdWithoutSpecChars;
              	tempCreditMemoList.add(tempCM);
            }
        }
        //Inserting the tempCreditMemoMap
        for(QtC_Mig_CreditMemo_Temp_Table__c tempCM : tempCreditMemoList)
        {
            if(tempCreditMemoMap.containsKey(tempCM.Account_Id__c))
            {
                tempCreditMemoMap.get(tempCM.Account_Id__c).add(tempCM);
            }
            else
            {
                tempCreditMemoMap.put(tempCM.Account_Id__c,new List<QtC_Mig_CreditMemo_Temp_Table__c> {tempCM});
            }
        }
        //Collecting the account for tempCreditMemoMap.keySet
        List<Account> tempAccList = [SELECT Id,IntApp_Account_Number__c FROM Account 
                                     WHERE IntApp_Account_Number__c in: tempCreditMemoMap.keySet()
                                     AND IntApp_Account_Number__c != NULL];
        //Collecting the records to Update
        List<QtC_Mig_CreditMemo_Temp_Table__c> recordsToUpdate = new List<QtC_Mig_CreditMemo_Temp_Table__c>();
        //Mapping the Account ID
        for(Account acc : tempAccList)
        {	
            if(tempCreditMemoMap.containsKey(acc.IntApp_Account_Number__c))
            {	
                //Collecting the CreditMemo records for Account Number
            	List<QtC_Mig_CreditMemo_Temp_Table__c> creditMList = tempCreditMemoMap.get(acc.IntApp_Account_Number__c);
            	//Updating the Account Id
                if(creditMList != null){
                for(QtC_Mig_CreditMemo_Temp_Table__c tempCM : creditMList)
                {
                    tempCM.T_Account__c = acc.Id;
                    recordsToUpdate.add(tempCM);
                }
                }
            }
        }
        //Updating the records
        if(recordsToUpdate.size()>0){
            update recordsToUpdate;
        }
    }
    public void finish(Database.BatchableContext bc){
        System.debug('Process Completed');
    }
    /*
    public void execute(Database.BatchableContext bc,List<QtC_Mig_CreditMemo_Temp_Table__c> creditMemoList)
     {
      //Get the Credit Memo records for the Invoice InternalId 
      Map<String,List<QtC_Mig_CreditMemo_Temp_Table__c>> tempInternalIdCreditMemoMap = new Map<String,List<QtC_Mig_CreditMemo_Temp_Table__c>>();
         for(QtC_Mig_CreditMemo_Temp_Table__c tempCreditMemo :creditMemoList){
             if(tempInternalIdCreditMemoMap.containsKey(tempCreditMemo.Invoice_Internal_Id__c)){
                 tempInternalIdCreditMemoMap.get(tempCreditMemo.Invoice_Internal_Id__c).add(tempCreditMemo);
             } 
             else
             {
                 tempInternalIdCreditMemoMap.put(tempCreditMemo.Invoice_Internal_Id__c, new List<QtC_Mig_CreditMemo_Temp_Table__c> {tempCreditMemo});
             }
         }
       //Collect Billing Invoice from the based on the Temp Credit Memo records Invoice Internal Id 
         List<blng__Invoice__c> tempInvList = [SELECT Id,NS_Inv_Internal_ID__c,blng__Account__c,T_IsMigrated__c FROM blng__Invoice__c 
                                               WHERE NS_Inv_Internal_ID__c in :tempInternalIdCreditMemoMap.keySet() 
                                               AND blng__Account__c!= Null 
                                               AND NS_Inv_Internal_ID__c != Null AND T_IsMigrated__c = true];
        //Temp List to Update the QtC_Mig_CreditMemo_Temp_Table__c
        List<QtC_Mig_CreditMemo_Temp_Table__c> recordsToUpdate = new List<QtC_Mig_CreditMemo_Temp_Table__c>();
        //Updating the Account and Invoice in QtC_Mig_CreditMemo_Temp_Table__c 
         for(blng__Invoice__c tempInv :tempInvList ){
             if(tempInternalIdCreditMemoMap.containsKey(tempInv.NS_Inv_Internal_ID__c)){
                 List<QtC_Mig_CreditMemo_Temp_Table__c> tempCrMemoList = tempInternalIdCreditMemoMap.get(tempInv.NS_Inv_Internal_ID__c);
                 if(tempCrMemoList != null){
                 for(QtC_Mig_CreditMemo_Temp_Table__c tempCrMemo : tempCrMemoList){
                     if(tempCrMemo.T_Invoice__c == Null){
                         tempCrMemo.T_Invoice__c = tempInv.Id;
                         tempCrMemo.T_Account__c = tempInv.blng__Account__c;
                         recordsToUpdate.add(tempCrMemo);
                     }
                 }
                 }
             }
         }
         //Updating the records
         if(recordsToUpdate.size()>0){
             update recordsToUpdate;
         }
     }
	*/
    //Finishing the batch process
    /*
    public void finish(Database.BatchableContext bc){
        System.debug('Process Completed');
    }
*/
}