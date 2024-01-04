trigger QuoteDocumentTrigger on SBQQ__QuoteDocument__c (before insert,after update) {
    if(Trigger.isInsert && Trigger.isAfter){
        QuoteDocumentTriggerHandler.quotedocumentAfterInsert(trigger.new);
    }
    
    if(Trigger.isUpdate && Trigger.isAfter){
        QuoteDocumentTriggerHandler.quotedocumentAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}