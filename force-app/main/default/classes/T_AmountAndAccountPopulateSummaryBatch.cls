/**** @name        : T_AmountAndAccountPopulateSummaryBatch // File to update Amount and account
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Update the Amount and Account of Order Line DM Summary Records from Qtc_Order_Headers
******/
//Database.executeBatch(new T_AmountAndAccountPopulateSummaryBatch(),200);
public class T_AmountAndAccountPopulateSummaryBatch implements Database.Batchable<sObject>,Database.Stateful {
    public database.querylocator start(Database.BatchableContext bc){//NOPMD
     //Query for T_OrderLineDMSummary__c records
        String query = 'SELECT id,NSOrderID__c,NS_Order_Amount__c,NS_AccountId__c,NS_Order_Date__c,Currency__c,Exchange_Rate__c FROM T_OrderLineDMSummary__c';
      return Database.getQueryLocator(query);  
    }
    //Executing the queried records
    public void execute(Database.BatchableContext bc,List<T_OrderLineDMSummary__c> orderLines){//NOPMD
        Map<String,QTC_Mig_OrderHeaders__c> orderMap = new Map<String,QTC_Mig_OrderHeaders__c>();
        Set<String> orderIdSet = new Set<String>();
        //Collecting the NS orderdid in a set
        for(T_OrderLineDMSummary__c temp :orderLines){
            orderIdSet.add(temp.NSOrderID__c);
        }
        //Get the QTC_Mig_OrderHeaders__c based on the NS Order Ids
        List<QTC_Mig_OrderHeaders__c> orderList = [SELECT Id,Account_ID__c,Internal_ID__c,Amount_Foreign_Currency_without_Symbol__c,
                                                   T_Amount_Without_Symbol__c,Date__c,Currency__c,Exchange_Rate__c 
                                                   FROM QTC_Mig_OrderHeaders__c 
                                                   WHERE Internal_ID__c in: orderIdSet ];
        //Get the OrderHeader records internalid in a map
        for(QTC_Mig_OrderHeaders__c ord : orderList){
            String internalId = ord.Internal_ID__c;
            if(orderMap.containsKey(internalId)!=null){
                orderMap.put(internalId,ord);
            }
        }
        List<T_OrderLineDMSummary__c> tempList = new List<T_OrderLineDMSummary__c>();
        //Updating the orderLineSummary fields
        for(T_OrderLineDMSummary__c temp :orderLines){
            if(orderMap.containsKey(temp.NSOrderID__c)){
                temp.NS_AccountId__c = orderMap.get(temp.NSOrderID__c).Account_ID__c;
                temp.NS_Order_Amount__c = Decimal.valueof(orderMap.get(temp.NSOrderID__c).Amount_Foreign_Currency_without_Symbol__c);
                temp.NS_Order_Date__c = orderMap.get(temp.NSOrderID__c).Date__c;
               	temp.Currency__c = orderMap.get(temp.NSOrderID__c).Currency__c;
               	temp.Exchange_Rate__c = Decimal.valueof(orderMap.get(temp.NSOrderID__c).Exchange_Rate__c);
                tempList.add(temp); 
            }
        }
        //Updating the OrderLineSummary
        if(tempList!=Null){
        update tempList;    
        }  
    }
    public void finish(Database.BatchableContext bc){// Method to Finish
        system.debug('Batch Class Completed');
        //Finish Batch
    }
}