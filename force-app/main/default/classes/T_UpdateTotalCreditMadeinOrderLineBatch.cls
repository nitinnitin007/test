/**** @name        : T_UpdateTotalCreditMadeinOrderLineBatch 
***** @author      : KPMG
***** @date        : Dec 11th, 2023
***** @description : Updating Total credit made from Invoice to OrderLineDMSummary table using SalesOrderInternalId.
******/

public class T_UpdateTotalCreditMadeinOrderLineBatch implements Database.Batchable<sObject>,Database.Stateful{

    public Database.querylocator start(Database.BatchableContext bc){

        String query = 'Select Id,Total_Invoice_Credit__c, Internal_ID__c,Sales_Order_Internal_Id__c from QtC_Mig_Invoice_Temp_Table__c where Total_Invoice_Credit__c != null';

        return Database.getqueryLocator(query);                 

    }

    public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Temp_Table__c> invoiceList){

        Map<String,List<QtC_Mig_Invoice_Temp_Table__c>> salesOrderIdInvMap = new Map<String,List<QtC_Mig_Invoice_Temp_Table__c>>();

        for(QtC_Mig_Invoice_Temp_Table__c inv : invoiceList){

            if(salesOrderIdInvMap.containsKey(inv.Sales_Order_Internal_Id__c)){

                salesOrderIdInvMap.get(inv.Sales_Order_Internal_Id__c).add(inv);

            }else{

                salesOrderIdInvMap.put(inv.Sales_Order_Internal_Id__c, new List<QtC_Mig_Invoice_Temp_Table__c> {inv});

            }

        }

        Map<String,Decimal> orderIdInvAmountMap = new Map<String,Decimal>();

       

        for(QtC_Mig_Invoice_Temp_Table__c temp :invoiceList ){

            if(orderIdInvAmountMap.containskey(temp.Sales_Order_Internal_Id__c)){

                orderIdInvAmountMap.put(temp.Sales_Order_Internal_Id__c,orderIdInvAmountMap.get(temp.Sales_Order_Internal_Id__c)+temp.Total_Invoice_Credit__c);

            } else{

                orderIdInvAmountMap.put(temp.Sales_Order_Internal_Id__c,temp.Total_Invoice_Credit__c);

            }

        }
        // Collecting Records from T_OrderLineDMSummary__c

        List<T_OrderLineDMSummary__c> summary = [Select Id,NSOrderID__c,Total_Credit_memo_applied__c

                                                 from T_OrderLineDMSummary__c where NSOrderID__c in:salesOrderIdInvMap.keyset()];

        List<T_OrderLineDMSummary__c> tempList = new List<T_OrderLineDMSummary__c>();

        for(T_OrderLineDMSummary__c temp :summary ){

            if(salesOrderIdInvMap.containskey(temp.NSOrderID__c)){
            //updating the Total_Credit_memo_applied__c in T_OrderLineDMSummary__c


                temp.Total_Credit_memo_applied__c = orderIdInvAmountMap.get(temp.NSOrderID__c);

               

                tempList.add(temp);

            }

        }

       
       //Updating the Records
        update tempList;

    }
   // Finish Method
    public void finish(Database.BatchableContext bc){

    }

}