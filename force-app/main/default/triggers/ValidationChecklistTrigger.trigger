/**
 * @description       : Trigger on Validation_Checklist__c on before insert & update
 * @author            : Dipali Pedgulwar
 * @last modified on  : 04-09-2023
 * @last modified by  : Dipali Pedgulwar
 * Modifications Log
 * Ver   Date         Author         Modification
 * 1.0   04-09-2023   Dipali Pedgulwar   Initial Version
**/
trigger ValidationChecklistTrigger on Validation_Checklist__c (before insert, before update) {
    //count number of checkboxes checked on create/update of Validation_Checklist__c records
	if( ( Trigger.isInsert || Trigger.isUpdate ) && Trigger.isBefore){
        ValidationChecklistHandler.countChecklist(Trigger.new);
    }
}