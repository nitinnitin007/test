/**** @name        : T_NA_UpdSFOrderProdIdInBlnginvBatch
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Update the SF order Id and SF order Products Id in the blng__InvoiceLine__c
                     based on the Combination of Item COde, QTY, Amount 
                   : OR Without Amount
******/ 
public class T_NA_UpdSFOrderProdIdInBlnginvBatch implements Database.Batchable<sObject>,Database.Stateful {
    public string tempFileName;
    public T_NA_UpdSFOrderProdIdInBlnginvBatch(){}
    public T_NA_UpdSFOrderProdIdInBlnginvBatch(String fileName){
        this.tempFileName = fileName;
    }
//Database.executeBatch(new T_NA_UpdSFOrderProdIdInBlnginvBatch('withAmount'),200); -----On Demand
//Database.executeBatch(new T_NA_UpdSFOrderProdIdInBlnginvBatch('withoutAmount'),200);---On Demand
     public database.querylocator start(Database.BatchableContext bc)
	{	//Get the orderLine Summary records 
        String query = 'SELECT Id,Internal_ID__c, Term_Start_Date__c,Term_End_Date__c,Sales_Order_Internal_Id__c, '
                       + 'Sales_Order_Line_Id__c,Order__c, Order_Product__c,Quantity__c,Item__c,IL_Amount_with_Tax__c  ' 
                       +' FROM QtC_Mig_Invoice_Lines_Temp_Table__c '
                       +' WHERE Sales_Order_Internal_Id__c != null  AND Quantity__c != Null '
                       +' AND Item__c != Null '//AND Term_Start_date__c != Null AND Term_End_date__c != Null';
                       + ' AND IL_Amount_with_Tax__c != null';
        return Database.getQueryLocator(query);
    }
    //Method to execute the query
     public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Lines_Temp_Table__c> invLineList)
    {
        if(this.tempFileName == 'withAmount'){
           withAmountExecute(invLineList,this.tempFileName); 
        } else if(this.tempFileName == 'withoutAmount'){
        	withoutAmountExecute(invLineList,this.tempFileName);    
        }
    }
    //Execute With Amount logic
    public static void withAmountExecute(List<QtC_Mig_Invoice_Lines_Temp_Table__c> invLineList,String tempFileName){
        Map<String,QtC_Mig_Invoice_Lines_Temp_Table__c> comboKeyToInvLineList = new Map<String,QtC_Mig_Invoice_Lines_Temp_Table__c>();
        Set<String> invLineIdSet = new Set<String>();
        //Storing the QtC_Mig_Invoice_Lines_Temp_Table__c in the Map
        for(QtC_Mig_Invoice_Lines_Temp_Table__c invLine :invLineList ){
            //Combination of key with Sales_Order_Internal_Id__c, Qty,Item,Amount
            String invLineIDKey = invLine.Sales_Order_Internal_Id__c
                                  +'-'+ invLine.Quantity__c
                				  +'-'+ invLine.Item__c 
                				  //+'-'+ invLine.Term_Start_date__c
                                  //+'-'+ invLine.Term_End_date__c;
                                  +'-'+ invLine.IL_Amount_with_Tax__c;
            if(!comboKeyToInvLineList.containsKey(invLineIDKey)){
                comboKeyToInvLineList.put(invLineIDKey,invLine);
            }
            //Get the Sales_Order_Internal_Id__c
            invLineIdSet.add(invLine.Sales_Order_Internal_Id__c);
        }
        //Collecting the Salesforce  which has the NS_Sales_Order_Internal_Id__c
        List<blng__InvoiceLine__c> tempBlngInvLine =  [SELECT Id,NS_Sales_Order_Internal_Id__c,NS_Inv_Internal_ID__c,blng__OrderProduct__c,Order__c,T_IsMigrated__c,
                                                       blng__StartDate__c,blng__EndDate__c,blng__Quantity__c,blng__Product__r.ProductCode,blng__TotalAmount__c  
                                                       FROM blng__InvoiceLine__c 
                                                       WHERE NS_Sales_Order_Internal_Id__c in :invLineIdSet
                                                       AND NS_Sales_Order_Internal_Id__c != null
                                                       AND T_IsMigrated__c = true
                                                       //AND blng__StartDate__c != null  AND blng__EndDate__c != null
                                                       AND blng__TotalAmount__c != null
                                                       AND blng__Quantity__c != null AND blng__Product__r.ProductCode != null];
         Map<String,blng__InvoiceLine__c> netSuiteIdInvLineIdMap = new Map<String,blng__InvoiceLine__c>();
        //Combination of key with NS_Sales_Order_Internal_Id__c, NS_Line_ID__c
        for(blng__InvoiceLine__c tempInvLine :tempBlngInvLine ){
            String sfInvLineIdKey = tempInvLine.NS_Sales_Order_Internal_Id__c
                                    +'-'+ tempInvLine.blng__Quantity__c 
                                    +'-'+ tempInvLine.blng__Product__r.ProductCode 
                                    //+'-'+ tempInvLine.blng__StartDate__c
                                    //+'-'+ tempInvLine.blng__EndDate__c;
                                    +'-'+ tempInvLine.blng__TotalAmount__c;
            if(!netSuiteIdInvLineIdMap.containskey(sfInvLineIdKey)){
                netSuiteIdInvLineIdMap.put(sfInvLineIdKey,tempInvLine);
            }
        }
        List<blng__InvoiceLine__c> tempBlngInvLineList = new List<blng__InvoiceLine__c>();
        //Updating the value of blng__OrderProduct__c and Order__c in blng__InvoiceLine__c
        for(String internalId :netSuiteIdInvLineIdMap.keyset() ){
            if(comboKeyToInvLineList.containsKey(internalId)){
                blng__InvoiceLine__c tempInvLine = netSuiteIdInvLineIdMap.get(internalId);
                if(tempInvLine != null){
                    tempInvLine.blng__OrderProduct__c = comboKeyToInvLineList.get(internalId).Order_Product__c;//Update blng__OrderProduct__c in blng__InvoiceLine__c
                    tempInvLine.Order__c = comboKeyToInvLineList.get(internalId).Order__c;//Update Order__c in blng__InvoiceLine__c
                    tempBlngInvLineList.add(tempInvLine);
                }
            }
        }
        //Updating the InvLine List
        if(tempBlngInvLineList.size() > 0){
            update tempBlngInvLineList;
        }
    }
    //Without Amount Logic
    public static void withoutAmountExecute(List<QtC_Mig_Invoice_Lines_Temp_Table__c> invLineList,String tempFileName){
        Map<String,QtC_Mig_Invoice_Lines_Temp_Table__c> comboKeyToInvLineList = new Map<String,QtC_Mig_Invoice_Lines_Temp_Table__c>();
        Set<String> invLineIdSet = new Set<String>();
        //Storing the QtC_Mig_Invoice_Lines_Temp_Table__c in the Map
        for(QtC_Mig_Invoice_Lines_Temp_Table__c invLine :invLineList ){
            //Combination of key with Sales_Order_Internal_Id__c, Qty,Item,NS_Sales_Order_Line_Id__c
            String invLineIDKey = invLine.Sales_Order_Internal_Id__c 
            					  +'-'+ invLine.Sales_Order_Line_Id__c
                                  +'-'+ invLine.Quantity__c
                				  +'-'+ invLine.Item__c;
                				  //+'-'+ invLine.Term_Start_date__c
                                  //+'-'+ invLine.Term_End_date__c;
                                  //+'-'+ invLine.IL_Amount_with_Tax__c;
            if(!comboKeyToInvLineList.containsKey(invLineIDKey)){
                comboKeyToInvLineList.put(invLineIDKey,invLine);
            }
            //Get the Sales_Order_Internal_Id__c
            invLineIdSet.add(invLine.Sales_Order_Internal_Id__c);
        }
       
        //Collecting the Salesforce  which has the NS_Sales_Order_Internal_Id__c
        List<blng__InvoiceLine__c> tempBlngInvLine =  [SELECT Id,NS_Sales_Order_Internal_Id__c,NS_Sales_Order_Line_Id__c,NS_Inv_Internal_ID__c,blng__OrderProduct__c,Order__c,T_IsMigrated__c,
                                                       blng__StartDate__c,blng__EndDate__c,blng__Quantity__c,blng__Product__r.ProductCode,blng__TotalAmount__c  
                                                       FROM blng__InvoiceLine__c 
                                                       WHERE NS_Sales_Order_Internal_Id__c in :invLineIdSet
                                                       AND NS_Sales_Order_Internal_Id__c != null  AND NS_Sales_Order_Line_Id__c != null
                                                       AND T_IsMigrated__c = true
                                                       //AND blng__StartDate__c != null  AND blng__EndDate__c != null
                                                       //AND blng__TotalAmount__c != null
                                                       AND blng__Quantity__c != null AND blng__Product__r.ProductCode != null];
       
         Map<String,blng__InvoiceLine__c> netSuiteIdInvLineIdMap = new Map<String,blng__InvoiceLine__c>();
        //Combination of key with NS_Sales_Order_Internal_Id__c, NS_Line_ID__c
        for(blng__InvoiceLine__c tempInvLine :tempBlngInvLine ){
            String sfInvLineIdKey = tempInvLine.NS_Sales_Order_Internal_Id__c
                					+'-'+ tempInvLine.NS_Sales_Order_Line_Id__c
                                    +'-'+ tempInvLine.blng__Quantity__c 
                                    +'-'+ tempInvLine.blng__Product__r.ProductCode;
                                    //+'-'+ tempInvLine.blng__StartDate__c
                                    //+'-'+ tempInvLine.blng__EndDate__c;
                                    //+'-'+ tempInvLine.blng__TotalAmount__c;
            if(!netSuiteIdInvLineIdMap.containskey(sfInvLineIdKey)){
                netSuiteIdInvLineIdMap.put(sfInvLineIdKey,tempInvLine);
            }
        }
        List<blng__InvoiceLine__c> tempBlngInvLineList = new List<blng__InvoiceLine__c>();
        //Updating the value of blng__OrderProduct__c and Order__c in blng__InvoiceLine__c
        for(String internalId :netSuiteIdInvLineIdMap.keyset() ){
            if(comboKeyToInvLineList.containsKey(internalId)){
                blng__InvoiceLine__c tempInvLine = netSuiteIdInvLineIdMap.get(internalId);
                if(tempInvLine != null){
                    tempInvLine.blng__OrderProduct__c = comboKeyToInvLineList.get(internalId).Order_Product__c;//Update blng__OrderProduct__c in blng__InvoiceLine__c
                    tempInvLine.Order__c = comboKeyToInvLineList.get(internalId).Order__c;//Update Order__c in blng__InvoiceLine__c
                    tempBlngInvLineList.add(tempInvLine);
                }
            }
        }
        //Updating the InvLine List
        if(tempBlngInvLineList.size() > 0){
            update tempBlngInvLineList;
        }
    }
     //Finishing the batch process
    public void finish(Database.BatchableContext bc){
        system.debug( 'batch class completed' );
    }

}