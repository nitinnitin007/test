/**** @name        : T_CreditMemoAllocLookupBatch
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Update the QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c with the blng__CreditNote__c id in the T_CreditNote__c Field.
******/
//Credit Note Header
public class T_CreditMemoAllocLookupBatch implements Database.Batchable<sObject>,Database.Stateful {
    public List<QtC_Mig_Invoice_Temp_Table__c> count = new List<QtC_Mig_Invoice_Temp_Table__c>();
    public Set<String> noInvForLines = new Set<String>();
    public Set<String> noInvForPay = new Set<String>();
    public Set<String> noInvForPayAlloc = new Set<String>();
    public database.querylocator start(Database.BatchableContext bc)
    {
        String queryInvLine = 'Select Id,Applied_To_Internal_ID__c,T_CreditNote__c,Internal_ID__c from QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c '+
            ' where T_Invoice__c = null ';//T_MatchedWithPayCM__C = true and
        return Database.getQueryLocator(queryInvLine);
    }
    public void execute(Database.BatchableContext bc,List<QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c> invsExl)
    {
        Map<String,List<QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c>> ilineInternalIdToInvoiceMap = new Map<String,List<QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c>>();
        for(QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c i : invsExl)
        {//T_Invoice__c,Internal_ID__c --------------------TO DO with CM header Internal Id
            if (ilineInternalIdToInvoiceMap.containsKey(i.Internal_ID__c))
                ilineInternalIdToInvoiceMap.get(i.Internal_ID__c).add(i);
            else ilineInternalIdToInvoiceMap.put(i.Internal_ID__c,new List<QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c>{i});
        }
        List<blng__CreditNote__c> matchingBInv=[Select Id,NS_Credit_Note_Internal_ID__c from blng__CreditNote__c where
                                                T_IsMigrated__c = true
                                                and blng__Account__c != null
                                                and NS_Credit_Note_Internal_ID__c in :ilineInternalIdToInvoiceMap.keySet()];
        Map<String,blng__CreditNote__c> internalIdToBlngIdMap = new Map<String,blng__CreditNote__c>();
        for (blng__CreditNote__c bInv : matchingBInv) {
            internalIdToBlngIdMap.put(bInv.NS_Credit_Note_Internal_ID__c, bInv);
        }
        List<QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c> forUpdate = new List<QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c>();
        for (String internalId : ilineInternalIdToInvoiceMap.keySet()) {//QtC_Mig_Invoice_Lines_Temp_Table__c
            if (internalIdToBlngIdMap.containsKey(internalId)) {
                List<QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c> temp = ilineInternalIdToInvoiceMap.get(internalId);
                for(QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c t : temp){
                    t.T_CreditNote__c = internalIdToBlngIdMap.get(internalId).Id;
                    // t.T_Invoice__c = internalIdToBlngIdMap.get(internalId).blng__RelatedInvoice__c;
                    forUpdate.add(t);
                }
            }
        }
        if(forUpdate.size()>0)
            Database.update(forUpdate);
    }
    public void finish(Database.BatchableContext bc){
    }
}