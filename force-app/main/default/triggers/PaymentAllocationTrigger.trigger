trigger PaymentAllocationTrigger on blng__PaymentAllocationInvoiceLine__c (after insert,after update, before Insert) {
    if(Trigger.isInsert && Trigger.isAfter){
        PaymentAllocationTriggerHandler.paymentAllocationAfterInsert(trigger.new);
    }
    
    if(Trigger.isUpdate && Trigger.isAfter){
        PaymentAllocationTriggerHandler.paymentAllocationAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}