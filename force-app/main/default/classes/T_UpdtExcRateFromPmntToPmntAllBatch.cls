/**** @name :T_UpdtExcFactorFromPmntToPmntBatch
***** @author : KPMG
***** @date : Nov 11th, 2023
***** @description : Update the Exchange Rate from Payments to Payment Allocation
******/
//Database.executeBatch(new T_UpdtExcFactorFromPmntToPmntAlloc(),200);
public class T_UpdtExcRateFromPmntToPmntAllBatch implements Database.Batchable<sObject>,Database.Stateful {
    public database.querylocator start(Database.BatchableContext bc){
     //Query for QtC_Mig_PaymentAlloc_Temp_Table__c  records
        String query = 'SELECT id,Internal_ID__c,Exchange_Rate__c FROM QtC_Mig_PaymentAlloc_Temp_Table__c ';
      return Database.getQueryLocator(query);  
    }
    //Executing the queried records
    public void execute(Database.BatchableContext bc,List<QtC_Mig_PaymentAlloc_Temp_Table__c> paymentAlloc){
        Map<String,QtC_Mig_Payments_Temp_Table__c> paymentIdMap = new Map<String,QtC_Mig_Payments_Temp_Table__c>();
        Set<String> internalIdSet = new Set<String>();
        //Collecting the Internal_ID__c in a set
        for(QtC_Mig_PaymentAlloc_Temp_Table__c temp :paymentAlloc){
            internalIdSet.add(temp.Internal_ID__c);
        }
        //Get the QtC_Mig_Payments_Temp_Table__c based on the Internal_ID__c
        List<QtC_Mig_Payments_Temp_Table__c> paymentList = [SELECT Id,Internal_ID__c,Exchange_Rate__c FROM QtC_Mig_Payments_Temp_Table__c WHERE
                                                 Internal_ID__c in: internalIdSet ];
        //Get the payment records internalid in a map
        for(QtC_Mig_Payments_Temp_Table__c pymnt :paymentList ){
            String internalId = pymnt.Internal_ID__c;
            if(paymentIdMap.containsKey(internalId)!=null){
                paymentIdMap.put(internalId,pymnt);
            }
        }
        List<QtC_Mig_PaymentAlloc_Temp_Table__c> tempList = new List<QtC_Mig_PaymentAlloc_Temp_Table__c>();
        //Updating the paymentAllocation fields
        for(QtC_Mig_PaymentAlloc_Temp_Table__c temp :paymentAlloc){
            if(paymentIdMap.containsKey(temp.Internal_ID__c)){
               	temp.Exchange_Rate__c = paymentIdMap.get(temp.Internal_ID__c).Exchange_Rate__c;
                tempList.add(temp); 
            }
        }
        //Updating the OrderLineSummary
        if(tempList!=Null){
        update tempList;    
        }  
    }
    public void finish(Database.BatchableContext bc){
    }
}