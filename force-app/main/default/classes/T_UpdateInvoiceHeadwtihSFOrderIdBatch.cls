/**** @Name        : T_UpdateInvoiceHeadwtihSFOrderIdBatch
***** @Created By  : KPMG
***** @Created On  : Nov 11th, 2023
***** @Description : Batch to Update InvoiceHeader with SF ORDER Id using  Order-InternalID in T_OrderLineDMSummaryLine Table
******/
public class T_UpdateInvoiceHeadwtihSFOrderIdBatch implements Database.Batchable<sObject>,Database.Stateful {
// Database.executeBatch(new T_UpdateInvoiceHeadwtihSFOrderId(),200);
public database.querylocator start(Database.BatchableContext bc)
    //Collecting the Temp Invoice Records
	{ string query ='Select Id,Order__c,Sales_Order_Internal_Id__c  from QtC_Mig_Invoice_Temp_Table__c ';
     return Database.getQueryLocator(query);
    }
    //Passing the inv records to be executed
     public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Temp_Table__c> invoiceList) {
         Map<String,List<QtC_Mig_Invoice_Temp_Table__c>> salesOrderIdInvoiceMap = new Map<String,List<QtC_Mig_Invoice_Temp_Table__c>>();
         //Get the temp invoices to salesOrderIdInvoiceMap based on the Sales Order Internal Id
         for(QtC_Mig_Invoice_Temp_Table__c inv :invoiceList ){
             if(salesOrderIdInvoiceMap.containsKey(inv.Sales_Order_Internal_Id__c)){
                 salesOrderIdInvoiceMap.get(inv.Sales_Order_Internal_Id__c).add(inv);
             }
             else{
                 salesOrderIdInvoiceMap.put(inv.Sales_Order_Internal_Id__c, new List<QtC_Mig_Invoice_Temp_Table__c> {inv});
             }
         }
         //Collecting T_OrderLineDMSummary__c based on the Order Internal Ids
         List<T_OrderLineDMSummary__c> orderItemList = [SELECT Id,NSOrderID__c,SF_Order_Id__c
                                                        FROM T_OrderLineDMSummary__c 
                                                        WHERE SF_Order_Id__c != null and NSOrderID__c in:salesOrderIdInvoiceMap.keyset()];
         List<QtC_Mig_Invoice_Temp_Table__c> tempInvoicesList = new List<QtC_Mig_Invoice_Temp_Table__c>();
         //Iterating T_OrderLineDMSummary__c to populate SF-OrderId
         for(T_OrderLineDMSummary__c summary :orderItemList ){
             if(salesOrderIdInvoiceMap.containskey(summary.NSOrderID__c)){
                 List<QtC_Mig_Invoice_Temp_Table__c> temp = salesOrderIdInvoiceMap.get(summary.NSOrderID__c);
                 for(QtC_Mig_Invoice_Temp_Table__c tempInv : temp){
               		 tempInv.Order__c = summary.SF_Order_Id__c; 
                     if(!tempInvoicesList.contains(tempInv)){
                    	tempInvoicesList.add(tempInv);       
                     }
                 }            
             }
         }
         //Updating T_OrderLineDMSummary__c 
         if(tempInvoicesList.size() > 0){
         update tempInvoicesList;    
         }
     }
    public void finish(Database.BatchableContext bc){
    }
    
}