/**** @Name        : T_UpdateInvLinewithSFOrderSFOrdProdBatch
***** @Created By  : KPMG
***** @Created On  : Nov 11th, 2023
***** @Description : Batch to update InvoiceLines in QTC temp table to update with SFOrderId and 
					 SFOrderProductId from T_OrderLineDMSummaryLine Table
******/
public class T_UpdateInvLinewithSFOrderSFOrdProdBatch implements Database.Batchable<sObject>,Database.Stateful {
    // Database.executeBatch(new T_UpdateInvLinewithSFOrderSFOrdProdBatch(),200);
    public database.querylocator start(Database.BatchableContext bc)
    { 
        //Collect the Temp invLine Records 
        string query = 'SELECT Id,Order__c, Order_Product__c,Sales_Order_Internal_Id__c,Item__c,Sales_Order_Line_Id__c, '
            +'Quantity__c FROM QtC_Mig_Invoice_Lines_Temp_Table__c'
            +' WHERE Sales_Order_Internal_Id__c != Null AND Sales_Order_Line_Id__c != NULL AND Quantity__c != NULL AND Item__c != NULL ';//AND Order_Product__c ! = Null AND Order__c != Null';
        return Database.getQueryLocator(query);
    }
    //Passing the records to execute the Batch class
    public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Lines_Temp_Table__c> invoiceLineList) {
        Map<String,List<QtC_Mig_Invoice_Lines_Temp_Table__c>> comboKeyToInvLineList = new Map<String,List<QtC_Mig_Invoice_Lines_Temp_Table__c>>();
        Set<String> invLineIdSet = new Set<String>();
        //Storing the QtC_Mig_Invoice_Lines_Temp_Table__c in the Map
        for(QtC_Mig_Invoice_Lines_Temp_Table__c inv :invoiceLineList ){
            String invLineIDKey = inv.Sales_Order_Internal_Id__c
                                 +'-'+ inv.Quantity__c
                				 +'-'+ inv.Sales_Order_Line_Id__c 
                                 +'-'+ inv.Item__c;
            if(comboKeyToInvLineList.containsKey(invLineIDKey)){
                comboKeyToInvLineList.get(invLineIDKey).add(inv);
            } else{
                comboKeyToInvLineList.put(invLineIDKey, new List<QtC_Mig_Invoice_Lines_Temp_Table__c> {inv});
            }
            //Get the Sales_Order_Internal_Id__c
            invLineIdSet.add(inv.Sales_Order_Internal_Id__c);
        }        
        //Collecting records from T_OrderLineDMSummary__c
        List<T_OrderLineDMSummary__c> orderItemList = [SELECT Id,NSOrderID__c,SF_Order_Id__c,SF_OrderProduct_Id__c,NS_OrderLine_Item__c,Quantity__c,NSOrderLineitemID__c 
                                                       FROM T_OrderLineDMSummary__c 
                                                       WHERE SF_Order_Id__c != null 
                                                       AND NSOrderID__c != null
                                                       AND NSOrderID__c in :invLineIdSet
                                                       AND Quantity__c != null
                                                       AND NS_OrderLine_Item__c != null
                                                       AND NSOrderLineitemID__c != null
                                                       AND SF_OrderProduct_Id__c != null];
        Map<String,T_OrderLineDMSummary__c> orderIdInvLineMap = new Map<String,T_OrderLineDMSummary__c>();
        //Combination of key with NSOrderID__c, NS_OrderLine_Item__c and Quantity__c
        for(T_OrderLineDMSummary__c summary :orderItemList ){
            String orderSummaryKey = summary.NSOrderID__c
                                     +'-'+ summary.Quantity__c 
                                     +'-'+ summary.NSOrderLineitemID__c
                                     +'-'+ summary.NS_OrderLine_Item__c;
            if(! orderIdInvLineMap.containskey(orderSummaryKey)){
                orderIdInvLineMap.put(orderSummaryKey,summary);
            }
        }
        List<QtC_Mig_Invoice_Lines_Temp_Table__c> tempInvLines = new List<QtC_Mig_Invoice_Lines_Temp_Table__c>();
        //Updating the T_OrderLineDMSummary__c to populate the Order and OrderProduct
        for(String comboKey : orderIdInvLineMap.keyset()){
            if(comboKeyToInvLineList.containsKey(comboKey)){
                List<QtC_Mig_Invoice_Lines_Temp_Table__c> tempInv = comboKeyToInvLineList.get(comboKey);
                if(tempInv != null){
                for(QtC_Mig_Invoice_Lines_Temp_Table__c inv : tempInv){
                    inv.Order__c = orderIdInvLineMap.get(comboKey).SF_Order_Id__c; 
                    inv.Order_Product__c = orderIdInvLineMap.get(comboKey).SF_OrderProduct_Id__c;
                    tempInvLines.add(inv);  
                }
                }
            }
        }            
        
        //Updating the T_OrderLineDMSummary__c
        if(tempInvLines.size()>0){
            update tempInvLines;    
        }
    }
    //Finishing the batch process
    public void finish(Database.BatchableContext bc){
        System.debug( 'batch class completed' );
    }
}