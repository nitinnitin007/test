/**** @name        : T_PaymentLookupBatch
***** @author      : KPMG
***** @date  : Nov 11th, 2023
***** @description : Batch to Update QtC_Mig_Payments_Temp_Table__c with blng__Account__c using 
                    Account__c and IntAppAccountNumber in Account
******/
public class T_PaymentLookupBatch implements Database.Batchable<sObject>,Database.Stateful {
    // Database.executeBatch(new T_PaymentLookupBatch(),200);
   public database.querylocator start(Database.BatchableContext bc)
   {
      //Collecting the QtC_Mig_Invoice_Temp_Table__c records 
      //String query = 'SELECT ID, Internal_ID__c FROM QtC_Mig_Invoice_Temp_Table__c WHERE Internal_ID__c != null ';
      String query = 'SELECT Id,Account__c,T_Account__c FROM QtC_Mig_Payments_Temp_Table__c WHERE Account__c != Null';
      return Database.getQueryLocator(query);//queryPayment);
   }
    //Method to execute the batch process
    public void execute(Database.BatchableContext bc,List<QtC_Mig_Payments_Temp_Table__c>  payExl)
    {	
       //Get the Temp payments for the AccountNumber
       Map<String,List<QtC_Mig_Payments_Temp_Table__c>> tempAccNumberPaymentsMap = new Map<String,List<QtC_Mig_Payments_Temp_Table__c>>();
        //Set<String> invAccNumber = new Set<String>();
        List<QtC_Mig_Payments_Temp_Table__c> tempPayList = new List<QtC_Mig_Payments_Temp_Table__c>();
        //Removing the AccountNumber subsidary
        for(QtC_Mig_Payments_Temp_Table__c tempPay :payExl )
        {
            if (tempPay.Account__c != null) 
            {	
                //Cleaning the Account Number
            	String accIdWithoutSpecChars = tempPay.Account__c.contains(':') ? tempPay.Account__c.Split(':')[0] : 
            													tempPay.Account__c.contains('_') ? tempPay.Account__c.Split('_')[0] : tempPay.Account__c;
            	tempPay.Account__c = accIdWithoutSpecChars;
              	tempPayList.add(tempPay);
            }
        }
        //Inserting the tempAccNumberPaymentsMap
        for(QtC_Mig_Payments_Temp_Table__c tempPay : tempPayList)
        {
            if(tempAccNumberPaymentsMap.containsKey(tempPay.Account__c))
            {
                tempAccNumberPaymentsMap.get(tempPay.Account__c).add(tempPay);
            }
            else
            {
                tempAccNumberPaymentsMap.put(tempPay.Account__c,new List<QtC_Mig_Payments_Temp_Table__c> {tempPay});
            }
        }
        //Collecting the Account for tempAccNumberPaymentsMap.keySet
        List<Account> accList = [SELECT Id,IntApp_Account_Number__c FROM Account 
                                 WHERE IntApp_Account_Number__c in: tempAccNumberPaymentsMap.keySet()
                                 AND IntApp_Account_Number__c != NULL];
        //Collecting the records to Update
        List<QtC_Mig_Payments_Temp_Table__c> recordsToUpdate = new List<QtC_Mig_Payments_Temp_Table__c>();
        //Mapping the Account ID
        for(Account acc : accList)
        {	
            if(tempAccNumberPaymentsMap.containsKey(acc.IntApp_Account_Number__c))
            {	
                //Collecting the payment records for Account Number
            	List<QtC_Mig_Payments_Temp_Table__c> payList = tempAccNumberPaymentsMap.get(acc.IntApp_Account_Number__c);
            	//Updating the Account Id
                if(payList != null){
                for(QtC_Mig_Payments_Temp_Table__c tempPay : payList)
                {
                    tempPay.T_Account__c = acc.Id;
                    recordsToUpdate.add(tempPay);
                }
                }
            }
        }
        //Updating the records
        if(recordsToUpdate.size()>0){
            update recordsToUpdate;
        }
    }
    // The batch job finishes
  public void finish(Database.BatchableContext bc){
  system.debug('batch is completed');
  }
}
  /*
   public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Temp_Table__c>  invExl)
    {
        //updatePaymentInvoice,Account from Temp Invoice 
        //Store Internal_ID__c values from QtC_Mig_Invoice_Temp_Table__c
        Set<String> internalIds = new Set<String>();
        for(QtC_Mig_Invoice_Temp_Table__c invTemp : invExl){
            internalIds.add(invTemp.Internal_ID__c);
        }
        // Store blng__Invoice__c records with matching NS_Inv_Internal_ID__c values
        Map<String,blng__Invoice__c> internalIdToBillingInv = new Map<String,blng__Invoice__c>();
        List<blng__Invoice__c> blngInvoiceList = [SELECT Id,NS_Inv_Internal_ID__c,blng__Account__c,T_IsMigrated__c FROM blng__Invoice__c
                                                  WHERE NS_Inv_Internal_ID__c != null 
                                                  AND NS_Inv_Internal_ID__c in:internalIds
                                                  AND T_IsMigrated__c = true];
        // Populate the Map with blng__Invoice__c records
        for(blng__Invoice__c blngInv: blngInvoiceList){
            internalIdToBillingInv.put(blngInv.NS_Inv_Internal_ID__c , blngInv);
        }
        // Collecting the QtC_Mig_Payments_Temp_Table__c records
        List<QtC_Mig_Payments_Temp_Table__c> paymentList =[SELECT Id,T_Invoice__c,T_Account__c,Internal_ID__c,Invoice_Internal_ID__c
                                                           FROM QtC_Mig_Payments_Temp_Table__c
                                                           WHERE Invoice_Internal_ID__c in :internalIdToBillingInv.keySet()
                                                           AND Invoice_Internal_ID__c != null];
        // List to store updated QtC_Mig_Payments_Temp_Table__c records
        List<QtC_Mig_Payments_Temp_Table__c> tempList = new List<QtC_Mig_Payments_Temp_Table__c>(); 
        // Updates QtC_Mig_Payments_Temp_Table__c records with matching blng__Invoice__c records
        for(QtC_Mig_Payments_Temp_Table__c payTemp: paymentList){
            if(internalIdToBillingInv.containskey(payTemp.Invoice_Internal_ID__c)){
                blng__Invoice__c blngInvoice = internalIdToBillingInv.get(payTemp.Invoice_Internal_ID__c);
                payTemp.T_Invoice__c = blngInvoice.Id;
                payTemp.T_Account__c = blngInvoice.blng__Account__c;
                tempList.add(payTemp);
            }
        }
         // Updates the record in the database
        if(tempList.size()>0){
            update tempList;
        }
  }
    // The batch job finishes
  public void finish(Database.BatchableContext bc){ }

}*/