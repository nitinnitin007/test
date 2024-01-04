trigger InvoiceblngTrigger on blng__Invoice__c (after update) {   
    if(Trigger.isUpdate && Trigger.isAfter){
        InvoiceTriggerHandler.invoiceAfterUpdate(Trigger.new, Trigger.oldMap);
    }
 }