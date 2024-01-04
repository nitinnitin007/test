/**** @name        : T_UpdateTotalPaymentMadeinOrderLineBatch
***** @author      : KPMG
***** @date        : Dec 11th, 2023
***** @description : Updating Total Payments made from Invoice to OrderLineDMSummary table using SalesOrderInternalId.
******/


public class T_UpdateTotalPaymentMadeinOrderLineBatch implements Database.Batchable<sObject>,Database.Stateful{

                  //Database.executeBatch(new T_UpdateTotalPaymentMadeinOrderLineBatch(),200);

    public Database.querylocator start(Database.BatchableContext bc){

        String query = 'Select Id,Total_Invoice_Payment__c, Internal_ID__c,Sales_Order_Internal_Id__c from QtC_Mig_Invoice_Temp_Table__c where Total_Invoice_Payment__c != null';

                             return Database.getqueryLocator(query);                         

    }

    public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Temp_Table__c> invList){

               Map<String,List<QtC_Mig_Invoice_Temp_Table__c>> salesOrderInternalIdInvMap = new Map<String,List<QtC_Mig_Invoice_Temp_Table__c>>();

        for(QtC_Mig_Invoice_Temp_Table__c inv : invList){

            if(salesOrderInternalIdInvMap.containsKey(inv.Sales_Order_Internal_Id__c)){

                salesOrderInternalIdInvMap.get(inv.Sales_Order_Internal_Id__c).add(inv);

            } else

            {

                salesOrderInternalIdInvMap.put(inv.Sales_Order_Internal_Id__c, new List<QtC_Mig_Invoice_Temp_Table__c> {inv});

            }

        }

        Map<String,Decimal> orderIdInvAmountMap = new Map<String,Decimal>();

       

        for(QtC_Mig_Invoice_Temp_Table__c temp :invList ){

            if(orderIdInvAmountMap.containskey(temp.Sales_Order_Internal_Id__c)){

                orderIdInvAmountMap.put(temp.Sales_Order_Internal_Id__c,orderIdInvAmountMap.get(temp.Sales_Order_Internal_Id__c)+temp.Total_Invoice_Payment__c);

            } else{

                orderIdInvAmountMap.put(temp.Sales_Order_Internal_Id__c,temp.Total_Invoice_Payment__c);

            }

        }

       
       //collecting records from T_OrderLineDMSummary__c
        List<T_OrderLineDMSummary__c> ordProdList = [Select Id,Total_Payments_Made__c,NSOrderID__c

                                                     from T_OrderLineDMSummary__c where NSOrderID__c in:salesOrderInternalIdInvMap.keyset()];

        List<T_OrderLineDMSummary__c> tempList = new List<T_OrderLineDMSummary__c>();

        for(T_OrderLineDMSummary__c temp :ordProdList ){
        //updating Total_Payments_Made__c in T_OrderLineDMSummary__c

            if(orderIdInvAmountMap.containskey(temp.NSOrderID__c)){

                temp.Total_Payments_Made__c = orderIdInvAmountMap.get(temp.NSOrderID__c);

               

                tempList.add(temp);

            }

        }

       
        //updating the records
        update tempList;

    }
    //Finish Method
    public void finish(Database.BatchableContext bc){

    }

}