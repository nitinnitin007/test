/**** @Name       : T_InvoiceLookupBatch
***** @Created By  : KPMG
***** @Created On  : Nov 11th, 2023
***** @Description : Update the QtC_Mig_Invoice_Temp_Table__c with Account Id;
******/ 
public class T_InvoiceLookupBatch implements Database.Batchable<sObject>,Database.Stateful {
//Database.executeBatch(new T_InvoiceLookupBatch(),200);    
public List<QtC_Mig_Invoice_Temp_Table__c> count = new List<QtC_Mig_Invoice_Temp_Table__c>();
public Set<String> noInvForLines = new Set<String>();
public Set<String> noInvForPay = new Set<String>(); 
public Set<String> noInvForPayAlloc = new Set<String>();        
public database.querylocator start(Database.BatchableContext bc)
	{  //Get the Temp Invoice records
       String query = 'Select Id,Name__c,Account_ID__c,AccName__c,T_Account__c,Internal_ID__c,Document_Number__c '
                      +' from QtC_Mig_Invoice_Temp_Table__c '
                      +' where Account_ID__c != null ' ;// Document_Number__c != null Order By Document_Number__c';
       return Database.getQueryLocator(query);
    }
   //Executing the queried records for update
    public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Temp_Table__c> invsExl)
    {
        Set<String> invAccNumber = new Set<String>();
        for(QtC_Mig_Invoice_Temp_Table__c i : invsExl)
        {
            //87612:16 removing special characters
            String accIdWithoutSpecChars = i.Account_ID__c.contains(':') ? i.Account_ID__c.Split(':')[0] : 
            													i.Account_ID__c.contains('_') ? i.Account_ID__c.Split('_')[0] : i.Account_ID__c;
            if (i.Account_ID__c != null) {
                invAccNumber.add(accIdWithoutSpecChars);//i.Account_ID__c);
            }
            
        }
        //Querying the Account records using invAccNumber
        List<Account> matchingAccounts=[SELECT Id,Name,IntApp_Account_Number__c FROM Account 
                                        WHERE IntApp_Account_Number__c IN :invAccNumber];
        //Get the Accounts in a map based on the Account Numebr
        Map<String,Id> accountNameToIdMap = new Map<String,Id>();
        for (Account acc : matchingAccounts) {
            accountNameToIdMap.put(acc.IntApp_Account_Number__c, acc.Id);
        }
        
        List<QtC_Mig_Invoice_Temp_Table__c> forUpdate = new List<QtC_Mig_Invoice_Temp_Table__c>();
        //Updating the Invoice records
        for (QtC_Mig_Invoice_Temp_Table__c inv : invsExl) {
            String accIdWithoutSpecChars = inv.Account_ID__c.contains(':') ? inv.Account_ID__c.Split(':')[0] : 
            													inv.Account_ID__c.contains('_') ? inv.Account_ID__c.Split('_')[0] : inv.Account_ID__c;
            if (accountNameToIdMap.containsKey(accIdWithoutSpecChars)) {
                inv.T_Account__c = accountNameToIdMap.get(accIdWithoutSpecChars);
                forUpdate.add(inv);
            }
        }
        //Udating the records in the temp table
        if(forUpdate.size() >0)
        {Update forUpdate;}
    }   
    public void finish(Database.BatchableContext bc){
    }
}