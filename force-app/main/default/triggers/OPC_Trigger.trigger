trigger OPC_Trigger on Opportunity_Product_Component__c (before insert, after insert, after update, after delete) {
    if(trigger.isInsert && trigger.isBefore) OPC_TriggerHandler.beforeInsert(trigger.new);	
	if(trigger.isInsert && trigger.isAfter) OPC_TriggerHandler.afterInsert(trigger.new);
    if(trigger.isUpdate && trigger.isAfter) OPC_TriggerHandler.afterUpdate(trigger.new, trigger.oldMap);
    if(trigger.isDelete && trigger.isAfter) OPC_TriggerHandler.afterDelete(trigger.old);
}