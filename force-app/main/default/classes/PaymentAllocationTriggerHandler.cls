public class PaymentAllocationTriggerHandler {
    public static void paymentAllocationAfterInsert(list<blng__PaymentAllocationInvoiceLine__c> payNewList) {
        list<blng__PaymentAllocationInvoiceLine__c> paymentAllocList = new list<blng__PaymentAllocationInvoiceLine__c>();
        if(!payNewList.isEmpty()){
            for(blng__PaymentAllocationInvoiceLine__c payAlloc : payNewList){
                if(payAlloc.blng__Unallocated__c == false){
                    paymentAllocList.add(payAlloc);
                }
            }
        }
        IntegrationUtility.publishsObjectRecords(paymentAllocList,'blng__PaymentAllocationInvoiceLine__c');
    }
    
    public static void paymentAllocationAfterUpdate(list<blng__PaymentAllocationInvoiceLine__c> payNewList,Map<Id,blng__PaymentAllocationInvoiceLine__c> payOldMap) {
        list<blng__PaymentAllocationInvoiceLine__c> paymentAllocList = new list<blng__PaymentAllocationInvoiceLine__c>();
        if(!payNewList.isEmpty()){
            for(blng__PaymentAllocationInvoiceLine__c payAlloc : payNewList){
                if(payAlloc.blng__Unallocated__c != payOldMap.get(payAlloc.Id).blng__Unallocated__c && payAlloc.blng__Unallocated__c == true){
                    paymentAllocList.add(payAlloc);
                }
                if(payAlloc.Sync_NetSuite__c == true && payAlloc.Sync_NetSuite__c!=payOldMap.get(payAlloc.id).Sync_NetSuite__c){
                    paymentAllocList.add(payAlloc);
                }
            }
        }
        IntegrationUtility.publishsObjectRecords(paymentAllocList,'blng__PaymentAllocationInvoiceLine__c');
    }
}