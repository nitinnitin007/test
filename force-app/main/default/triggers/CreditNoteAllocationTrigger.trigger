trigger CreditNoteAllocationTrigger on blng__CreditNoteAllocation__c (after insert,after update, before Insert) {
    if(Trigger.isInsert && Trigger.isAfter){
        CreditNoteAllocationTriggerHandler.creditNoteAllocationAfterInsert(trigger.new);
    }
    
    if(Trigger.isUpdate && Trigger.isAfter){
        CreditNoteAllocationTriggerHandler.creditNoteAllocationAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}