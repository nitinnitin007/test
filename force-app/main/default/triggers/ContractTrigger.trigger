/********************************************************************************     
*  Name             :  ContractTrigger
*  Author           :  Hiforte Technologies
*  Description      :  1. Populate Billing Account on Contract
*                                  
*  Change history   :
*  Date                Author                          Description
*  06/01/14        Vasu Pulipati                   Created
********************************************************************************/
trigger ContractTrigger on Contract (before insert, after insert, after update) {
    if(trigger.isInsert && trigger.isBefore){
        ContractTriggerHandler.populateBillingAccount(trigger.new);
    }
    
    if(trigger.isAfter && trigger.isInsert) {
        ContractTriggerHandler.afterInsert(trigger.new);
    }
    if(trigger.isAfter && trigger.isUpdate) {
        ContractTriggerHandler.afterUpdate(trigger.new, Trigger.oldMap);
    }
}