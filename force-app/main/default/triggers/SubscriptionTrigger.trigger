trigger SubscriptionTrigger on SBQQ__Subscription__c (after insert,after update) {
    if(Trigger.isInsert && Trigger.isAfter){
        SubscriptionTriggerHandler.subscriptionAfterInsert(trigger.new);
    }
    
    if(Trigger.isUpdate && Trigger.isAfter){
        SubscriptionTriggerHandler.subscriptionAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}