/**** @name :T_UpdatePmntAllocAmtInInvBatch
***** @author : KPMG
***** @date : Nov 11th, 2023
***** @description : Update Total Invoice Payment field from PaymentAllocations using InvoiceInternalId
******/
//Database.executeBatch(new T_UpdatePmntAllocAmtInInvBatch(),200);
public class T_UpdatePmntAllocAmtInInvBatch implements Database.Batchable<sObject>,Database.Stateful{
    public Database.querylocator start(Database.BatchableContext bc){
        //Query for QtC_Mig_Invoice_Temp_Table__c records
        String query = 'SELECT Id,Total_Invoice_Payment__c, Internal_ID__c,Sales_Order_Internal_Id__c,Payment_Exchange_Rate__c '
            			+' FROM QtC_Mig_Invoice_Temp_Table__c where Internal_ID__c != null';
        return Database.getqueryLocator(query);		
    }
    //Executing the queried records
    public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Temp_Table__c> invList){
        Map<String,QtC_Mig_Invoice_Temp_Table__c> invIdInvMap = new Map<String,QtC_Mig_Invoice_Temp_Table__c>();
        for(QtC_Mig_Invoice_Temp_Table__c inv : invList){
            if(!invIdInvMap.containsKey(inv.Internal_ID__c)){
                invIdInvMap.put(inv.Internal_ID__c,inv);
            }
        }
        List<QtC_Mig_PaymentAlloc_Temp_Table__c> pamentAllocList = [SELECT Id,Applied_Amount_Without_symbol__c,Invoice_Internal_ID__c,Exchange_Rate__c 
                                                                    FROM QtC_Mig_PaymentAlloc_Temp_Table__c
                                                                    WHERE Invoice_Internal_ID__c in: invIdInvMap.keyset()
                                                                    AND Invoice_Internal_ID__c != null
                                                                    AND Applied_Amount_Without_symbol__c != null ];
         Map<String, String> paymentExcRateMap = new Map<String, String>();
        for(QtC_Mig_PaymentAlloc_Temp_Table__c payExchange : pamentAllocList){
          if(invIdInvMap.containsKey(payExchange.Invoice_Internal_ID__c)){
              paymentExcRateMap.put(payExchange.Invoice_Internal_ID__c,payExchange.Exchange_Rate__c);
        }
        }
        Map<String,Decimal> invInternalIdPaymentAllocAmountMap = new Map<String,Decimal>();
        for(QtC_Mig_PaymentAlloc_Temp_Table__c pay :pamentAllocList){
            if(invInternalIdPaymentAllocAmountMap.containsKey(pay.Invoice_Internal_ID__c)){
                Decimal temp = Decimal.valueof(pay.Applied_Amount_Without_symbol__c)+invInternalIdPaymentAllocAmountMap.get(pay.Invoice_Internal_ID__c);
                invInternalIdPaymentAllocAmountMap.put(pay.Invoice_Internal_ID__c,temp);
                
            } else {
                invInternalIdPaymentAllocAmountMap.put(pay.Invoice_Internal_ID__c,Decimal.valueof(pay.Applied_Amount_Without_symbol__c));
            }
        }
        List<QtC_Mig_Invoice_Temp_Table__c> tempList = new List<QtC_Mig_Invoice_Temp_Table__c>();
        for(String invInternalId : invInternalIdPaymentAllocAmountMap.keyset()){
            if(invIdInvMap.containskey(invInternalId)){
                QtC_Mig_Invoice_Temp_Table__c tempInvoice = invIdInvMap.get(invInternalId);
                tempInvoice.Total_Invoice_Payment__c = invInternalIdPaymentAllocAmountMap.get(invInternalId);
                tempInvoice.Payment_Exchange_Rate__c = paymentExcRateMap.get(invInternalId);
                tempList.add(tempInvoice);
            }
        }
        update tempList;  
    }
    public void finish(Database.BatchableContext bc){
    }
}