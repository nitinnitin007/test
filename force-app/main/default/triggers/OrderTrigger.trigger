trigger OrderTrigger on Order (after update) {    
    if(Trigger.isUpdate && Trigger.isAfter){
        OrderTriggerHandler.orderAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}