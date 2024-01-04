/**** @Name        : T_InvoiceLinesLookupBatch
***** @Created By  : KPMG
***** @Created On  : Nov 11th, 2023
***** @Description : Update the Invoice lines lookup field in Invoice Lines : Invoice Id
******/
//Database.executeBatch(new T_InvoiceLinesLookupBatch(),200);
public class T_InvoiceLinesLookupBatch implements Database.Batchable<sObject>,Database.Stateful {
public List<QtC_Mig_Invoice_Temp_Table__c> count = new List<QtC_Mig_Invoice_Temp_Table__c>();
public Set<String> noInvForLines = new Set<String>();
public Set<String> noInvForPay = new Set<String>(); 
public Set<String> noInvForPayAlloc = new Set<String>();   
public database.querylocator start(Database.BatchableContext bc)
	{	
    	//Qyureying the Inv Lines Records
      String queryInvLine = 'Select Id,T_Invoice__c,Internal_ID__c  from QtC_Mig_Invoice_Lines_Temp_Table__c '+
                           ' where T_Invoice__c = null ';//T_MatchedWithPayCM__C = true and 
      return Database.getQueryLocator(queryInvLine);
    }
    //Executing the queried records
    public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Lines_Temp_Table__c> invsExl)
    {
        Map<String,List<QtC_Mig_Invoice_Lines_Temp_Table__c>> ilineInternalIdToInvoiceMap = new Map<String,List<QtC_Mig_Invoice_Lines_Temp_Table__c>>();
        //Get the Invoice lines in a map based on the Invoice Inetrnal Id
        for(QtC_Mig_Invoice_Lines_Temp_Table__c invLine : invsExl)
        {
            if (ilineInternalIdToInvoiceMap.containsKey(invLine.Internal_ID__c)) 
            {ilineInternalIdToInvoiceMap.get(invLine.Internal_ID__c).add(invLine);}
            else {ilineInternalIdToInvoiceMap.put(invLine.Internal_ID__c,new List<QtC_Mig_Invoice_Lines_Temp_Table__c>{invLine});}
        }
        //Get the Billing Invoices based on the Invoice Internal Ids
        List<blng__Invoice__c> matchingBInv=[SELECT Id,NS_Inv_Internal_ID__c,T_IsMigrated__c,blng__Account__c FROM blng__Invoice__c WHERE
                                             T_IsMigrated__c = true 
                                             AND blng__Account__c != null 
                                             AND NS_Inv_Internal_ID__c in :ilineInternalIdToInvoiceMap.keySet()];
        Map<String,Id> internalIdToBlngIdMap = new Map<String,Id>();
        //Storing the Inv Internal Id and Invoice records in a Map
        for (blng__Invoice__c bInv : matchingBInv) {
            internalIdToBlngIdMap.put(bInv.NS_Inv_Internal_ID__c, bInv.Id);
        }
        List<QtC_Mig_Invoice_Lines_Temp_Table__c> forUpdate = new List<QtC_Mig_Invoice_Lines_Temp_Table__c>();
        //Update the  the Invoice Id for the Invoice Lines Id
        for (String internalId : ilineInternalIdToInvoiceMap.keySet()) {
            if (internalIdToBlngIdMap.containsKey(internalId)) {
                List<QtC_Mig_Invoice_Lines_Temp_Table__c> temp = ilineInternalIdToInvoiceMap.get(internalId);
                if(temp != null){
                    for(QtC_Mig_Invoice_Lines_Temp_Table__c invLine : temp){
                    invLine.T_Invoice__c = internalIdToBlngIdMap.get(internalId);
                    forUpdate.add(invLine);
                }
                }
            }
        }
        //Updating the record with the Invoice Id
        if(forUpdate.size() > 0 )
        Update forUpdate;
    }     
public void finish(Database.BatchableContext bc){
// Batch Finish
}
}