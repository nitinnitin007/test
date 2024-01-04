/****  Name       : T_ValidateInvoiceBatch
***** Created By  : KPMG
***** Created On  : Oct 11th, 2023
***** Description : Checking Order Product Line Amount = Corresponding Inv Lines Amount
                    Order Product : InternalId+LineId+Item+Qty '-'separator 
                    Inv Lines : : SalesOrderInternalId+SalesOrderLineId+Item+Qty '-'separator 
                    Validate the amount and find the flag
                    Insert them into OLSummary Table which is the Base table for all migrations
******/

public class T_ValidateInvoiceBatch implements Database.Batchable<sObject>,Database.Stateful {
    // Database.executeBatch(new T_ValidateInvoiceBatch(),200);
    public Database.queryLocator start(Database.BatchableContext bc)
    {
        //Collect all the Temp Order Lines
        string query = 'SELECT id,Amount__c, Amount_Credit__c, Amount_Debit_Foreign_Currency__c, Amount_Foreign_Currency__c,Applying_Link_Type__c,'+ 
                       'Amount_Foreign_Currency_without_Symbol__c,Document_Number__c, Internal_ID__c, Invoice_Line_ID__c, Item_Rate__c, Line_ID__c,' 
                       + ' Line_Sequence_Number__c, OSA_Contract_Number_from_Salesforce__c, OSA_Contract_Number_RA__c,Tax__c,Item__c,Quantity__c ,'
                       + ' Invoice_End_Date__c,Invoice_Start_Date__c,Amount_with_Tax__c FROM QTC_Mig_OrderProducts__c ';
                       //+ ' WHERE Applying_Link_Type__c = \'Order Bill/{#Invoice#}\' ';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc,List<QTC_Mig_OrderProducts__c> orderLines) {
       validateInvoice(orderLines);
    }
    public static void validateInvoice(List<QTC_Mig_OrderProducts__c> orderLines){
         //Get the OrderLines into Map 
        //Map<Id,QTC_Mig_OrderProducts__c> idToOrderLinesMap = new  Map<Id,QTC_Mig_OrderProducts__c>(orderLines);
        Set<String> orderInternalIds = new Set<String>();
        Map<String,List<QTC_Mig_OrderProducts__c>> orderLineIdMap = new Map<String,list<QTC_Mig_OrderProducts__c>>();
        //1.Get the Map<OrderLineId,OrderLines>
        for(QTC_Mig_OrderProducts__c ord : orderLines)
        {	String ordIntIdLineIdItemQty = ord.Internal_ID__c+'-'+ord.Line_ID__c+'-'+ord.Item__c+'-'+ord.Quantity__c;
         	if(orderLineIdMap.containskey(ordIntIdLineIdItemQty)){
             orderLineIdMap.get(ordIntIdLineIdItemQty).add(ord);       
         	} 
         	else{
             orderLineIdMap.put(ordIntIdLineIdItemQty, new List<QTC_Mig_OrderProducts__c> {ord});
         }
         orderInternalIds.add(ord.Internal_ID__c);
        }
        //Map<String,OLAmount>
        Map<String,Decimal> orderLineAmountMap = new Map<String,Decimal>();
        //Iterating order products
        for(QTC_Mig_OrderProducts__c ord : orderLines)
        {	
            String invOrderIdLineIdItemQty = ord.Internal_ID__c+'-'+ord.Line_ID__c+'-'+ord.Item__c+'-'+ord.Quantity__c;
            if(orderLineAmountMap.containskey(invOrderIdLineIdItemQty)){
                orderLineAmountMap.put(invOrderIdLineIdItemQty,ord.Amount_with_Tax__c+orderLineAmountMap.get(invOrderIdLineIdItemQty));
            }
            else {
                orderLineAmountMap.put(invOrderIdLineIdItemQty,ord.Amount_with_Tax__c);       
            }
            
        }
        //Querying Invoice Lines List
        List<QtC_Mig_Invoice_Lines_Temp_Table__c> invoiceLinesOrderProductList = [SELECT id,Amount__c, Amount_Foreign_Currency__c, 
                                                                                  Amount_Foreign_Currency_without_Symbol__c,T_SourceName__c,
             																	  Sales_Order_Internal_Id__c, Sales_Order_Line_Id__c,Line_ID__c,Quantity__c,Item__c,
                                                                                  Tax__c,Line_Sequence_Number__c,
            																	  IL_Amount_with_Tax__c 
             																	  FROM QtC_Mig_Invoice_Lines_Temp_Table__c
                                                                                  WHERE Sales_Order_Internal_Id__c in :orderInternalIds];
             //3.Get the Map<OrderLineId,List<InvoiceLines>> 
             Map<String,List<QtC_Mig_Invoice_Lines_Temp_Table__c >> orderLineIdInvoiceLinesMap = new Map<String,List<QtC_Mig_Invoice_Lines_Temp_Table__c >>();
        	//Iterating invoice lice to store it in Map
             for(QtC_Mig_Invoice_Lines_Temp_Table__c qTCInvoiceLines : invoiceLinesOrderProductList)
             {	
                 String invOrderIdLineIdItemQty = qTCInvoiceLines.Sales_Order_Internal_Id__c +'-'+ qTCInvoiceLines.Sales_Order_Line_Id__c + '-' + qTCInvoiceLines.Item__c+'-'+qTCInvoiceLines.Quantity__c;
                 if(orderLineIdInvoiceLinesMap.containskey(invOrderIdLineIdItemQty)){
                     orderLineIdInvoiceLinesMap.get(invOrderIdLineIdItemQty).add(qTCInvoiceLines);
                 }
                 else {
                     orderLineIdInvoiceLinesMap.put(invOrderIdLineIdItemQty,new List<QtC_Mig_Invoice_Lines_Temp_Table__c> {qTCInvoiceLines});       
                 }
                 
             }
             Map<String,Decimal> invLinesAmountMap = new Map<String,Decimal>();
              Map<String,Decimal> invLinesAmountWithoutTaxMap = new Map<String,Decimal>();
        	//Iterating inv lines record to create map
             for(QtC_Mig_Invoice_Lines_Temp_Table__c qTCInvoiceLines : invoiceLinesOrderProductList)
             {	
                 if(qTCInvoiceLines.IL_Amount_with_Tax__c !=null){
                     String invOrderIdLineIdItemQty = qTCInvoiceLines.Sales_Order_Internal_Id__c+'-'+qTCInvoiceLines.Sales_Order_Line_Id__c+'-'+qTCInvoiceLines.Item__c+'-'+qTCInvoiceLines.Quantity__c;
                     if(invLinesAmountMap.containskey(InvOrderIdLineIdItemQty)){
                         invLinesAmountMap.put(InvOrderIdLineIdItemQty,(qTCInvoiceLines.IL_Amount_with_Tax__c+invLinesAmountMap.get(InvOrderIdLineIdItemQty)));
                     }
                     else {
                         invLinesAmountMap.put(InvOrderIdLineIdItemQty,qTCInvoiceLines.IL_Amount_with_Tax__c);       
                     }    
                 }
                 //Without Tax
                 if(qTCInvoiceLines.Amount_Foreign_Currency_without_Symbol__c !=null){
                     String invOrderIdLineIdItemQty = qTCInvoiceLines.Sales_Order_Internal_Id__c+'-'+qTCInvoiceLines.Sales_Order_Line_Id__c+'-'+qTCInvoiceLines.Item__c+'-'+qTCInvoiceLines.Quantity__c;
                     if(invLinesAmountWithoutTaxMap.containskey(InvOrderIdLineIdItemQty)){
                         invLinesAmountWithoutTaxMap.put(InvOrderIdLineIdItemQty,(Decimal.valueOf(qTCInvoiceLines.Amount_Foreign_Currency_without_Symbol__c)+invLinesAmountWithoutTaxMap.get(InvOrderIdLineIdItemQty)));
                     }
                     else {
                         invLinesAmountWithoutTaxMap.put(InvOrderIdLineIdItemQty,Decimal.valueOf(qTCInvoiceLines.Amount_Foreign_Currency_without_Symbol__c));       
                     }    
                 }
             }
             List<T_OrderLineDMSummary__c> summaryList = new List<T_OrderLineDMSummary__c>();   
        	//Iterating the maps and finding out if Amount matches
             for(String ordProdId : orderLineIdMap.keySet() ){
                 //If its present in InvLineAmount Map
                 if(invLinesAmountMap.containskey(ordProdId)){  
                     //Checking if Amount value is same
                     if(orderLineAmountMap.get(ordProdId) == invLinesAmountMap.get(ordProdId)){
                         List<QTC_Mig_OrderProducts__c> tempList = orderLineIdMap.get(ordProdId);
                         List<QtC_Mig_Invoice_Lines_Temp_Table__c> invLineTempList = orderLineIdInvoiceLinesMap.get(ordProdId);
                         //Iterating the order prodcut list 
                         for(QTC_Mig_OrderProducts__c temp : tempList){
                             //Decimal ordProdAmount = Decimal.valueof(idToOrderLinesMap.get(temp.Id).Amount_Foreign_Currency_without_Symbol__c);
                             T_OrderLineDMSummary__c summary = new T_OrderLineDMSummary__c();
                             summary.NSOrderID__c = temp.Internal_ID__c;
                             summary.Quantity__c = temp.Quantity__c;
                             summary.NS_OL_Sum_Amount_with_Tax__c = orderLineAmountMap.get(ordProdId);
                             summary.NSLine_Sequence_Id__c = temp.Line_Sequence_Number__c;
                             summary.NSOrderLineitemID__c = String.valueof(temp.Line_ID__c);
                             summary.OL_Amount__c = Decimal.valueof(temp.Amount_Foreign_Currency_without_Symbol__c);
                             summary.OL_End_Date__c = temp.Invoice_End_Date__c;
                             summary.OL_StartDate__c = temp.Invoice_Start_Date__c;
                             summary.NS_OL_Amount_with_Tax__c = temp.Amount_with_Tax__c;
                             summary.OL_Paid_in_Full_Indicator__c = true;
                             summary.NS_OrderLine_Item__c = temp.item__c;
                             summary.Tax_Line_Indicator__c = String.valueof(temp.Tax__c);
                             summary.NS_IL_Amount_with_Tax__c = invLinesAmountMap.get(ordProdId);
                             summary.NS_IL_Amount_Total__c = invLinesAmountWithoutTaxMap.get(ordProdId);
                             if(invLineTempList.size() > 0 && invLineTempList[0].T_SourceName__c != null)
                             {summary.NS_Source_FileName__c = invLineTempList[0].T_SourceName__c;}
                             summaryList.add(summary);   
                         }  
                     }//Checking if OL Amount and Inv Line amount total is not different
                     else if(orderLineAmountMap.get(ordProdId) != invLinesAmountMap.get(ordProdId)){
                         List<QTC_Mig_OrderProducts__c> tempList = orderLineIdMap.get(ordProdId);
                         List<QtC_Mig_Invoice_Lines_Temp_Table__c> invLineTempList = orderLineIdInvoiceLinesMap.get(ordProdId);
                         //Iterating the order products 
                         for(QTC_Mig_OrderProducts__c temp : tempList){
                             //Decimal ordProdAmount = Decimal.valueof(idToOrderLinesMap.get(temp.Id).Amount_Foreign_Currency_without_Symbol__c);
                             T_OrderLineDMSummary__c summary = new T_OrderLineDMSummary__c();
                             summary.NSOrderID__c = temp.Internal_ID__c;
                             summary.Quantity__c = temp.Quantity__c;
                             summary.NS_OL_Sum_Amount_with_Tax__c = orderLineAmountMap.get(ordProdId);
                             summary.NSOrderLineitemID__c = String.valueof(temp.Line_ID__c);
                             summary.NSLine_Sequence_Id__c = temp.Line_Sequence_Number__c;
                             summary.OL_Amount__c = Decimal.valueof(temp.Amount_Foreign_Currency_without_Symbol__c);
                             summary.OL_End_Date__c = temp.Invoice_End_Date__c;
                             summary.NS_OL_Amount_with_Tax__c = temp.Amount_with_Tax__c;
                             summary.OL_StartDate__c = temp.Invoice_Start_Date__c;
                             summary.NS_OrderLine_Item__c = temp.item__c; 
                             summary.OL_with_Partially_paid_invoice__c =true; 
                             summary.Tax_Line_Indicator__c = String.valueof(temp.Tax__c);
                             summary.NS_IL_Amount_with_Tax__c = invLinesAmountMap.get(ordProdId);
                             summary.NS_IL_Amount_Total__c = invLinesAmountWithoutTaxMap.get(ordProdId);
                             if(invLineTempList.size() > 0 && invLineTempList[0].T_SourceName__c != null)
                             {summary.NS_Source_FileName__c = invLineTempList[0].T_SourceName__c;}
                             summaryList.add(summary);  
                         }                
                     }
                 }//If inv lines amount not present  
                 else {
                     List<QTC_Mig_OrderProducts__c> tempList = orderLineIdMap.get(ordProdId);
                     for(QTC_Mig_OrderProducts__c temp : tempList){
                         //Iterating the order product list
                         //Decimal ordProdAmount = Decimal.valueof(idToOrderLinesMap.get(temp.Id).Amount_Foreign_Currency_without_Symbol__c);
                         T_OrderLineDMSummary__c summary = getSummary(temp,orderLineAmountMap,ordProdId );
                         summaryList.add(summary); 
                     } 
                 }
             }
        	//Inserting the DMLine SUmmary records
             if(summaryList.size()>0)
             {Database.Insert(summaryList);}
    }
    //Helper
    public static T_OrderLineDMSummary__c getSummary(QTC_Mig_OrderProducts__c temp,Map<String,Decimal> orderLineAmountMap,String ordProdId ){
        T_OrderLineDMSummary__c summary = new T_OrderLineDMSummary__c();
        summary.NSOrderID__c = temp.Internal_ID__c;
        summary.Quantity__c = temp.Quantity__c;
        summary.NS_OL_Sum_Amount_with_Tax__c = orderLineAmountMap.get(ordProdId);
        summary.NSOrderLineitemID__c = String.valueof(temp.Line_ID__c);
        summary.NSLine_Sequence_Id__c = temp.Line_Sequence_Number__c;
        summary.OL_Amount__c = Decimal.valueof(temp.Amount_Foreign_Currency_without_Symbol__c);
        summary.OL_End_Date__c = temp.Invoice_End_Date__c;
        summary.NS_OL_Amount_with_Tax__c = temp.Amount_with_Tax__c;
        summary.OL_StartDate__c = temp.Invoice_Start_Date__c;
        summary.OL_Future_Invoice_Indicator__c = true;
        summary.NS_OrderLine_Item__c = temp.item__c;
        summary.Tax_Line_Indicator__c = String.valueof(temp.Tax__c);
        return summary;
    }
    public void finish(Database.BatchableContext bc){
             }
}