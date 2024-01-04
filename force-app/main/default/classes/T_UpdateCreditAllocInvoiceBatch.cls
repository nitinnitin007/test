/**** @name :T_UpdateCreditAllocInvoiceBatch
***** @author : KPMG
***** @date : Nov 11th, 2023
***** @description : Updating Total Invoice credit from CreditAllocations using InvoiceInternalId in InvTempTable
******/
public class T_UpdateCreditAllocInvoiceBatch implements Database.Batchable<sObject>,Database.Stateful {
    public Database.querylocator start(Database.BatchableContext bc){
        //Quering the Invoice records
        String query = 'SELECT Id, Internal_ID__c,Sales_Order_Internal_Id__c,Total_Invoice_credit__c FROM QtC_Mig_Invoice_Temp_Table__c ';
        return Database.getqueryLocator(query);	
    }
    //Executing the records
    public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Temp_Table__c> invoiceList){
        Map<String,QtC_Mig_Invoice_Temp_Table__c> invoiceIdInvMap = new Map<String,QtC_Mig_Invoice_Temp_Table__c>();
        //Iterating the invoiceList and storing it in Map
        for(QtC_Mig_Invoice_Temp_Table__c inv : invoiceList){
            if(!invoiceIdInvMap.containsKey(inv.Internal_ID__c)){
                invoiceIdInvMap.put(inv.Internal_ID__c,inv);
            }
        }
        //Get Credit Memo Lines using Invoice Internal Id
        List<QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c> creditAllocList = [SELECT Id,Applied_to_Amt_without_Symbol__c,Applied_To_Internal_ID__c 
                                                                             FROM QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c WHERE Applied_To_Internal_ID__c in: invoiceIdInvMap.keyset() ];
        Map<String,Decimal> invInternalIdCreditAllocAmountMap = new Map<String,Decimal>();
        //Iterating credit memo line and storing the amount for InternalId
        for(QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c credit :creditAllocList){
            if(invInternalIdCreditAllocAmountMap.containsKey(credit.Applied_To_Internal_ID__c)){
                Decimal temp = Decimal.valueof(credit.Applied_to_Amt_without_Symbol__c)+invInternalIdCreditAllocAmountMap.get(credit.Applied_To_Internal_ID__c);
                invInternalIdCreditAllocAmountMap.put(credit.Applied_To_Internal_ID__c,temp);
                
            } else {
                invInternalIdCreditAllocAmountMap.put(credit.Applied_To_Internal_ID__c,Decimal.valueof(credit.Applied_to_Amt_without_Symbol__c));
            }
        }
        List<QtC_Mig_Invoice_Temp_Table__c> recordsToUpdate = new List<QtC_Mig_Invoice_Temp_Table__c>();
        //Interting the Invocie to update the credit amount
        for(String invInternalId : invInternalIdCreditAllocAmountMap.keyset()){
            if(invoiceIdInvMap.containskey(invInternalId)){
                QtC_Mig_Invoice_Temp_Table__c tempInv = invoiceIdInvMap.get(invInternalId);
                tempInv.Total_Invoice_credit__c = invInternalIdCreditAllocAmountMap.get(invInternalId);
                recordsToUpdate.add(tempInv);
            }
        }
        //Updating the Invoice records
        update recordsToUpdate;
    }
    public void finish(Database.BatchableContext bc){
    }
}