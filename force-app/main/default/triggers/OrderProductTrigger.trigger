trigger OrderProductTrigger on OrderItem (after update) {
    if (trigger.isAfter && trigger.isUpdate) {
        OrderProductTriggerHandler.orderProductAfterUpdate(trigger.new,trigger.oldMap);
    }
}