/**** @name :T_UpdateOrderProdWithInvLineDateBatch
***** @author : KPMG
***** @date : Dec 11th, 2023
***** @description : Update the SF Order Product with Max Invoice Lines Date and Invoice Lines Count.
******/
//Database.executeBatch(new T_UpdateOrderProdWithInvLineDateBatch(),200);
public class  T_UpdateOrderProdWithInvLineDateBatch implements Database.Batchable<sObject>,Database.Stateful {
     public Database.queryLocator start(Database.BatchableContext bc)
    {   //Get the Order Item
        String query = 'SELECT Id,Order.NetSuite_Sales_order_Internal_Id__c,Quantity,' 
                       +' T_Mig_InvLines_Max_StartDate__c,T_Mig_InvLines_Max_EndDate__c,T_Mig_InvLines_Count__c  '
                       +' FROM OrderItem WHERE Order.NetSuite_Sales_order_Internal_Id__c != null ';
        return Database.getQueryLocator(query);
    }
    //Method to execute the query
     public void execute(Database.BatchableContext bc,List<OrderItem> orderItems)
    {
        getTheMaxInvoiceLineDatesForOrderItem(orderItems);
    }
    //Helper
    public static void getTheMaxInvoiceLineDatesForOrderItem(List<OrderItem> orderItems){
        if(orderItems.size() > 0){
            List<OrderItem> forUpdate = new List<OrderItem>();
            //Get the Order Product Ids
            Map<String,OrderItem> orderProdMap = new Map<String,OrderItem>(orderItems);
            Set<String> orderIds = new Set<String>();
            for(OrderItem ordItem : orderItems){
                orderIds.add(ordItem.OrderId);
            }
            //Get the Billing Invoice lines per Order Product
            Map<String,List<blng__InvoiceLine__c>> orderProdToInvLinesMap = new Map<String,List<blng__InvoiceLine__c>>();
            //Get the Billing Invoice Lines for the Order Products
            List<blng__InvoiceLine__c> blngInvLinesList = [SELECT Id,blng__OrderProduct__c,Order__c,NS_Sales_Order_Internal_Id__c,
                                                           blng__StartDate__c,blng__EndDate__c
                                               			   FROM blng__InvoiceLine__c 
                                                           WHERE blng__OrderProduct__c != null 
                                                           AND blng__OrderProduct__c in :orderProdMap.keySet()
                                                           AND Order__c != null AND Order__c in :orderIds
                                                           AND NS_Sales_Order_Internal_Id__c != null
                                                           AND blng__StartDate__c != null AND blng__EndDate__c != null
                                                           AND T_IsMigrated__c = true];
              if(blngInvLinesList.size() > 0){
                //Get the Order Product to Invoice Lines Mapping
                for(blng__InvoiceLine__c invLine : blngInvLinesList){
                    if(orderProdToInvLinesMap.containsKey(invLine.blng__OrderProduct__c)){
                        orderProdToInvLinesMap.get(invLine.blng__OrderProduct__c).add(invLine);
                    }
                    else {orderProdToInvLinesMap.put(invLine.blng__OrderProduct__c,new List<blng__InvoiceLine__c>{invLine});}
                }
                //Get the matched Order Product and Update the Invoice Lines count and Max dates
                for(OrderItem orderProd : orderItems){
                    if(orderProdToInvLinesMap.containsKey(orderProd.Id)){
						blng__InvoiceLine__c invLineWithMaxDate = getTheMaxDateLine(orderProdToInvLinesMap.get(orderProd.Id));
                        if(invLineWithMaxDate != null){
                            //Update Order Product
                            orderProd.T_Mig_InvLines_Max_StartDate__c = invLineWithMaxDate.blng__StartDate__c;
                            orderProd.T_Mig_InvLines_Max_EndDate__c = invLineWithMaxDate.blng__EndDate__c;
                            orderProd.T_Mig_InvLines_Count__c = orderProdToInvLinesMap.get(orderProd.Id) != null ? (orderProdToInvLinesMap.get(orderProd.Id)).size() : 0 ;
                            forUpdate.add(orderProd);
                        }
                    }
                }
            }
            if(forUpdate.size() > 0){update forUpdate;}
        }
    }
    //Helper
    //Get the Maximum date Invoice Lines 
    public static blng__InvoiceLine__c getTheMaxDateLine(List<blng__InvoiceLine__c> invLines){
          blng__InvoiceLine__c maxDateLine = null;
          if(invLines.size() > 0){
           for(blng__InvoiceLine__c line : invLines){
                if(maxDateLine == null){maxDateLine = line;}
               else {
                   if(line.blng__StartDate__c > maxDateLine.blng__StartDate__c && line.blng__EndDate__c > maxDateLine.blng__EndDate__c){maxDateLine = line;}
               }
            }
        }
        return maxDateLine;
    }
     public void finish(Database.BatchableContext bc){
    }
}