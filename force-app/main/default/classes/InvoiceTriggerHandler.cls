public class InvoiceTriggerHandler {   
    public Static void invoiceAfterUpdate(list<blng__Invoice__c> invoiceNewList, Map<Id,blng__Invoice__c> invoiceOldMap) {
        List<blng__Invoice__c> invoiceEligibleList = new List<blng__Invoice__c>();
        if(!invoiceNewList.isEmpty())
        {
            for(blng__Invoice__c invoiceObj : invoiceNewList)
            {
                if(invoiceObj.blng__InvoiceStatus__c!=invoiceOldMap.get(invoiceObj.id).blng__InvoiceStatus__c && invoiceObj.blng__InvoiceStatus__c == 'Posted')
                {
                    invoiceEligibleList.add(invoiceObj);
                }
                if(invoiceObj.Sync_NetSuite__c == true && invoiceObj.Sync_NetSuite__c!=invoiceOldMap.get(invoiceObj.id).Sync_NetSuite__c){
                    invoiceEligibleList.add(invoiceObj);  
                }
            }    
        } 
        IntegrationUtility.publishsObjectRecords(invoiceEligibleList,'blng__Invoice__c');
    }
}