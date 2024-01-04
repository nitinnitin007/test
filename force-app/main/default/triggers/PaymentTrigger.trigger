trigger PaymentTrigger on blng__Payment__c (after insert,after update) { 
    if(Trigger.isInsert && Trigger.isAfter){
        PaymentTriggerHandler.PaymentAfterInsert(trigger.new);
    } 
    if(Trigger.isUpdate && Trigger.isAfter){
        PaymentTriggerHandler.PaymentAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}