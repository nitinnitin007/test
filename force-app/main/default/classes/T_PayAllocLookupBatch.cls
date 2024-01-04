/**** @Name        : T_PayAllocLookupBatch
***** @Created By  : KPMG
***** @Created On  : Nov 11th, 2023
***** @Description : Update Temp Payment Alloc with blng__Account__c and blng__Invoice__c 
                     Using blng__Invoice__c-NS_Inv_Internal_ID__c 
******/
//Payment lines lookup : Account,Invoice Id
//Update Invoice Id ---- Do we need Acc Id + NS Internal Id ? - No need of AccId
public class T_PayAllocLookupBatch implements Database.Batchable<sObject>,Database.Stateful {
    //Database.executeBatch(new T_PayAllocLookupBatch(),200);
    //The start method to initiate the batch job
    public database.querylocator start(Database.BatchableContext bc)
    {
        // Get the Temp Payment Allocation records.
        String loadInvInternalIdFromPatAlloc = 'SELECT Id,Invoice_Internal_ID__c,T_Invoice__c,T_Account__c FROM QtC_Mig_PaymentAlloc_Temp_Table__c '
                                                +' WHERE Invoice_Internal_ID__c != null';
        return Database.getQueryLocator(loadInvInternalIdFromPatAlloc);
    }
    // The execute method for processing records
    public void execute(Database.BatchableContext bc,List<QtC_Mig_PaymentAlloc_Temp_Table__c>  payAllocExl)
    {
        // Update Payment allocation records based on related blng__Invoice__c records 
        updatePaymentInvoiceFromAllocLookups(payAllocExl);
    }
    //Update Payment allocation records
    public static void updatePaymentInvoiceFromAllocLookups(List<QtC_Mig_PaymentAlloc_Temp_Table__c> payAllocExl)
    {
        //Update the Invoice Id based on the Invoice Number and Opportunity
        List<QtC_Mig_PaymentAlloc_Temp_Table__c> forUpdatePayAllocExl = new List<QtC_Mig_PaymentAlloc_Temp_Table__c>();
        //Account to Payments
        Map<String,List<QtC_Mig_PaymentAlloc_Temp_Table__c>> internalIdToPayAllocExl = new Map<String,List<QtC_Mig_PaymentAlloc_Temp_Table__c>>();
        Map<String,blng__Invoice__c> internalIdToBillingInv = new Map<String,blng__Invoice__c>(); 
        for(QtC_Mig_PaymentAlloc_Temp_Table__c pay : payAllocExl) {
            if (internalIdToPayAllocExl.containsKey(pay.Invoice_Internal_ID__c))//Document_Number__c , Internal_ID__c
                internalIdToPayAllocExl.get(pay.Invoice_Internal_ID__c).add(pay);
            else internalIdToPayAllocExl.put(pay.Invoice_Internal_ID__c,new List<QtC_Mig_PaymentAlloc_Temp_Table__c>{pay});
        }
        // Retrieve related blng__Invoice__c records
        List<blng__Invoice__c> billingInvList = [SELECT Id,blng__Account__c,NS_Inv_Internal_ID__c,NS_Inv_Document_Number__c,T_IsMigrated__c 
                                                 FROM blng__Invoice__c WHERE
                                                 //blng__Account__c in :accIds and 
                                                 NS_Inv_Internal_ID__c in :internalIdToPayAllocExl.keySet() and
                                                 T_IsMigrated__c = true];
        //System.debug('billingInvList:'+billingInvList.size());
        //Internal Id To Billing Inv Map with NS Internal Id
        for(blng__Invoice__c inv : billingInvList)
        {
            //System.debug('Blng contains:'+(inv.NS_Inv_Internal_ID__c));
            if(! internalIdToBillingInv.containsKey(inv.NS_Inv_Internal_ID__c))
                internalIdToBillingInv.put(inv.NS_Inv_Internal_ID__c,inv);
        }
        //Map the Inv Id to InvExcel using the Account Id and Inv Number
        for(String invInternalId : internalIdToPayAllocExl.keySet())
        {
            //System.debug('Contains:'+(payObj.Opportunity__c+'-'+payObj.Invoice_Invoice_Number__c));
            if(internalIdToBillingInv.containsKey(invInternalId))
            {
                //Get the Payments for the Account and Invoice Number records - it may have more than one -Processed,Error,Cancelled
                //System.debug('IN Contains:'+(payObj.blng__Account__c+'-'+payObj.Invoice_Invoice_Number__c));
                List<QtC_Mig_PaymentAlloc_Temp_Table__c> temp = internalIdToPayAllocExl.get(invInternalId);
                if(temp != null){
                for(QtC_Mig_PaymentAlloc_Temp_Table__c payAllocObj : temp){
                    payAllocObj.T_Invoice__c = internalIdToBillingInv.get(invInternalId).Id;
                    payAllocObj.T_Account__c = internalIdToBillingInv.get(invInternalId).blng__Account__c;
                    forUpdatePayAllocExl.add(payAllocObj);
                }
                }
            }
        }
        
        //System.debug('forUpdatePayExl Size:'+QtC_Mig_PaymentAlloc_Temp_Table__c.size());
        if(forUpdatePayAllocExl.size()>0)
            Database.Update(forUpdatePayAllocExl);
    }
    
    // The batch job finishes
    public void finish(Database.BatchableContext bc){ }
    
}