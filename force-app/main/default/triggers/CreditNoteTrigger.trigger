trigger CreditNoteTrigger on blng__CreditNote__c (after update) {
    if(Trigger.isUpdate && Trigger.isAfter){
        CreditNoteTriggerHandler.creditNoteAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}