/**
 * @description       : This trigger will handle all the events on Address object.
 * @author            : Pankaj Kumar
 * @last modified on  : 07-07-2023
 * @last modified by  : Pankaj Kumar
 * Modifications Log
 * Ver   Date         Author         Modification
 * 1.0   07-07-2023   Pankaj Kumar   Initial Version
**/
trigger AddressTrigger on Address__c (before insert,before update,after insert,after update) {
       
        if(Trigger.isBefore && Trigger.isInsert)
        {
            AddressTriggerHandler.beforeInsert(Trigger.New);
        }
        if(Trigger.isBefore && Trigger.isUpdate)
        {
            AddressTriggerHandler.beforeUpdate(Trigger.New,Trigger.oldMap); 
        }
        if(Trigger.isAfter && Trigger.isInsert)
        {
            AddressTriggerHandler.afterInsert(Trigger.New);
        }
        if(Trigger.isAfter && Trigger.isUpdate)
        {
            AddressTriggerHandler.afterUpdate(Trigger.New,Trigger.oldMap); 
        }
}