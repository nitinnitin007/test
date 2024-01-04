/**** @name        : T_NA_UpdateSFOrderIdInOLTableBatch
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Update the OL Summary Table's SF Order Id using Internal Id
******/ 
public class T_NA_UpdateSFOrderIdInOLTableBatch implements Database.Batchable<sObject>,Database.Stateful {
    //Database.executeBatch(new T_NA_UpdateSFOrderIdInOLTableBatch(),200);
    public database.querylocator start(Database.BatchableContext bc)
    {	//Query to update orderLine Summary records from temp table
        String query = 'SELECT Id,SF_Order_Id__c, NSOrderID__c FROM T_OrderLineDMSummary__c ';
        return Database.getQueryLocator(query);
    }
    //Method to execute the query
    public void execute(Database.BatchableContext bc,List<T_OrderLineDMSummary__c> tempOrdProdList)
    {
        Map<String,List<T_OrderLineDMSummary__c>> internalIdordProdList = new Map<String,List<T_OrderLineDMSummary__c>>();
        //Storing the OrdProd in Map<NS_Internal_Id,List<OrdProduct>>
        for(T_OrderLineDMSummary__c ordProd :tempOrdProdList ){
            if(internalIdordProdList.containsKey(ordProd.NSOrderID__c)){
                internalIdordProdList.get(ordProd.NSOrderID__c).add(ordProd);
            } 
            else
            {
                internalIdordProdList.put(ordProd.NSOrderID__c, new List<T_OrderLineDMSummary__c> {ordProd});
            }
        }
        //Collecting the Salesforce Orders which has the NS Order Id
        List<Order> tempSFOrd =  [SELECT Id,NetSuite_Sales_order_Internal_Id__c 
                                  FROM Order 
                                  WHERE NetSuite_Sales_order_Internal_Id__c in :internalIdordProdList.keyset()];
        Map<String,Order> netSuiteIdSFOrderIdMap = new Map<String,Order>();
        //Storing the SFOrder in Map<NSOrderId,Order>
        for(Order tempOrd :tempSFOrd ){
            if(!netSuiteIdSFOrderIdMap.containskey(tempOrd.NetSuite_Sales_order_Internal_Id__c)){
                netSuiteIdSFOrderIdMap.put(tempOrd.NetSuite_Sales_order_Internal_Id__c,tempOrd);
            }
        }
        List<T_OrderLineDMSummary__c> tempOLList = new List<T_OrderLineDMSummary__c>();
        //Updating the value of SF order id in temporary Orerline summary table
        for(String internalId :internalIdordProdList.keyset() ){
            if(netSuiteIdSFOrderIdMap.containsKey(internalId)){
                List<T_OrderLineDMSummary__c> ordProdList = internalIdordProdList.get(internalId);
                if(ordProdList != null){
                    for(T_OrderLineDMSummary__c tempOP :ordProdList ){
                        tempOP.SF_Order_Id__c = netSuiteIdSFOrderIdMap.get(internalId).id;
                        tempOLList.add(tempOP);
                    }
                }
            }
        }
        //Updating the OL List
        if(tempOLList.size()>0){
            update tempOLList;
        }
        
    }
    //Finishing the batch process
    public void finish(Database.BatchableContext bc){
        system.debug( 'batch class completed' );
    }
    
}