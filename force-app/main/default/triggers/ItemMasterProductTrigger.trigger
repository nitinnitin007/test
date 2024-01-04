trigger ItemMasterProductTrigger on Item_Master_Product__c (after insert,after update) {
if(Trigger.isUpdate && Trigger.isAfter){
        ItemMasterProductTriggerHandler.itemMasterProductAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}