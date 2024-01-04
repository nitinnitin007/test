global with sharing class InvoiceSentBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = '' 
            + ' SELECT Id'
            + '      , Internal_Id__c'
            + '      , Count__c'
            + '   FROM T_Invoice_Sent__c'
            + '  WHERE Internal_Id__c != null'
            + '    AND Count__c > 0';  
            
        return Database.getQueryLocator(query);  
    }

    global void execute(Database.BatchableContext bc, List<T_Invoice_Sent__c> invoiceSentList){
        set<string> internalIds = new set<string>();
        for (T_Invoice_Sent__c invoiceSent : invoiceSentList) {
            internalIds.add(invoiceSent.Internal_Id__c);
        }

        if (!internalIds.isEmpty()) {
            List<T_Invoice_NewTemp__c> invoiceList = [
                SELECT Id
                     , internal_Id__c
                     , invoice_sent__c
                  FROM T_Invoice_NewTemp__c
                 WHERE internal_Id__c IN :internalIds
            ];
            if (!invoiceList.isEmpty()) {
                for (T_Invoice_NewTemp__c invoice : invoiceList) {
                    invoice.invoice_sent__c = true;
                }

                HandleCustomException.logDatabaseErrors(Database.update(invoiceList,false));
            }
        }
    }

    global void finish(Database.BatchableContext bc){
       
    }
}