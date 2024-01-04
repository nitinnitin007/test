/**** @name        : T_UpdateOverRideNBDateBatch
***** @author      : KPMG
***** @date        : Dec 11th, 2023
***** @description : Update Override Next Billing Date in OrderProducts from Invoice Temp table
******/
public class T_UpdateOverRideNBDateBatch  implements Database.Batchable<sObject>,Database.Stateful {
    public static final Set<String> EXCLUDED_BILLING_FREQUENCIES = new Set<String>{'Annual', 'Annually'};
    // Database.executeBatch(new T_UpdateOverRideNBDateBatch(),200);
    public Database.queryLocator start(Database.BatchableContext bc)
    {	//Collecting the Invoice Records
        String query = 'SELECT Id,Sales_Order_Internal_Id__c,Internal_ID__c,Status__c, Invoice_Status__c,Date__c ,Next_Billing_Date__c '+
            ' FROM QtC_Mig_Invoice_Temp_Table__c where Next_Billing_Date__c != Null AND Sales_Order_Internal_Id__c != Null ';
        return Database.getQueryLocator(query);
    }
    //Method to execute the records
    public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Temp_Table__c> invList) {
        //Map for stroing Invoices
        Map<Id,QtC_Mig_Invoice_Temp_Table__c> invMap = new Map<Id,QtC_Mig_Invoice_Temp_Table__c>(invList);
        Map<String,Date> orderIdDateMap = new Map<String,Date>();
        //Storing the SalesOrderId and Next Billing Date in Map
        for(Id invId : invMap.keySet()){
            orderIdDateMap.put((invMap.get(invId).Sales_Order_Internal_Id__c),(invMap.get(invId).Next_Billing_Date__c));
        }
        
        //Collecting Orderline Summary records
        List<T_OrderLineDMSummary__c> orderLineList = [SELECT Id,NSOrderID__c,SF_Order_Id__c,SF_OrderProduct_Id__c,OL_with_Partially_paid_invoice__c 
                                                       FROM T_OrderLineDMSummary__c 
                                                       WHERE SF_OrderProduct_Id__c != Null AND OL_with_Partially_paid_invoice__c = TRUE 
                                                       AND NSOrderID__c in:orderIdDateMap.keySet() ];
        //Map for storing OrderItem and OrderLine Summary Record
        Map<Id,T_OrderLineDMSummary__c> sfIdOLMap = new Map<Id,T_OrderLineDMSummary__c>();
        if(orderLineList.size()>0){
            for(T_OrderLineDMSummary__c sfOLine :orderLineList){
                sfIdOLMap.put(sfOLine.SF_OrderProduct_Id__c,sfOLine);
            }    
        }
        //Collecting OrderItem Records using the Id
        List<OrderItem> orderItems = [SELECT Id,blng__OverrideNextBillingDate__c,SBQQ__BillingFrequency__c FROM OrderItem 
                                      WHERE SBQQ__BillingFrequency__c NOT IN :EXCLUDED_BILLING_FREQUENCIES AND Id in:sfIdOLMap.keySet()];
        //List to update the Orderitem
        List<OrderItem> recordsToUpdate = new List<OrderItem>();
        //Updating the Next Billing Date using Map
        if(orderItems.size()>0){
        	for(OrderItem ordLine :orderItems){
            	if(sfIdOLMap.containsKey(ordLine.Id)){
                	ordLine.blng__OverrideNextBillingDate__c =  orderIdDateMap.get(sfIdOLMap.get(ordLine.Id).NSOrderID__c);
                	recordsToUpdate.add(ordLine);
            } 
        }    
        }
        //Updating the Records
        if(recordsToUpdate.size()>0){
            update recordsToUpdate;
        }
    }
    //Batch Job finishes
    public void finish(Database.BatchableContext bc){
        System.debug('Batch class finishes');
    }
}