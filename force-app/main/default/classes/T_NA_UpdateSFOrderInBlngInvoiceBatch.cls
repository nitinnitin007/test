/**** @name        : T_NA_UpdateSFOrderInBlngInvoiceBatch
***** @author  : KPMG
***** @date  : Nov 11th, 2023
***** @description : Update the SF Order Id in Billing Invoices.
******/
//Database.executeBatch(new T_NA_UpdateSFOrderInBlngInvoiceBatch(),200);
public class T_NA_UpdateSFOrderInBlngInvoiceBatch implements Database.Batchable<sObject>,Database.Stateful {
    public database.querylocator start(Database.BatchableContext bc){
     //Query for QtC_Mig_PaymentAlloc_Temp_Table__c  records
       String query = 'SELECT Id,Internal_ID__c, Order__c FROM QtC_Mig_Invoice_Temp_Table__c WHERE Internal_ID__c != NULL AND Order__c != null ';
      return Database.getQueryLocator(query);  
    }
    //Executing the queried records
    public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Temp_Table__c> inv){
        Map<String,blng__Invoice__c> invIdMap = new Map<String,blng__Invoice__c>();
        Map<String,QtC_Mig_Invoice_Temp_Table__c> internalIdInvMap = new Map<String,QtC_Mig_Invoice_Temp_Table__c>();
        //Collecting the Internal_ID__c
        for(QtC_Mig_Invoice_Temp_Table__c tempInv :inv){
            if(!internalIdInvMap.containsKey(tempInv.Internal_ID__c)){
                internalIdInvMap.put(tempInv.Internal_ID__c,tempInv);
            }
        }
        //Get the blng_Invoice__c based on the Internal_ID__c
        List<blng__Invoice__c> blngInvList = [SELECT Id,NS_Inv_Internal_ID__c,blng__Order__c,T_IsMigrated__c 
                                              FROM blng__Invoice__c 
                                              WHERE NS_Inv_Internal_ID__c in: internalIdInvMap.keySet() 
                                              AND NS_Inv_Internal_ID__c != null AND T_IsMigrated__c = true ];
        //Get the blng__Invoice__c records internalid in a map
        for(blng__Invoice__c  invoice:blngInvList ){
            String internalId = invoice.NS_Inv_Internal_ID__c;
            if(!invIdMap.containsKey(internalId)){
                invIdMap.put(internalId,invoice);
            }
        }
        List<blng__Invoice__c> tempInvList = new List<blng__Invoice__c>();
        //Updating the SF Order Id in blng__Invoice__c 
        for(blng__Invoice__c tempInv :blngInvList){
            if(internalIdInvMap.containsKey(tempInv.NS_Inv_Internal_ID__c)){
               	tempInv.blng__Order__c = internalIdInvMap.get(tempInv.NS_Inv_Internal_ID__c).Order__c;
                tempInvList.add(tempInv); 
            }
        }
        //Updating the OrderLineSummary
        if(tempInvList != null){
        update tempInvList;    
        }  
    }
    public void finish(Database.BatchableContext bc){
    }
}