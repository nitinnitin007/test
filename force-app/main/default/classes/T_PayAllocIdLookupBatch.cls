/**** @Name :T_PayAllocIdLookupBatch
***** @Created By : KPMG
***** @Created On : Nov 11th, 2023
***** @Description : Batch to lookup the QtC_Mig_PaymentAlloc_Temp_Table__c with blng__Account__c and blng__Payment__c using blng__Payment__c-NS_Payment_Internal_ID__c in QtC_Mig_PaymentAlloc_Temp_Table__c
******/
//Payment lines lookup : Payment Id
//Update Payment Id 
public class T_PayAllocIdLookupBatch implements Database.Batchable<sObject>,Database.Stateful {
    //Database.executeBatch(new T_PayAllocIdLookupBatch(),200);
    public database.querylocator start(Database.BatchableContext bc)
    {
        //Collecting the records from QtC_Mig_PaymentAlloc_Temp_Table__c
        String loadInvInternalIdFromPatAlloc = 'SELECT Id,T_Account__c,Invoice_Internal_ID__c,T_Invoice__c,T_Payment__c,Internal_Id__c '
                                               +' FROM QtC_Mig_PaymentAlloc_Temp_Table__c WHERE '
                                               +' Internal_Id__c != null and T_Invoice__c != null and T_Account__c != null';
        return Database.getQueryLocator(loadInvInternalIdFromPatAlloc);//queryPayment);
    }
    
    //public void execute(Database.BatchableContext BC,List<QtC_Mig_Payments_Temp_Table__c>  payExl)
    public void execute(Database.BatchableContext bc,List<QtC_Mig_PaymentAlloc_Temp_Table__c>  payAllocExl)
    {
        //Update Pay Alloc - 
        updatePaymentInvoiceFromAllocLookups(payAllocExl);
        //updatePaymentExcelInvoiceLookups(payExl);//Line items CPQ Prod Name,Prod Id update
    }
    //Update Internal Id from Alloc
    public static void updatePaymentInvoiceFromAllocLookups(List<QtC_Mig_PaymentAlloc_Temp_Table__c> payAllocExl)
    {
        //Update the Invoice Id based on the Invoice Number and Opportunity
        List<QtC_Mig_PaymentAlloc_Temp_Table__c> forUpdatePayAllocExl = new List<QtC_Mig_PaymentAlloc_Temp_Table__c>();
        //Account to Payments
        Map<String,List<QtC_Mig_PaymentAlloc_Temp_Table__c>> internalIdToPayAllocExl = new Map<String,List<QtC_Mig_PaymentAlloc_Temp_Table__c>>();
        Map<String,blng__Payment__c> internalIdToBillingPay = new Map<String,blng__Payment__c>(); 
        for(QtC_Mig_PaymentAlloc_Temp_Table__c pay : payAllocExl) {
            if (internalIdToPayAllocExl.containsKey(pay.Internal_Id__c))//Document_Number__c , Internal_ID__c
                internalIdToPayAllocExl.get(pay.Internal_Id__c).add(pay);
            else internalIdToPayAllocExl.put(pay.Internal_Id__c,new List<QtC_Mig_PaymentAlloc_Temp_Table__c>{pay});
        }
        //Collecting the records from blng__Payment__c
        List<blng__Payment__c> billingPayList = [SELECT Id,blng__Account__c,NS_Payment_Internal_ID__c,T_IsMigrated__c 
                                                 FROM blng__Payment__c WHERE
                                                 //blng__Account__c in :accIds and 
                                                 NS_Payment_Internal_ID__c in :internalIdToPayAllocExl.keySet() AND T_IsMigrated__c = true];
        //and T_IsMigrated__c = true];
        //System.debug('billingPayList:'+billingPayList.size());
        //Opp To Billing Inv Map with Zuora Invoice Number
        for(blng__Payment__c pay : billingPayList)
        {
            //System.debug('Blng contains:'+(pay.NS_Payment_Internal_ID__c));
            if(! internalIdToBillingPay.containsKey(pay.NS_Payment_Internal_ID__c))
                internalIdToBillingPay.put(pay.NS_Payment_Internal_ID__c,pay);
        }
        //Map the Inv Id to InvExcel using the Account Id and Inv Number
        for(String invInternalId : internalIdToPayAllocExl.keySet())
        {
            //System.debug('Contains:'+(payObj.Opportunity__c+'-'+payObj.Invoice_Invoice_Number__c));
            if(internalIdToBillingPay.containsKey(invInternalId))
            {
                //Get the Payments for the Account and Invoice Number records - it may have more than one -Processed,Error,Cancelled
                //System.debug('IN Contains:'+(payObj.blng__Account__c+'-'+payObj.Invoice_Invoice_Number__c));
                List<QtC_Mig_PaymentAlloc_Temp_Table__c> temp = internalIdToPayAllocExl.get(invInternalId);
                for(QtC_Mig_PaymentAlloc_Temp_Table__c payAllocObj : temp){
                    payAllocObj.T_Payment__c = internalIdToBillingPay.get(invInternalId).Id;
                    payAllocObj.T_Account__c = internalIdToBillingPay.get(invInternalId).blng__Account__c;
                    forUpdatePayAllocExl.add(payAllocObj);
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