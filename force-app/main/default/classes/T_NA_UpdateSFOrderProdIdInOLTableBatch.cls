/**** @name       : T_NA_UpdateSFOrderProdIdInOLTableBatch
***** @author     : KPMG
***** @date       : Nov 11th, 2023
***** @description : Update the OL Summary Table's SF OrderProd Id using Key - 
                   *  Without Amount : SFOrderId,Item,Quantity,StartDate
                   *  With Amount : SFOrderId,Item,Quantity,Amount
                   *  With Approximate Amount For One Dollar match by: +/- .01 cents : SFOrderId,Item,Quantity AND +/ .03 Amount
******/ 
//Database.executeBatch(new T_NA_UpdateSFOrderProdIdInOLTableBatch('withAmount'),200);
//Database.executeBatch(new T_NA_UpdateSFOrderProdIdInOLTableBatch('withoutAmount'),200);
//Database.executeBatch(new T_NA_UpdateSFOrderProdIdInOLTableBatch(1.00),200);//Enter upto 1.00 for the current requirement
public class T_NA_UpdateSFOrderProdIdInOLTableBatch implements Database.Batchable<sObject>,Database.Stateful {
    public String amountFilter;
    public Decimal approximateCentIncrement = null;
    public T_NA_UpdateSFOrderProdIdInOLTableBatch(String withOrWithoutAmount){
        this.amountFilter = withOrWithoutAmount;
    }
    public T_NA_UpdateSFOrderProdIdInOLTableBatch(Decimal approximateAmount){
        this.approximateCentIncrement = approximateAmount;
    }
    public database.querylocator start(Database.BatchableContext bc)
    {   //Get the orderLine Summary records to update SF Order Prod Id
        String query = 'SELECT Id,SF_OrderProduct_Id__c,SF_Order_Id__c,OL_Amount__c ,NS_OrderLine_Item__c,Quantity__c,OL_StartDate__c,T_BillingFrequency__c,SF_OrderProdTotal__c,' 
                       +' NS_OL_Amount_with_Tax__c  '
                       +' FROM T_OrderLineDMSummary__c WHERE SF_Order_Id__c != null ';//and OL_StartDate__c != null';
        return Database.getQueryLocator(query);
    }
    //Method to execute the query
     public void execute(Database.BatchableContext bc,List<T_OrderLineDMSummary__c> tempOrdProdList)
    {
        if(amountFilter == 'withAmount')
        {withAmount(tempOrdProdList);}
        else if(amountFilter == 'withoutAmount') {withoutAmount(tempOrdProdList);}
        else if(approximateCentIncrement != null)
        {withApproximateAmount(tempOrdProdList,approximateCentIncrement);}
    }
    public static void withAmount(List<T_OrderLineDMSummary__c> tempOrdProdList){
        Map<String,List<T_OrderLineDMSummary__c>> comboKeyToOrdProdList = new Map<String,List<T_OrderLineDMSummary__c>>();
        Set<String> orderIdSet = new Set<String>();
        //Storing the OrdProd in Map<NS_Internal_Id,List<OrdProduct>>
        for(T_OrderLineDMSummary__c ordProd :tempOrdProdList ){
            //Combination of key with SF Order Id, NS Product Code, Quantity, OL Amount
            if(ordProd.NS_OrderLine_Item__c != null && ordProd.Quantity__c != null && ordProd.OL_Amount__c != null){
            String orderIDKey = ordProd.SF_Order_Id__c+'-'+ordProd.NS_OrderLine_Item__c+'-'+ordProd.Quantity__c+'-'+ ordProd.OL_Amount__c;
            if(comboKeyToOrdProdList.containsKey(orderIDKey)){
                comboKeyToOrdProdList.get(orderIDKey).add(ordProd);
            } 
            else
            {
                comboKeyToOrdProdList.put(orderIDKey, new List<T_OrderLineDMSummary__c> {ordProd});
            }
            }
            //Get the Order Ids
            orderIdSet.add(ordProd.SF_Order_Id__c);
        }
        //Collecting the Salesforce Order products which has the NS Order Id
        List<OrderItem> tempSFOrdItem =  [SELECT Id,OrderId,Order.NetSuite_Sales_order_Internal_Id__c,Quantity,
                                          Product2.ProductCode,TotalPrice,ServiceDate,SBQQ__BillingFrequency__c
                                          FROM OrderItem 
                                          WHERE OrderId in :orderIdSet
                                          AND Quantity != NULL AND Product2.ProductCode != NULL AND TotalPrice != NULL];
        Map<String,OrderItem> netSuiteIdSFOrderProdIdMap = new Map<String,OrderItem>();
        //Combination of key with SF Order Id, SF Product Code, Quantity, OL Start Date
        for(OrderItem tempOrdItem :tempSFOrdItem ){
            String sfOrderIdKey = tempOrdItem.OrderId+'-'+tempOrdItem.Product2.ProductCode+'-'+tempOrdItem.Quantity+'-'+ tempOrdItem.TotalPrice;
            if(!netSuiteIdSFOrderProdIdMap.containskey(sfOrderIdKey)){
                netSuiteIdSFOrderProdIdMap.put(sfOrderIdKey,tempOrdItem);
            }
        }
        List<T_OrderLineDMSummary__c> tempOLList = new List<T_OrderLineDMSummary__c>();
        //Updating the value of SF order product Id in OrderLineDMSummary
        for(String internalId :comboKeyToOrdProdList.keyset() ){
            if(netSuiteIdSFOrderProdIdMap.containsKey(internalId)){
                List<T_OrderLineDMSummary__c> ordProdList = comboKeyToOrdProdList.get(internalId);
                if(ordProdList != null){
                for(T_OrderLineDMSummary__c tempOP :ordProdList ){
                    tempOP.SF_OrderProduct_Id__c = netSuiteIdSFOrderProdIdMap.get(internalId).Id;
                    tempOP.SF_OrderProdTotal__c = netSuiteIdSFOrderProdIdMap.get(internalId).TotalPrice;
                    tempOP.T_BillingFrequency__c = netSuiteIdSFOrderProdIdMap.get(internalId).SBQQ__BillingFrequency__c;
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
    public static void withoutAmount(List<T_OrderLineDMSummary__c> tempOrdProdList){
        Map<String,List<T_OrderLineDMSummary__c>> comboKeyToOrdProdList = new Map<String,List<T_OrderLineDMSummary__c>>();
        Set<String> orderIdSet = new Set<String>();
        //Storing the OrdProd in Map<NS_Internal_Id,List<OrdProduct>>
        for(T_OrderLineDMSummary__c ordProd :tempOrdProdList ){
            //Combination of key with SF Order Id, NS Product Code, Quantity, OL Start Date
            if(ordProd.NS_OrderLine_Item__c != null && ordProd.Quantity__c != null && ordProd.OL_StartDate__c != null){
            String orderIDKey = ordProd.SF_Order_Id__c+'-'+ordProd.NS_OrderLine_Item__c+'-'+ordProd.Quantity__c+'-'+ ordProd.OL_StartDate__c;
            if(comboKeyToOrdProdList.containsKey(orderIDKey)){
                comboKeyToOrdProdList.get(orderIDKey).add(ordProd);
            } 
            else
            {
                comboKeyToOrdProdList.put(orderIDKey, new List<T_OrderLineDMSummary__c> {ordProd});
            }
            }
            //Get the Order Ids
            orderIdSet.add(ordProd.SF_Order_Id__c);
        }
        //Collecting the Salesforce Order products which has the NS Order Id
        List<OrderItem> tempSFOrdItem =  [SELECT Id,OrderId,Order.NetSuite_Sales_order_Internal_Id__c,Quantity,
                                          Product2.ProductCode,TotalPrice,ServiceDate,SBQQ__BillingFrequency__c 
                                          FROM OrderItem 
                                          WHERE OrderId in :orderIdSet
                                          AND Quantity != NULL AND Product2.ProductCode != NULL AND ServiceDate != NULL];
        Map<String,OrderItem> netSuiteIdSFOrderProdIdMap = new Map<String,OrderItem>();
        //Combination of key with SF Order Id, SF Product Code, Quantity, OL Start Date
        for(OrderItem tempOrdItem :tempSFOrdItem ){
            String sfOrderIdKey = tempOrdItem.OrderId+'-'+tempOrdItem.Product2.ProductCode+'-'+tempOrdItem.Quantity+'-'+ tempOrdItem.ServiceDate;
            if(!netSuiteIdSFOrderProdIdMap.containskey(sfOrderIdKey)){
                netSuiteIdSFOrderProdIdMap.put(sfOrderIdKey,tempOrdItem);
            }
        }
        List<T_OrderLineDMSummary__c> tempOLList = new List<T_OrderLineDMSummary__c>();
        //Updating the value of SF order product Id in OrderLineDMSummary
        for(String internalId :comboKeyToOrdProdList.keyset() ){
            if(netSuiteIdSFOrderProdIdMap.containsKey(internalId)){
                List<T_OrderLineDMSummary__c> ordProdList = comboKeyToOrdProdList.get(internalId);
                if(ordProdList != null){
                for(T_OrderLineDMSummary__c tempOP :ordProdList ){
                    tempOP.SF_OrderProduct_Id__c = netSuiteIdSFOrderProdIdMap.get(internalId).Id;
                    tempOP.SF_OrderProdTotal__c = netSuiteIdSFOrderProdIdMap.get(internalId).TotalPrice;
                    tempOP.T_BillingFrequency__c = netSuiteIdSFOrderProdIdMap.get(internalId).SBQQ__BillingFrequency__c;
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
    public static void withApproximateAmount(List<T_OrderLineDMSummary__c> tempOrdProdList, Decimal approximateCentIncrement){
        Map<String,List<T_OrderLineDMSummary__c>> comboKeyToNSOrdProdsMap = new Map<String,List<T_OrderLineDMSummary__c>>();
        Set<String> orderIdSet = new Set<String>();
        //Storing the OrdProd in Map<NS_Internal_Id,List<OrdProduct>>
        for(T_OrderLineDMSummary__c ordProd :tempOrdProdList ){
            //Combination of key with SF Order Id, NS Product Code, Quantity, OL Amount
            if(ordProd.NS_OrderLine_Item__c != null && ordProd.Quantity__c != null 
               && ordProd.OL_Amount__c != null && ordProd.SF_OrderProduct_Id__c == null){
            String orderIDKey = ordProd.SF_Order_Id__c+'-'+ordProd.NS_OrderLine_Item__c+'-'+ordProd.Quantity__c;
            if(comboKeyToNSOrdProdsMap.containsKey(orderIDKey)){
                comboKeyToNSOrdProdsMap.get(orderIDKey).add(ordProd);
            } 
            else
            {comboKeyToNSOrdProdsMap.put(orderIDKey, new List<T_OrderLineDMSummary__c> {ordProd});}
            
            //Get the Order Ids
            orderIdSet.add(ordProd.SF_Order_Id__c);
            }
        }
        //Collecting the Salesforce Order products which has the NS Order Id
        List<OrderItem> tempSFOrdItem =  [SELECT Id,OrderId,Order.NetSuite_Sales_order_Internal_Id__c,Quantity,
                                          Product2.ProductCode,TotalPrice,ServiceDate,SBQQ__BillingFrequency__c
                                          FROM OrderItem 
                                          WHERE OrderId in :orderIdSet
                                          AND Quantity != NULL AND Product2.ProductCode != NULL AND TotalPrice != NULL];
        Map<String,OrderItem> comboKeyToSFOrderProdsMap = new Map<String,OrderItem>();
        //Combination of key with SF Order Id, SF Product Code, Quantity, OL Start Date
        for(OrderItem tempOrdItem :tempSFOrdItem ){
            String sfOrderIdKey = tempOrdItem.OrderId+'-'+tempOrdItem.Product2.ProductCode+'-'+tempOrdItem.Quantity;
            if(! comboKeyToSFOrderProdsMap.containskey(sfOrderIdKey)){
                comboKeyToSFOrderProdsMap.put(sfOrderIdKey,tempOrdItem);
            }
        }
        List<T_OrderLineDMSummary__c> tempOLList = new List<T_OrderLineDMSummary__c>();
        //Updating the value of SF order product Id in OrderLineDMSummary
        for(String comboKey :comboKeyToNSOrdProdsMap.keyset() ){
            if(comboKeyToSFOrderProdsMap.containsKey(comboKey)){
                List<T_OrderLineDMSummary__c> ordProdList = comboKeyToNSOrdProdsMap.get(comboKey);
                if(ordProdList != null){
                /*for(T_OrderLineDMSummary__c summaryRec :ordProdList ){
                    //Get the SF Order Item to compare the amount
                    OrderItem sfOrderProd = comboKeyToSFOrderProdsMap.get(comboKey);
                    Decimal tempIncreaseSFAmount = sfOrderProd.TotalPrice + approximateCentIncrement;
                    Decimal tempDecreaseSFAmount = sfOrderProd.TotalPrice - approximateCentIncrement;
                    if(tempIncreaseSFAmount == summaryRec.OL_Amount__c ||
                      tempDecreaseSFAmount == summaryRec.OL_Amount__c){
                    summaryRec.SF_OrderProduct_Id__c = comboKeyToSFOrderProdsMap.get(comboKey).Id;
                    summaryRec.SF_OrderProdTotal__c = comboKeyToSFOrderProdsMap.get(comboKey).TotalPrice;
                    tempOLList.add(summaryRec);
                    }
                }*/
                Decimal centAmtForChecking = 0.01;
                    for(T_OrderLineDMSummary__c summaryRec :ordProdList ){
                        centAmtForChecking = 0.01;
                         if(summaryRec.SF_OrderProduct_Id__c == null){
                             for(Integer count = 1;  centAmtForChecking <= approximateCentIncrement;count++){
                            //Get the SF Order Item to compare the amount
                            OrderItem sfOrderProd = comboKeyToSFOrderProdsMap.get(comboKey);
                            Decimal tempIncreaseSFAmount = sfOrderProd.TotalPrice + centAmtForChecking;
                            Decimal tempDecreaseSFAmount = sfOrderProd.TotalPrice - centAmtForChecking;
                            if(tempIncreaseSFAmount == summaryRec.OL_Amount__c ||
                            tempDecreaseSFAmount == summaryRec.OL_Amount__c){
                            summaryRec.SF_OrderProduct_Id__c = comboKeyToSFOrderProdsMap.get(comboKey).Id;
                            summaryRec.SF_OrderProdTotal__c = comboKeyToSFOrderProdsMap.get(comboKey).TotalPrice;
                          //summaryRec.T_BillingFrequency__c = comboKeyToSFOrderProdsMap.get(comboKey).SBQQ__BillingFrequency__c;
                            tempOLList.add(summaryRec);
                            break;
                            }
                            else {centAmtForChecking = centAmtForChecking + 0.01;}
                             }
                         }
                     
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
    }

}