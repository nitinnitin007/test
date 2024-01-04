/**** @name 		: T_CreditMemoLinesLookupBatch
***** @author 	    : KPMG
***** @date 	    : Nov 11th, 2023
***** @description 	: Updating Credit Note lookup using Internal Id  
                      Updating InvoiceLines Lookup using Billing Credit Note Id and Billing Invoice Line Id 
******/
public class T_CreditMemoLinesLookupBatch implements Database.Batchable<sObject>,Database.Stateful {
    //Database.executeBatch(new T_CreditMemoLinesLookupBatch('InvoiceLine'),200);
    //Database.executeBatch(new T_CreditMemoLinesLookupBatch('CreditNote'),200);
    public List<QtC_Mig_Invoice_Temp_Table__c> count = new List<QtC_Mig_Invoice_Temp_Table__c>();
    //File name  value to get constructor
    public string fileName;
    public T_CreditMemoLinesLookupBatch(String tempFileName){
        this.fileName = tempFileName;
    }
    //Querying the records
    public Database.queryLocator start(Database.BatchableContext bc)
    {
        //Querying the records based on constructor value
        if(fileName == 'CreditNote'){
            String queryInvLineCreditNotePopulate = 'Select Id,T_CreditNote__c,Internal_ID__c from QtC_Mig_CreditMemoLines_Temp_Table__c '
                									+ ' where  T_CreditNote__c = null ';
            return Database.getQueryLocator(queryInvLineCreditNotePopulate);
        } 
        else if(fileName == 'InvoiceLine')
        {
            String queryInvLineInvoiceLinePopulate = 'Select Id,Invoice_Internal_ID__c,Invoice_Line_ID__c,T_Invoice_Line__c from QtC_Mig_CreditMemoLines_Temp_Table__c '
                									 +' where  T_Invoice_Line__c = null ';
            return Database.getQueryLocator(queryInvLineInvoiceLinePopulate);
        }
        else
        {return null;}
    }
    //Executing the queried records
    public void execute(Database.BatchableContext bc,List<QtC_Mig_CreditMemoLines_Temp_Table__c> invsExl){
        //Calling the method for populating the CreditNote and InvoiceLine
        executeCreditNoteAndInvoiceLine(invsExl,this.fileName);
    }
    //Executing the records to populate the  CreditNote and InvoiceLine based on the Input File Name
    public void executeCreditNoteAndInvoiceLine(List<QtC_Mig_CreditMemoLines_Temp_Table__c> invsExl, String tempValue)
    {	
        //Checking the constructor value
        if(tempValue == 'CreditNote'){
            //Get  CM Lines Temp Table in a Map using Internal_ID__c
            Map<String,List<QtC_Mig_CreditMemoLines_Temp_Table__c>> ilineInternalIdToCreditNoteLinesMap = new Map<String,List<QtC_Mig_CreditMemoLines_Temp_Table__c>>();
            for(QtC_Mig_CreditMemoLines_Temp_Table__c tempCreditMemoLines : invsExl)
            {//Internal_ID__c 
                if(ilineInternalIdToCreditNoteLinesMap.containsKey(tempCreditMemoLines.Internal_ID__c))  
                {
                    ilineInternalIdToCreditNoteLinesMap.get(tempCreditMemoLines.Internal_ID__c).add(tempCreditMemoLines);
                }
                else 
                {
                    ilineInternalIdToCreditNoteLinesMap.put(tempCreditMemoLines.Internal_ID__c,new List<QtC_Mig_CreditMemoLines_Temp_Table__c>{tempCreditMemoLines});
                }
            }
            //Collecting the Billing Credit Notes
            List<blng__CreditNote__c> billingCreditNotes = [SELECT Id,NS_Credit_Note_Internal_ID__c,T_IsMigrated__c,blng__Account__c FROM blng__CreditNote__c 
                                                            WHERE T_IsMigrated__c = true 
                                                    		AND blng__Account__c != null 
                                                    		AND NS_Credit_Note_Internal_ID__c in :ilineInternalIdToCreditNoteLinesMap.keySet()];
            //Mapping CreditNote based on InternalId
            Map<String,blng__CreditNote__c> internalIdToBlngIdMap = new Map<String,blng__CreditNote__c>();
            for (blng__CreditNote__c billingCreditNote : billingCreditNotes) {
                internalIdToBlngIdMap.put(billingCreditNote.NS_Credit_Note_Internal_ID__c, billingCreditNote);
            }
            List<QtC_Mig_CreditMemoLines_Temp_Table__c> forUpdate = new List<QtC_Mig_CreditMemoLines_Temp_Table__c>();
            //Updating the CreditNote in QtC_Mig_CreditMemoLines_Temp_Table__c
            for (String internalId : ilineInternalIdToCreditNoteLinesMap.keySet()) {
                if (internalIdToBlngIdMap.containsKey(internalId)) 
                {
                    List<QtC_Mig_CreditMemoLines_Temp_Table__c> tempCMLinesList = ilineInternalIdToCreditNoteLinesMap.get(internalId);
                    if(tempCMLinesList != null ){
                    for(QtC_Mig_CreditMemoLines_Temp_Table__c tempCMLines : tempCMLinesList)
                    {
                        tempCMLines.T_CreditNote__c = internalIdToBlngIdMap.get(internalId).Id;
                        forUpdate.add(tempCMLines);
                    }
                    }
                }
            }
            //Updating the records
            if(forUpdate.size()>0)
                Database.update(forUpdate);    
        } 
        //Second constructor Value
        else if(fileName == 'InvoiceLine')
        {
            //Get Temp Invoice Lines in a map using Internal_ID__c
            Map<String,List<QtC_Mig_CreditMemoLines_Temp_Table__c>> ilineInternalIdToCreditNoteLinesMap = new Map<String,List<QtC_Mig_CreditMemoLines_Temp_Table__c>>();
            //Get the InternalIds
            Set<String> tempInvId = new Set<String>();
            for(QtC_Mig_CreditMemoLines_Temp_Table__c tempCreditMemoLines : invsExl)
            {//Invoice id and Line Id Keyset
                String keyInvIdLineId = tempCreditMemoLines.Invoice_Internal_ID__c+'-'+tempCreditMemoLines.Invoice_Line_ID__c;
                if(ilineInternalIdToCreditNoteLinesMap.containsKey(keyInvIdLineId))  
                {
                    ilineInternalIdToCreditNoteLinesMap.get(keyInvIdLineId).add(tempCreditMemoLines);
                }
                else 
                {
                    ilineInternalIdToCreditNoteLinesMap.put(keyInvIdLineId,new List<QtC_Mig_CreditMemoLines_Temp_Table__c>{tempCreditMemoLines});
                }
                tempInvId.add(tempCreditMemoLines.Invoice_Internal_ID__c);
            }
            //Get the InvoiceLines for Matching NsInvId and NsInvLineId
            List<blng__InvoiceLine__c> matchingBInvLines = [SELECT Id,	NS_Inv_Internal_ID__c,NS_Line_ID__c,T_IsMigrated__c FROM blng__InvoiceLine__c 
                                                            WHERE T_IsMigrated__c = true 
                                                            AND NS_Inv_Internal_ID__c in :tempInvId
                                                            ];
            //Storing the blng__InvoiceLine__c  in internalIdToBlngIdMap
            Map<String,blng__InvoiceLine__c > internalIdToBlngIdMap = new Map<String,blng__InvoiceLine__c >();
            for (blng__InvoiceLine__c  bInvLine : matchingBInvLines) {
                internalIdToBlngIdMap.put(bInvLine.NS_Inv_Internal_ID__c+'-'+bInvLine.NS_Line_ID__c, bInvLine);
            }
            List<QtC_Mig_CreditMemoLines_Temp_Table__c> forUpdate = new List<QtC_Mig_CreditMemoLines_Temp_Table__c>();
            //Updating the InvoiceLines in QtC_Mig_CreditMemoLines_Temp_Table__c
            for (String internalId : ilineInternalIdToCreditNoteLinesMap.keySet()) {//QtC_Mig_Invoice_Lines_Temp_Table__c
                if (internalIdToBlngIdMap.containsKey(internalId)) 
                {
                    List<QtC_Mig_CreditMemoLines_Temp_Table__c> tempCMLinesList = ilineInternalIdToCreditNoteLinesMap.get(internalId);
                    if(tempCMLinesList != null){
                    for(QtC_Mig_CreditMemoLines_Temp_Table__c tempCMLines : tempCMLinesList)
                    {
                        tempCMLines.T_Invoice_Line__c = internalIdToBlngIdMap.get(internalId).Id;
                        forUpdate.add(tempCMLines);
                    }
                    }
                }
            }
            //Updating the QtC_Mig_CreditMemoLines_Temp_Table__c
            if(forUpdate.size()>0)
                Database.update(forUpdate);    	    
        }
    }   
    public void finish(Database.BatchableContext bc){
        system.debug('Batch Process ends ');
    }
}