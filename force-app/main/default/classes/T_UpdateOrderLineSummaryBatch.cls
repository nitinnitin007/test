/**** @Name        : T_UpdateOrderLineSummaryBatch
***** @Created By  : KPMG
***** @Created On  : Nov 11th, 2023
***** @Description : Populate the SF_order_id and Sf_orderProduct_id in the Summary Temp table for Reporting.
******/
public class T_UpdateOrderLineSummaryBatch implements Database.Batchable<sObject>,Database.Stateful {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //Get the Order Line Summary records
        String query = 'SELECT Id, NS_AccountId__c, NS_OrderLine_Item__c, Quantity__c,OL_StartDate__c,OL_End_Date__c FROM T_OrderLineDMSummary__c'; 
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<T_OrderLineDMSummary__c> orderLineSummaryList){
        Map<String, OrderItem> orderProductMap = new Map<String,OrderItem>();
        Map<String, T_OrderLineDMSummary__c> orderLineDMSummaryMap = new Map<String, T_OrderLineDMSummary__c>();
        //Get the Account Numbers map to filter the OrderItem
        Set<String> accountNumbersFromSummary = new Set<String>();
        // Collect data from T_OrderLineDMSummary in a map with key as Account Number + ProductCode+Qty+StartDate+EndDate
        for (T_OrderLineDMSummary__c summary : orderLineSummaryList) {
            accountNumbersFromSummary.add(summary.NS_AccountId__c);
            String keyWithAccProdCodeQtyDates = summary.NS_AccountId__c + '-'+summary.NS_OrderLine_Item__c+ '-'+summary.Quantity__c+'-'+summary.OL_StartDate__c+'-'+summary.OL_End_Date__c;            
            orderLineDMSummaryMap.put(keyWithAccProdCodeQtyDates,summary);    
        }
        //Get the Salesforce OrderItem Records based on the Summary Account Numbers.
        List<OrderItem> orderProducts = [SELECT Id,Product2.ProductCode, Order.Account.IntApp_Account_Number__c,OrderId,Quantity,ServiceDate,EndDate
                                         FROM OrderItem 
                                         WHERE Order.Account.IntApp_Account_Number__c in :accountNumbersFromSummary];
        //Get the  Order Products in a map with key as Account Number + ProductCode+Qty+StartDate+EndDate
        for (OrderItem orderItem : orderProducts) {
            String keyWithAccProdCodeQtyDates = orderItem.Order.Account.IntApp_Account_Number__c+'-' + orderItem.Product2.ProductCode+'-' + orderItem.Quantity+'-' +orderItem.ServiceDate+'-'+orderItem.EndDate;
            orderProductMap.put(keyWithAccProdCodeQtyDates, orderItem);                
        }
 	   
        List<T_OrderLineDMSummary__c> recordsToUpdate = new List<T_OrderLineDMSummary__c>();
        // Compare and update records
        for (String combinedKey : orderLineDMSummaryMap.keySet()) {
            if (orderProductMap.containsKey(combinedKey)) {
                OrderItem orderProduct = orderProductMap.get(combinedKey);
                T_OrderLineDMSummary__c summary = orderLineDMSummaryMap.get(combinedKey);
                summary.SF_OrderProduct_Id__c = String.valueOf(orderProduct.Id);
                summary.SF_Order_Id__c = String.valueOf(orderProduct.OrderId);
                recordsToUpdate.add(summary); 
            }
        }
        // Update T_OrderLineDMSummary records   
        update recordsToUpdate;
    }
    public void finish(Database.BatchableContext bc) {
    }    
}