trigger OpportunityProductTrigger on OpportunityLineItem (after delete, after insert, after undelete, after update) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OpportunityProductTriggerHandler.afterInsert(Trigger.New);
        } 
        
        if (Trigger.isUpdate) {
            OpportunityProductTriggerHandler.afterUpdate(Trigger.New, trigger.oldMap);
        } 
        
        if (Trigger.isDelete) {
            OpportunityProductTriggerHandler.afterDelete(trigger.old);
        }
        
        if (Trigger.isUnDelete) {
            OpportunityProductTriggerHandler.afterUnDelete(trigger.new);
        }
    }
}