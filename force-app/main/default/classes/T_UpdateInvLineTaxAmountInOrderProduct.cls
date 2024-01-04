/****  Name :T_UpdateInvLineTaxAmountInOrderProduct
***** Created By : KPMG
***** Created On : Nov 11th, 2023
***** Description : To Update InvLine Total Amount including tax in NS_IL_Amount_Total__c field in OrderLine Summary variable
******/
public class T_UpdateInvLineTaxAmountInOrderProduct implements Database.Batchable<sObject>,Database.Stateful{
	    //Database.executeBatch(new T_UpdateInvLineTaxAmountInOrderProduct(),200);
    public Database.querylocator start(Database.BatchableContext bc){
        //Collecting the records to be passed on to the batch
        String query = 'Select Id,Internal_ID__c, Sales_Order_Internal_Id__c, Sales_Order_Line_Id__c, IL_Amount_with_Tax__c from QtC_Mig_Invoice_Lines_Temp_Table__c where Sales_Order_Internal_Id__c != null and Sales_Order_Line_Id__c != null  ';
		return Database.getqueryLocator(query);		
    }
    //Executing the records 
    public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Lines_Temp_Table__c > invLineList){
        Map<String,List<QtC_Mig_Invoice_Lines_Temp_Table__c>> orderIdLineIdInvLineMap = new Map<String,List<QtC_Mig_Invoice_Lines_Temp_Table__c>>();
        //Iterating to store the orderIdLineIdInvLineMap
        for(QtC_Mig_Invoice_Lines_Temp_Table__c temp :invLineList){
            if(orderIdLineIdInvLineMap.containsKey(temp.Sales_Order_Internal_Id__c+'-'+temp.Sales_Order_Line_Id__c)){
               orderIdLineIdInvLineMap.get(temp.Sales_Order_Internal_Id__c+'-'+temp.Sales_Order_Line_Id__c).add(temp);
            }else{   
                orderIdLineIdInvLineMap.put(temp.Sales_Order_Internal_Id__c+'-'+temp.Sales_Order_Line_Id__c,new List<QtC_Mig_Invoice_Lines_Temp_Table__c> {temp});
            }
        }
        Map<String,Decimal> invLineAmountMap = new Map<String,Decimal>();
        //Iterating to store the invLineAmountMap
        for(QtC_Mig_Invoice_Lines_Temp_Table__c temp :invLineList){
            if(invLineAmountMap.containsKey(temp.Sales_Order_Internal_Id__c+'-'+temp.Sales_Order_Line_Id__c)){
               Decimal t = invLineAmountMap.get(temp.Sales_Order_Internal_Id__c+'-'+temp.Sales_Order_Line_Id__c);
                if(temp.IL_Amount_with_Tax__c !=null){
               	invLineAmountMap.put(temp.Sales_Order_Internal_Id__c+'-'+temp.Sales_Order_Line_Id__c,t+temp.IL_Amount_with_Tax__c);     
                } else
                {
                    
                    invLineAmountMap.put(temp.Sales_Order_Internal_Id__c+'-'+temp.Sales_Order_Line_Id__c,t); 
                }
               
            }else{   
                invLineAmountMap.put(temp.Sales_Order_Internal_Id__c+'-'+temp.Sales_Order_Line_Id__c,temp.IL_Amount_with_Tax__c);
            }
        }
        List<T_OrderLineDMSummary__c> summaryList = new List<T_OrderLineDMSummary__c>();
        //Collecting the T_OrderLineDMSummary__c records
        List<T_OrderLineDMSummary__c> ordProdList = [Select Id,NSOrderID__c, NSOrderLineitemID__c,NS_IL_Amount_Total__c from T_OrderLineDMSummary__c ];
        //Iterating the T_OrderLineDMSummary__c records to store the NS_IL_Amount_Total__c
        for(T_OrderLineDMSummary__c  temp :ordProdList ){
            if(orderIdLineIdInvLineMap.containskey(temp.NSOrderID__c+'-'+temp.NSOrderLineitemID__c)){
                temp.NS_IL_Amount_Total__c = invLineAmountMap.get(temp.NSOrderID__c+'-'+temp.NSOrderLineitemID__c);
                summaryList.add(temp);
            }
        }
     	//Updating the T_OrderLineDMSummary__c records
        update summaryList;
    }
    public void finish(Database.BatchableContext bc){
    }
}