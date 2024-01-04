/**** @name        : T_UpdPndngAndBilledAmtForPartialInvBatch
***** @author  : KPMG
***** @date  : Nov 11th, 2023
***** @description : Switch off Billing trigger before running this batch and switch it on once done,
                    Batch to update the Pending amount and Billed amount for SF-OrderProducts. 
******/
public class T_UpdPndngAndBilledAmtForPartialInvBatch implements Database.Batchable<sObject>,Database.Stateful {
    // Database.executeBatch(new T_UpdPndngAndBilledAmtForPartialInvBatch(),200);
    public database.querylocator start(Database.BatchableContext bc)
    {	//Collecting the records from T_OrderLineDMSummary__c based on the Parially paid and fully paid indcator.
        string query = 'Select Id,SF_Order_Id__c, SF_OrderProduct_Id__c,SF_OrderProdTotal__c,NSOrderID__c,NSOrderLineitemID__c,Pending_Amount_To_Be_Billed__c,OL_with_Partially_paid_invoice__c,OL_Paid_in_Full_Indicator__c,OL_Future_Invoice_Indicator__c,NS_IL_Amount_Total__c,IL_Total_Amount__c,OL_Amount__c,NS_IL_Amount_with_Tax__c '+  
                       ' from T_OrderLineDMSummary__c where ' +
                      // ' SF_OrderProduct_Id__c != null  and (OL_with_Partially_paid_invoice__c = true or OL_Paid_in_Full_Indicator__c = true)';
        				 ' SF_OrderProduct_Id__c != null ';
        return Database.getQueryLocator(query);
    }
    //Passing the records to execute the Batch process
    public void execute(Database.BatchableContext bc,List<T_OrderLineDMSummary__c> tempOrderProdList) {
        Map<String,T_OrderLineDMSummary__c> sfOrderProdIdAndTempOrderMap = new Map<String,T_OrderLineDMSummary__c>();
        //Map<String,T_OrderLineDMSummary__c> sfOrderProdIdAndTempOrderPartialMap = new Map<String,T_OrderLineDMSummary__c>();
       // Map<String,T_OrderLineDMSummary__c> sfOrderProdIdAndTempOrderPaidInFullMap = new Map<String,T_OrderLineDMSummary__c>();
        //Collecting the T_OrderLineDMSummary__c with Partial Indicator and storing it in sfOrderProdIdAndTempOrderPartialMap
        //and full Indicator in sfOrderProdIdAndTempOrderPaidInFullMap
        for(T_OrderLineDMSummary__c summary :tempOrderProdList ){
          /* if(summary.OL_with_Partially_paid_invoice__c == true){
                if(!sfOrderProdIdAndTempOrderPartialMap.containsKey(summary.SF_OrderProduct_Id__c)){
                    sfOrderProdIdAndTempOrderPartialMap.put(summary.SF_OrderProduct_Id__c,summary);
                }  
            } else if(summary.OL_Paid_in_Full_Indicator__c == true){
                if(!sfOrderProdIdAndTempOrderPaidInFullMap.containsKey(summary.SF_OrderProduct_Id__c)){
                    sfOrderProdIdAndTempOrderPaidInFullMap.put(summary.SF_OrderProduct_Id__c,summary);
                }   
            }*/
            if(!sfOrderProdIdAndTempOrderMap.containsKey(summary.SF_OrderProduct_Id__c)){
                    sfOrderProdIdAndTempOrderMap.put(summary.SF_OrderProduct_Id__c,summary);
                }   
        }
       /* //Collecting the OrderItem to be updated from sfOrderProdIdAndTempOrderPartialMap.keyset() 
        List<OrderItem> sfOrderProdList = [SELECT Id,blng__PendingBillings__c,blng__BilledAmountwithouttax__c,T_IsUpdated__c 
                                           FROM OrderItem 
                                           WHERE Id in :sfOrderProdIdAndTempOrderPartialMap.keyset() ];
        
        //Collecting the OrderItem to be updated from sfOrderProdIdAndTempOrderPaidInFullMap.keyset() 
        List<OrderItem> sfOrderProdFullList = [SELECT Id,blng__PendingBillings__c,blng__BilledAmountwithouttax__c,T_IsUpdated__c
                                               FROM OrderItem 
                                               WHERE Id in :sfOrderProdIdAndTempOrderPaidInFullMap.keyset() ];*/
        
        List<OrderItem> sfOrderProdRecords = [SELECT Id,blng__PendingBillings__c,blng__BilledAmountwithouttax__c,T_IsUpdated__c,T_NS_OP_Pending_Balance__c,T_NS_Sales_Order_Internal_ID__c,T_NS_Sales_Order_Line_ID__c,T_NS_OP_Invoice_Status__c,T_NS_OP_Inv_Line_With_Tax__c 
                                             FROM OrderItem 
                                             WHERE Id in :sfOrderProdIdAndTempOrderMap.keyset() ];
        Map<Id,OrderItem> sfOrderProdIdAndOrderProdMapNew = new Map<Id,OrderItem>(sfOrderProdRecords);
       /* Map<Id,OrderItem> sfOrderProdIdAndOrderProdMap = new Map<Id,OrderItem>(sfOrderProdList);
        Map<Id,OrderItem> sfOrderProdIdAndOrderProdFullMap = new Map<Id,OrderItem>(sfOrderProdFullList);*/
        //Updating the OrderItem partial amount and Total Billed amount
         List<OrderItem> summaryList = new List<OrderItem>();
        //List<OrderItem> summaryPendingList = new List<OrderItem>();
        for(T_OrderLineDMSummary__c summary :tempOrderProdList){
            if(sfOrderProdIdAndOrderProdMapNew.containsKey(summary.SF_OrderProduct_Id__c)){
                OrderItem ordItem = sfOrderProdIdAndOrderProdMapNew.get(summary.SF_OrderProduct_Id__c);
                Decimal ilAmountWithoutTax = summary.NS_IL_Amount_Total__c == null ? 0.00 : summary.NS_IL_Amount_Total__c;
                ordItem.blng__BilledAmountwithouttax__c = ilAmountWithoutTax;
                ordItem.blng__PendingBillings__c = (summary.SF_OrderProdTotal__c == null ? 0.00 : summary.SF_OrderProdTotal__c) - ilAmountWithoutTax;
                ordItem.T_NS_Sales_Order_Internal_ID__c = summary.NSOrderID__c;
                ordItem.T_NS_Sales_Order_Line_ID__c = Decimal.valueof(summary.NSOrderLineitemID__c);
                ordItem.T_NS_OP_Inv_Line_With_Tax__c = summary.NS_IL_Amount_with_Tax__c;
                ordItem.T_NS_OP_Pending_Balance__c = summary.Pending_Amount_To_Be_Billed__c;
                ordItem.T_IsUpdated__c = true;
                
            if(summary.OL_Paid_in_Full_Indicator__c == True){
               ordItem.T_NS_OP_Invoice_Status__c = 'Paid in Full';
                }
               else if (summary.OL_with_Partially_paid_invoice__c == True) {
                ordItem.T_NS_OP_Invoice_Status__c = 'Partially Paid';
              } else {
                ordItem.T_NS_OP_Invoice_Status__c = 'Future Invoice';
            }
                summaryList.add(ordItem);
            }
        }
       /* for(T_OrderLineDMSummary__c summary :tempOrderProdList){
            if(sfOrderProdIdAndOrderProdMap.containsKey(summary.SF_OrderProduct_Id__c)){
                OrderItem ordItem = sfOrderProdIdAndOrderProdMap.get(summary.SF_OrderProduct_Id__c);
                //Update only if the order Items's Pending Billing amount is equal to the Summary's Order Line Amount
               // if(ordItem.blng__PendingBillings__c == summary.OL_Amount__c){
               /* Decimal ilAmountWithTax = summary.NS_IL_Amount_with_Tax__c == null ? 0.00 : summary.NS_IL_Amount_with_Tax__c;
                ordItem.blng__BilledAmountwithouttax__c = ilAmountWithTax;
                ordItem.blng__PendingBillings__c = (summary.OL_Amount__c == null ? 0.00 : summary.OL_Amount__c) - ilAmountWithTax;
                Decimal ilAmountWithoutTax = summary.NS_IL_Amount_Total__c == null ? 0.00 : summary.NS_IL_Amount_Total__c;
                ordItem.blng__BilledAmountwithouttax__c = ilAmountWithoutTax;
               // ordItem.blng__PendingBillings__c = (summary.OL_Amount__c == null ? 0.00 : summary.OL_Amount__c) - ilAmountWithoutTax;
                 ordItem.blng__PendingBillings__c = (summary.SF_OrderProdTotal__c == null ? 0.00 : summary.SF_OrderProdTotal__c) - ilAmountWithoutTax;
                 ordItem.T_IsUpdated__c = true;
                summaryPendingList.add(ordItem);
               // }
            }
        }
        //Updating the OrderItem partial amount and Total Billed amount
        List<OrderItem> summaryFullyPaidList = new List<OrderItem>();
        for(T_OrderLineDMSummary__c summary :tempOrderProdList){
            if(sfOrderProdIdAndOrderProdFullMap.containsKey(summary.SF_OrderProduct_Id__c)){
                OrderItem ordItem = sfOrderProdIdAndOrderProdFullMap.get(summary.SF_OrderProduct_Id__c);
                //ordItem.blng__BilledAmountwithouttax__c = Decimal.valueof(temp.NS_IL_Amount_with_Tax__c);
                /*ordItem.blng__PendingBillings__c = 0;
                ordItem.T_IsUpdated__c = true;
                summaryFullyPaidList.add(ordItem);//Same logic used for now for testing
                Decimal ilAmountWithoutTax = summary.NS_IL_Amount_Total__c == null ? 0.00 : summary.NS_IL_Amount_Total__c;
                ordItem.blng__BilledAmountwithouttax__c = ilAmountWithoutTax;
               // ordItem.blng__PendingBillings__c = (summary.OL_Amount__c == null ? 0.00 : summary.OL_Amount__c) - ilAmountWithoutTax;
                 ordItem.blng__PendingBillings__c = (summary.SF_OrderProdTotal__c == null ? 0.00 : summary.SF_OrderProdTotal__c) - ilAmountWithoutTax;
                 ordItem.T_IsUpdated__c = true;
                summaryPendingList.add(ordItem);
            }
        }
        //Update the OrderItem
        if(summaryPendingList.size()>0){
            update summaryPendingList;
        }
        //Update the OrderItem
        if(summaryFullyPaidList.size()>0){
            update summaryFullyPaidList;
        }*/
        if(summaryList.size() > 0)
        {update summaryList;}
    }
    public void finish(Database.BatchableContext bc){
    }
}