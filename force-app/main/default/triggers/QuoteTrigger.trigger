trigger QuoteTrigger on SBQQ__Quote__c (before insert,before update,after insert,after update) {
    if(Trigger.isInsert && Trigger.isBefore){
        QuoteTriggerHandler.processRecordsBeforeInsert(Trigger.new);
        //QuoteTriggerHandler.populateAddress(Trigger.new);
    }

    if(Trigger.isUpdate && Trigger.isBefore){
        QuoteTriggerHandler.processRecordsBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
    
    if(Trigger.isInsert && Trigger.isAfter){
        QuoteTriggerHandler.quoteAfterInsert(trigger.new);
    }
    
    if(Trigger.isUpdate && Trigger.isAfter){
        QuoteTriggerHandler.quoteAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}