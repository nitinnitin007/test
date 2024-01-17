/**** @name       : T_NA_UpdateSFOrderProdIdInOLTableBatch
***** @author     : KPMG
***** @date       : Nov 11th, 2023
***** @description : Update the OL Summary Table's SF OrderProd Id using Key - 
                   *  Without Amount : SFOrderId,Item,Quantity,StartDate
                   *  With Amount : SFOrderId,Item,Quantity,Amount
                   *  With Amount with StartDate : SFOrderId,Item,StartDate,Amount
                   *  With Amount Without Qty: SFOrderId,Item,Amount
                   *  With Approximate Amount For One Dollar match by: +/- .01 cents : SFOrderId,Item,Quantity AND +/ .03 Amount
                   *  With Approximate Amount For One Dollar match by: +/- .01 cents : SFOrderId,Item AND +/ .03 Amount and without Quantity
                   * 
******/ 
//Database.executeBatch(new T_NA_UpdateSFOrderProdIdInOLTableBatch('withAmount'),200);///Rule 1: QTY, Itemcode, Exact Amount
//Database.executeBatch(new T_NA_UpdateSFOrderProdIdInOLTableBatch('withoutAmount'),200);//Rule 2: QTY,Itemcode,Start Date
//Database.executeBatch(new T_NA_UpdateSFOrderProdIdInOLTableBatch(1.00),200);//Rule 3: QTY,Item code,Amount With Variance';Enter upto 1.00 for the current requirement//With Quantity
//Database.executeBatch(new T_NA_UpdateSFOrderProdIdInOLTableBatch('withAmount','withoutQuantity'),200);Rule 5: Itemcode,Exact Amount
//Database.executeBatch(new T_NA_UpdateSFOrderProdIdInOLTableBatch('withoutQuantityWithStartDate'),200);//Rule 4: StartDate, Itemcode
//Database.executeBatch(new T_NA_UpdateSFOrderProdIdInOLTableBatch(1.00,'withoutQuantity'),200);//Rule 6: Itemcode, Amount with variance,Without QTY
public class T_NA_UpdateSFOrderProdIdInOLTableBatch implements Database.Batchable<sObject>,Database.Stateful {
    public String amountFilter;
    public String quantityFilter;
    public Decimal approximateCentIncrement = null;
    //Matching Rule Names
    public static Final String RULE_1_QTY_ITEMCODE_EXACTAMOUNT = 'Rule 1: QTY, Itemcode, Exact Amount';
    Public static Final String RULE_2_QTY_ITEMCODE_STARTDATE = 'Rule 2: QTY,Itemcode,Start Date';
    Public static Final String RULE_3_QTY_ITEMCODE_APPROXAMOUNT = 'Rule 3: QTY,Item code,Amount With Variance';
    public static Final String RULE_4_ITEMCODE_WITHSTARTDATE_WITHOUTQTY = 'Rule 4: StartDate, Itemcode';
    Public static Final String RULE_5_ITEMCODE_EXACTAMOUNT_WITHOUTQTY = 'Rule 5: Itemcode,Exact Amount';
    Public static Final String RULE_6_ITEMCODE_APPROXAMOUNT_WITHOUTQTY = 'Rule 6: Itemcode, Amount with variance,Without QTY';
    public T_NA_UpdateSFOrderProdIdInOLTableBatch(String withoutAmount){
        this.amountFilter = withoutAmount;
    }
     public T_NA_UpdateSFOrderProdIdInOLTableBatch(String withAmount,String withoutQuantity){
        this.amountFilter = withAmount;
        this.quantityFilter = withoutQuantity;
    }
    public T_NA_UpdateSFOrderProdIdInOLTableBatch(Decimal approximateAmount){
        this.approximateCentIncrement = approximateAmount;
    }
    public T_NA_UpdateSFOrderProdIdInOLTableBatch(Decimal approximateAmount,String withoutQuantity){
        this.approximateCentIncrement = approximateAmount;
        this.quantityFilter = withoutQuantity;
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
        if(amountFilter == 'withAmount' && quantityFilter == null) //Rule 1: QTY, Itemcode, Exact Amount
        {withAmount(tempOrdProdList);}
        else if(amountFilter == 'withAmount' && quantityFilter == 'withoutQuantity')//'Rule 5: Itemcode,Exact Amount'
        { withAmountWithoutQty(tempOrdProdList);}
        else if(amountFilter == 'withoutAmount' && quantityFilter == null)//'Rule 2: QTY,Itemcode,Start Date'//Without Amount With Qty
        {withoutAmount(tempOrdProdList);}
        else if(amountFilter == null && quantityFilter == 'withoutQuantity' && approximateCentIncrement != null)//'Rule 6: Itemcode, Amount with variance,Without QTY'
        {withApproximateAmountAndWithoutQuantity(tempOrdProdList,approximateCentIncrement);}
        else if(amountFilter == 'withoutQuantityWithStartDate' && quantityFilter == null  && approximateCentIncrement == null)// 'Rule 4: StartDate, Itemcode';
        { withoutAmountWithoutQuantityWithStartDate(tempOrdProdList);
        }
        else if(approximateCentIncrement != null && amountFilter == null && quantityFilter == null )// 'Rule 3: QTY,Item code,Amount With Variance';
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
        //Combination of key with SF Order Id, SF Product Code, Quantity, OL Price
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
                    tempOP.Rule_Name__c = RULE_1_QTY_ITEMCODE_EXACTAMOUNT;
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
   public static void withoutAmountWithoutQuantityWithStartDate(List<T_OrderLineDMSummary__c> tempOrdProdList){
        Map<String,List<T_OrderLineDMSummary__c>> comboKeyToOrdProdList = new Map<String,List<T_OrderLineDMSummary__c>>();
        Set<String> orderIdSet = new Set<String>();
        //Storing the OrdProd in Map<NS_Internal_Id,List<OrdProduct>>
        for(T_OrderLineDMSummary__c ordProd :tempOrdProdList ){
            //Combination of key with SF Order Id, NS Product Code, Start Date
            if(ordProd.NS_OrderLine_Item__c != null && ordProd.OL_StartDate__c != null && ordProd.SF_OrderProduct_Id__c == null){
            String orderIDKey = ordProd.SF_Order_Id__c+'-'+ordProd.NS_OrderLine_Item__c+'-'+ordProd.OL_StartDate__c;
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
                                          AND ServiceDate != NULL AND Product2.ProductCode != NULL AND TotalPrice != NULL];
        Map<String,OrderItem> netSuiteIdSFOrderProdIdMap = new Map<String,OrderItem>();
        //Combination of key with SF Order Id, SF Product Code, Start Date
        for(OrderItem tempOrdItem :tempSFOrdItem ){
            String sfOrderIdKey = tempOrdItem.OrderId+'-'+tempOrdItem.Product2.ProductCode+'-'+tempOrdItem.ServiceDate;
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
                    tempOP.Rule_Name__c = RULE_4_ITEMCODE_WITHSTARTDATE_WITHOUTQTY;
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
            if(ordProd.NS_OrderLine_Item__c != null && ordProd.Quantity__c != null && ordProd.OL_StartDate__c != null && ordProd.SF_OrderProduct_Id__c == null){
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
                    tempOP.Rule_Name__c = RULE_2_QTY_ITEMCODE_STARTDATE;
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
                    for(T_OrderLineDMSummary__c summaryRec :ordProdList){
                        OrderItem sfOrderProd = comboKeyToSFOrderProdsMap.get(combokey);
                       // Decimal difference = summaryRec.OL_Amount__c - sfOrderProd.TotalPrice;
                        Decimal difference;
                        Decimal matchingVariance;
                        String negativeSign = summaryRec.OL_Amount__c > sfOrderProd.TotalPrice ? '-' : '';
                        //System.debug('Var:OL= '+summaryRec.OL_Amount__c +' -sfOrderProd.TotalPrice ='+sfOrderProd.TotalPrice +'-difference:'+difference);
       					if(summaryRec.OL_Amount__c > sfOrderProd.TotalPrice && summaryRec.OL_Amount__c >0 && sfOrderProd.TotalPrice > 0  ){
                            difference = summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //10 - 9 =1
                			if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                            matchingVariance=sfOrderProd.TotalPrice +  difference; // 9+1=10
                            }
                        }
                       else if(summaryRec.OL_Amount__c < sfOrderProd.TotalPrice && summaryRec.OL_Amount__c >0 && sfOrderProd.TotalPrice > 0  ){
                            difference =   summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //9 - 10 = -1
                            if(difference >0 && difference <=1 || difference <0 && difference >=-1 ){
                            matchingVariance=sfOrderProd.TotalPrice + difference; // 10 + (-1) //10 -1 = 9
                            }
                       } 
                        else if (summaryRec.OL_Amount__c < sfOrderProd.TotalPrice && summaryRec.OL_Amount__c < 0 && sfOrderProd.TotalPrice > 0    ){
                    		difference =   summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //-10 -9=-19
                			if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                        	matchingVariance=sfOrderProd.TotalPrice +  difference; // 9 +(-19) = -10 
                            }
                        }
                		else if(summaryRec.OL_Amount__c > sfOrderProd.TotalPrice && summaryRec.OL_Amount__c > 0 && sfOrderProd.TotalPrice < 0  ){
                    		difference =   summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //10 -(-9) = 19
                			if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                			matchingVariance=sfOrderProd.TotalPrice  + difference; //-9 +19 = 10
                            }
                        }
                		else if(summaryRec.OL_Amount__c < sfOrderProd.TotalPrice && summaryRec.OL_Amount__c < 0 && sfOrderProd.TotalPrice > 0 ){
                    		difference = summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //-9 -(+ 10) = -19
                			if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                			matchingVariance=sfOrderProd.TotalPrice + difference; //10 +(-19)=-9
                            }
                        }
                		else if(summaryRec.OL_Amount__c > sfOrderProd.TotalPrice && summaryRec.OL_Amount__c > 0 && sfOrderProd.TotalPrice < 0){
                    		difference = summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //9 - (-10)=19
                			if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                   			matchingVariance=sfOrderProd.TotalPrice + difference; //-10 + 19 = 9
                            }
                        }
                    	else if(summaryRec.OL_Amount__c < sfOrderProd.TotalPrice && summaryRec.OL_Amount__c <0 && sfOrderProd.TotalPrice < 0){
                       		difference = summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //-10 - (-9) , -10+9 = -1
                			if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                    		matchingVariance=sfOrderProd.TotalPrice + difference; // -9 + (-1), -9 -1 = -10
                            }
                        }
                		else if(summaryRec.OL_Amount__c > sfOrderProd.TotalPrice && summaryRec.OL_Amount__c <0 && sfOrderProd.TotalPrice < 0){
                    		difference = summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //-9 - (-10) , -9 + 10 = 1
                    		if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                    		matchingVariance=sfOrderProd.TotalPrice + difference; // -10 + 1 = -9
                            }
                        }
                        if(matchingVariance == summaryRec.OL_Amount__c ){
                            summaryRec.SF_OrderProduct_Id__c = comboKeyToSFOrderProdsMap.get(comboKey).Id;
                            summaryRec.SF_OrderProdTotal__c  = comboKeyToSFOrderProdsMap.get(comboKey).TotalPrice;
                            summaryRec.T_BillingFrequency__c = comboKeyToSFOrderProdsMap.get(comboKey).SBQQ__BillingFrequency__c;
                            summaryRec.Rule_Name__c = RULE_3_QTY_ITEMCODE_APPROXAMOUNT + negativeSign + String.valueOf(difference);
                            tempOLList.add(summaryRec);
                            
                        }
                        
                       /* if (difference > 0 && difference <= 1.00) {
                            matchingVariance = sfOrderProd.TotalPrice + difference;
                            System.debug('matchingVariance:'+matchingVariance+'-difference:'+difference+'-summaryRec.OL_Amount__c'+summaryRec.OL_Amount__c);
                            if(matchingVariance == summaryRec.OL_Amount__c){
                            summaryRec.SF_OrderProduct_Id__c = comboKeyToSFOrderProdsMap.get(comboKey).Id;
                            summaryRec.SF_OrderProdTotal__c  = comboKeyToSFOrderProdsMap.get(comboKey).TotalPrice;
                            summaryRec.T_BillingFrequency__c = comboKeyToSFOrderProdsMap.get(comboKey).SBQQ__BillingFrequency__c;
                            summaryRec.Rule_Name__c = RULE_3_QTY_ITEMCODE_APPROXAMOUNT + negativeSign + String.valueOf(difference);
                            tempOLList.add(summaryRec);
                            break;
                            }
                            
                      }else if (difference >= -1.00 && difference < 0) {
                          matchingVariance = sfOrderProd.TotalPrice - difference;
                          System.debug('matchingVariance:'+matchingVariance+'-difference:'+difference+'-summaryRec.OL_Amount__c'+summaryRec.OL_Amount__c);
                          if(matchingVariance == summaryRec.OL_Amount__c){
                            summaryRec.SF_OrderProduct_Id__c = comboKeyToSFOrderProdsMap.get(comboKey).Id;
                            summaryRec.SF_OrderProdTotal__c  = comboKeyToSFOrderProdsMap.get(comboKey).TotalPrice;
                            summaryRec.T_BillingFrequency__c = comboKeyToSFOrderProdsMap.get(comboKey).SBQQ__BillingFrequency__c;
                            summaryRec.Rule_Name__c = RULE_3_QTY_ITEMCODE_APPROXAMOUNT + negativeSign + String.valueOf(difference);
                            tempOLList.add(summaryRec);
                            break;
                          }
                    } */
                    }
                /*Decimal centAmtForChecking = 0.00001;
                    for(T_OrderLineDMSummary__c summaryRec :ordProdList ){
                        centAmtForChecking = 0.00001;
                         if(summaryRec.SF_OrderProduct_Id__c == null){
                             for(Integer count = 1;  centAmtForChecking <= approximateCentIncrement;count++){
                            //Get the SF Order Item to compare the amount
                            OrderItem sfOrderProd = comboKeyToSFOrderProdsMap.get(comboKey);
                            Decimal tempIncreaseSFAmount = sfOrderProd.TotalPrice + centAmtForChecking;
                            Decimal tempDecreaseSFAmount = sfOrderProd.TotalPrice - centAmtForChecking;
                            String negativeSign = summaryRec.OL_Amount__c > sfOrderProd.TotalPrice ? '-' : '';
                            if(tempIncreaseSFAmount == summaryRec.OL_Amount__c ||
                            tempDecreaseSFAmount == summaryRec.OL_Amount__c){
                            summaryRec.SF_OrderProduct_Id__c = comboKeyToSFOrderProdsMap.get(comboKey).Id;
                            summaryRec.SF_OrderProdTotal__c = comboKeyToSFOrderProdsMap.get(comboKey).TotalPrice;    
                            summaryRec.T_BillingFrequency__c = comboKeyToSFOrderProdsMap.get(comboKey).SBQQ__BillingFrequency__c;
                            summaryRec.Rule_Name__c =  RULE_3_QTY_ITEMCODE_APPROXAMOUNT + negativeSign + String.valueof(centAmtForChecking);
                            tempOLList.add(summaryRec);
                            break;
                            }
                            else {centAmtForChecking = centAmtForChecking + 0.00001; 
                                 }
                             }
                         }
                     
                    }*/
                
                }
            }
        }
        //Updating the OL List
        if(tempOLList.size()>0){
            update tempOLList;
        }
    }
   public static void withAmountWithoutQty(List<T_OrderLineDMSummary__c> tempOrdProdList){
        Map<String,List<T_OrderLineDMSummary__c>> comboKeyToOrdProdList = new Map<String,List<T_OrderLineDMSummary__c>>();
        Set<String> orderIdSet = new Set<String>();
        //Storing the OrdProd in Map<NS_Internal_Id,List<OrdProduct>>
        for(T_OrderLineDMSummary__c ordProd :tempOrdProdList ){
            //Combination of key with SF Order Id, NS Product Code, Quantity, OL Amount
            if(ordProd.NS_OrderLine_Item__c != null && ordProd.OL_Amount__c != null && ordProd.SF_OrderProduct_Id__c == null){
            String orderIDKey = ordProd.SF_Order_Id__c+'-'+ordProd.NS_OrderLine_Item__c+'-'+ ordProd.OL_Amount__c;
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
                                          AND Product2.ProductCode != NULL AND TotalPrice != NULL];
        Map<String,OrderItem> netSuiteIdSFOrderProdIdMap = new Map<String,OrderItem>();
        //Combination of key with SF Order Id, SF Product Code, Quantity, OL Start Date
        for(OrderItem tempOrdItem :tempSFOrdItem ){
            String sfOrderIdKey = tempOrdItem.OrderId+'-'+tempOrdItem.Product2.ProductCode+'-'+ tempOrdItem.TotalPrice;
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
                    tempOP.Rule_Name__c = RULE_5_ITEMCODE_EXACTAMOUNT_WITHOUTQTY;
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
     public static void withApproximateAmountAndWithoutQuantity(List<T_OrderLineDMSummary__c> tempOrdProdList, Decimal approximateCentIncrement){
        Map<String,List<T_OrderLineDMSummary__c>> comboKeyToNSOrdProdsMap = new Map<String,List<T_OrderLineDMSummary__c>>();
        Set<String> orderIdSet = new Set<String>();
        //Storing the OrdProd in Map<NS_Internal_Id,List<OrdProduct>>
        for(T_OrderLineDMSummary__c ordProd :tempOrdProdList ){
            //Combination of key with SF Order Id, NS Product Code,
            if(ordProd.NS_OrderLine_Item__c != null && ordProd.OL_Amount__c != null && ordProd.SF_OrderProduct_Id__c == null){
            String orderIDKey = ordProd.SF_Order_Id__c+'-'+ordProd.NS_OrderLine_Item__c;
            if(comboKeyToNSOrdProdsMap.containsKey(orderIDKey)){
                comboKeyToNSOrdProdsMap.get(orderIDKey).add(ordProd);
            } 
            else
            {comboKeyToNSOrdProdsMap.put(orderIDKey, new List<T_OrderLineDMSummary__c> {ordProd});}
            //Get the Order Ids
            orderIdSet.add(ordProd.SF_Order_Id__c);
            }
        }
        //system.debug('orderIdSet---->'+orderIdSet);
        //Collecting the Salesforce Order products which has the NS Order Id
        List<OrderItem> tempSFOrdItem =  [SELECT Id,OrderId,Order.NetSuite_Sales_order_Internal_Id__c,Quantity,
                                          Product2.ProductCode,TotalPrice,ServiceDate,SBQQ__BillingFrequency__c
                                          FROM OrderItem 
                                          WHERE OrderId in :orderIdSet
                                          AND Product2.ProductCode != NULL AND TotalPrice != NULL];
        Map<String,OrderItem> comboKeyToSFOrderProdsMap = new Map<String,OrderItem>();
        //Combination of key with SF Order Id, SF Product Code
        for(OrderItem tempOrdItem :tempSFOrdItem ){
            String sfOrderIdKey = tempOrdItem.OrderId+'-'+tempOrdItem.Product2.ProductCode;
            if(! comboKeyToSFOrderProdsMap.containskey(sfOrderIdKey)){
                comboKeyToSFOrderProdsMap.put(sfOrderIdKey,tempOrdItem);
            }
        }
                     
                /*Decimal centAmtForChecking = 0.00001;
                    for(T_OrderLineDMSummary__c summaryRec :ordProdList ){
                        centAmtForChecking = 0.00001;
                         if(summaryRec.SF_OrderProduct_Id__c == null){
                             for(Integer count = 1;  centAmtForChecking <= approximateCentIncrement;count++){
                            //Get the SF Order Item to compare the amount
                            OrderItem sfOrderProd = comboKeyToSFOrderProdsMap.get(comboKey);
                            Decimal tempIncreaseSFAmount = sfOrderProd.TotalPrice + centAmtForChecking;
                            Decimal tempDecreaseSFAmount = sfOrderProd.TotalPrice - centAmtForChecking;
                            String negativeSign = summaryRec.OL_Amount__c > sfOrderProd.TotalPrice ? '-' : '';
                            if(tempIncreaseSFAmount == summaryRec.OL_Amount__c ||
                            tempDecreaseSFAmount == summaryRec.OL_Amount__c){
                            summaryRec.SF_OrderProduct_Id__c = comboKeyToSFOrderProdsMap.get(comboKey).Id;
                            summaryRec.SF_OrderProdTotal__c = comboKeyToSFOrderProdsMap.get(comboKey).TotalPrice;
                            summaryRec.T_BillingFrequency__c = comboKeyToSFOrderProdsMap.get(comboKey).SBQQ__BillingFrequency__c;
                            summaryRec.Rule_Name__c= RULE_5_ITEMCODE_APPROXAMOUNT_WITHOUTQTY + negativeSign + String.valueof(centAmtForChecking);
                            tempOLList.add(summaryRec);
                            break;
                            }
                            else {centAmtForChecking = centAmtForChecking + 0.00001;}
                             }
                         }
                     
                    } */
        List<T_OrderLineDMSummary__c> tempOLList = new List<T_OrderLineDMSummary__c>();
        //Updating the value of SF order product Id in OrderLineDMSummary
        for(String comboKey :comboKeyToNSOrdProdsMap.keyset() ){
            if(comboKeyToSFOrderProdsMap.containsKey(comboKey)){
                List<T_OrderLineDMSummary__c> ordProdList = comboKeyToNSOrdProdsMap.get(comboKey);
                if(ordProdList != null){
                    for(T_OrderLineDMSummary__c summaryRec :ordProdList){
                        OrderItem sfOrderProd = comboKeyToSFOrderProdsMap.get(combokey);
                        Decimal difference = summaryRec.OL_Amount__c - sfOrderProd.TotalPrice;
                        //Decimal difference ;
                        Decimal matchingVariance;
                        String negativeSign = summaryRec.OL_Amount__c > sfOrderProd.TotalPrice ? '-' : '';
                        /*if (difference > 0 && difference <= 1.00) {
                            matchingVariance = sfOrderProd.TotalPrice + difference;
                            System.debug('matchingVariance:'+matchingVariance+'-difference:'+difference+'-summaryRec.OL_Amount__c'+summaryRec.OL_Amount__c);
                            //if(matchingVariance == summaryRec.OL_Amount__c)
                            summaryRec.SF_OrderProduct_Id__c = comboKeyToSFOrderProdsMap.get(comboKey).Id;
                            summaryRec.SF_OrderProdTotal__c  = comboKeyToSFOrderProdsMap.get(comboKey).TotalPrice;
                            summaryRec.T_BillingFrequency__c = comboKeyToSFOrderProdsMap.get(comboKey).SBQQ__BillingFrequency__c;
                            summaryRec.Rule_Name__c = RULE_6_ITEMCODE_APPROXAMOUNT_WITHOUTQTY + negativeSign + String.valueOf(difference) +comboKeyToSFOrderProdsMap.get(comboKey).Id ;
                            tempOLList.add(summaryRec);
                            
                      }else if (difference >= -1.00 && difference < 0) {
                          matchingVariance = sfOrderProd.TotalPrice - difference;
                          System.debug('matchingVariance:'+matchingVariance+'-difference:'+difference+'-summaryRec.OL_Amount__c'+summaryRec.OL_Amount__c);
                          //if(matchingVariance == summaryRec.OL_Amount__c)
                            summaryRec.SF_OrderProduct_Id__c = comboKeyToSFOrderProdsMap.get(comboKey).Id;
                            summaryRec.SF_OrderProdTotal__c  = comboKeyToSFOrderProdsMap.get(comboKey).TotalPrice;
                            summaryRec.T_BillingFrequency__c = comboKeyToSFOrderProdsMap.get(comboKey).SBQQ__BillingFrequency__c;
                            summaryRec.Rule_Name__c = RULE_6_ITEMCODE_APPROXAMOUNT_WITHOUTQTY + negativeSign + String.valueOf(difference) +comboKeyToSFOrderProdsMap.get(comboKey).Id ;
                            tempOLList.add(summaryRec);
                          
                     }*/
                        ///From new logic
                        System.debug('Var:OL= '+summaryRec.OL_Amount__c +' -sfOrderProd.TotalPrice ='+sfOrderProd.TotalPrice +'-difference:'+difference);
       					if(summaryRec.OL_Amount__c > sfOrderProd.TotalPrice && summaryRec.OL_Amount__c >0 && sfOrderProd.TotalPrice > 0  ){
                            difference = summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //10 - 9 =1
                			if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                            matchingVariance=sfOrderProd.TotalPrice +  difference; // 9+1=10
                }
                 }
                
                         else if(summaryRec.OL_Amount__c < sfOrderProd.TotalPrice && summaryRec.OL_Amount__c >0 && sfOrderProd.TotalPrice > 0  ){
                            difference =   summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //9 - 10 = -1
                            if(difference >0 && difference <=1 || difference <0 && difference >=-1 ){
                            matchingVariance=sfOrderProd.TotalPrice + difference; // 10 + (-1) //10 -1 = 9
                }
                                
                                        }
                
                
                		else if (summaryRec.OL_Amount__c < sfOrderProd.TotalPrice && summaryRec.OL_Amount__c < 0 && sfOrderProd.TotalPrice > 0    ){
                    		difference =   summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //-10 -9=-19
                			if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                        	matchingVariance=sfOrderProd.TotalPrice +  difference; // 9 +(-19) = -10 
                }
                             
                    
                }
                		else if(summaryRec.OL_Amount__c > sfOrderProd.TotalPrice && summaryRec.OL_Amount__c > 0 && sfOrderProd.TotalPrice < 0  ){
                    		difference =   summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //10 -(-9) = 19
                			if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                
                			matchingVariance=sfOrderProd.TotalPrice  + difference; //-9 +19 = 10
                }
                        
                
                }
                		else if(summaryRec.OL_Amount__c < sfOrderProd.TotalPrice && summaryRec.OL_Amount__c < 0 && sfOrderProd.TotalPrice > 0 ){
                    		difference = summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //-9 -(+ 10) = -19
                			if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                
                			matchingVariance=sfOrderProd.TotalPrice + difference; //10 +(-19)=-9
                }
                    
                }
                		else if(summaryRec.OL_Amount__c > sfOrderProd.TotalPrice && summaryRec.OL_Amount__c > 0 && sfOrderProd.TotalPrice < 0){
                    		difference = summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //9 - (-10)=19
                			if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                   			matchingVariance=sfOrderProd.TotalPrice + difference; //-10 + 19 = 9
                }
                }
                
                
                
                		else if(summaryRec.OL_Amount__c < sfOrderProd.TotalPrice && summaryRec.OL_Amount__c <0 && sfOrderProd.TotalPrice < 0){
                       		difference = summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //-10 - (-9) , -10+9 = -1
                			if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                    		matchingVariance=sfOrderProd.TotalPrice + difference; // -9 + (-1), -9 -1 = -10
                }
                }
                		else if(summaryRec.OL_Amount__c > sfOrderProd.TotalPrice && summaryRec.OL_Amount__c <0 && sfOrderProd.TotalPrice < 0){
                    		difference = summaryRec.OL_Amount__c - sfOrderProd.TotalPrice; //-9 - (-10) , -9 + 10 = 1
                    		if(difference >=0 && difference <=1 || difference <=0 && difference >=-1 ){
                    		matchingVariance=sfOrderProd.TotalPrice + difference; // -10 + 1 = -9
                }
                }
                        if(matchingVariance == summaryRec.OL_Amount__c ){
                            summaryRec.SF_OrderProduct_Id__c = comboKeyToSFOrderProdsMap.get(comboKey).Id;
                            summaryRec.SF_OrderProdTotal__c  = comboKeyToSFOrderProdsMap.get(comboKey).TotalPrice;
                            summaryRec.T_BillingFrequency__c = comboKeyToSFOrderProdsMap.get(comboKey).SBQQ__BillingFrequency__c;
                            summaryRec.Rule_Name__c = RULE_6_ITEMCODE_APPROXAMOUNT_WITHOUTQTY + String.valueOf(difference);
                            tempOLList.add(summaryRec);
                            
                        }
                            
                        //End new logic
                        
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