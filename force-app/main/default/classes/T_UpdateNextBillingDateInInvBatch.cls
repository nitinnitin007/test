/**** @name        : T_UpdateNextBillingDateInInvBatch
***** @author      : KPMG
***** @date        : Dec 11th, 2023
***** @description : Get the Next Billing date from Temp Invoice with Inv Lines mapping.
******/

public class T_UpdateNextBillingDateInInvBatch implements Database.Batchable<sObject>,Database.Stateful {
    // Database.executeBatch(new T_UpdateNextBillingDateInInvBatch(),200);
    public static Final String INVOICE_STATUS_SENT = 'Sent';
    public class T_QtCInvoice_ComparatorInternalId implements Comparable {
        public QtC_Mig_Invoice_Temp_Table__c tempTableRecord { get; set; }

        public T_QtCInvoice_ComparatorInternalId(QtC_Mig_Invoice_Temp_Table__c record) {
            tempTableRecord = record;
        }

        public Integer compareTo(Object compareTo) {
            T_QtCInvoice_ComparatorInternalId compareRecord = (T_QtCInvoice_ComparatorInternalId)compareTo;
            if (tempTableRecord.Internal_ID__c < compareRecord.tempTableRecord.Internal_ID__c) {
                return 1;
            } else if (tempTableRecord.Internal_ID__c > compareRecord.tempTableRecord.Internal_ID__c) {
                return -1;
            } else {
                return 0;
            }
        }
    }
    public Database.queryLocator start(Database.BatchableContext bc)
    {	//Collecting the Invoice Records
        String query = 'SELECT Id,Sales_Order_Internal_Id__c,Internal_ID__c,Status__c, Invoice_Status__c,Date__c ,Next_Billing_Date__c '+
            ' FROM QtC_Mig_Invoice_Temp_Table__c where Sales_Order_Internal_Id__c != Null AND Date__c != NULL AND Status__c = \'Open\' Order By Sales_Order_Internal_Id__c';
        return Database.getQueryLocator(query);
    }
    //Method to execute the records
    public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Temp_Table__c> invList) {
        //Intializing Maps
        Map<String,List<QtC_Mig_Invoice_Temp_Table__c>> openInvoicesMap = new Map<String,List<QtC_Mig_Invoice_Temp_Table__c>>();
        Map<String,List<QtC_Mig_Invoice_Temp_Table__c>> openAndSentInvoiceMap = new Map<String,List<QtC_Mig_Invoice_Temp_Table__c>>();
        List<QtC_Mig_Invoice_Temp_Table__c> openAndSentInvList = new List<QtC_Mig_Invoice_Temp_Table__c>();
        Set<String> salesOrderIdSet = new Set<String>();
        //Iterating Invoice Records to Store it in Map and Collecting Invoice Records with Invoice Sent Status
        for(QtC_Mig_Invoice_Temp_Table__c tempInv :invList ){
            if(openInvoicesMap.containsKey(tempInv.Sales_Order_Internal_Id__c)){
                openInvoicesMap.get(tempInv.Sales_Order_Internal_Id__c).add(tempInv);
            }
            else
            {
                openInvoicesMap.put(tempInv.Sales_Order_Internal_Id__c,new List<QtC_Mig_Invoice_Temp_Table__c> {tempInv});
            }
            salesOrderIdSet.add(tempInv.Sales_Order_Internal_Id__c);
            if(tempInv.Invoice_Status__c == INVOICE_STATUS_SENT){
                openAndSentInvList.add(tempInv);
            }
        }
        //Storing the Invoice Records with Map of Sales Order Id and List of Invoice Records
        if(openAndSentInvList.size()>0){
            for(QtC_Mig_Invoice_Temp_Table__c openAndSentInv :openAndSentInvList){
                if(openAndSentInvoiceMap.containsKey(openAndSentInv.Sales_Order_Internal_Id__c)){
                    openAndSentInvoiceMap.get(openAndSentInv.Sales_Order_Internal_Id__c).add(openAndSentInv);
                }
                else
                {
                    openAndSentInvoiceMap.put(openAndSentInv.Sales_Order_Internal_Id__c,new List<QtC_Mig_Invoice_Temp_Table__c> {openAndSentInv});
                }
            }    
        }
        //Creating a Map to Store the last sent Invoice according to the Date__c Field
        Map<String,QtC_Mig_Invoice_Temp_Table__c> lastSentInvoiceMap = new Map<String,QtC_Mig_Invoice_Temp_Table__c>();
        //Storing it in the Map the last Invoice for each Sales order Id
        for(String intId :openAndSentInvoiceMap.keySet()){
            List<QtC_Mig_Invoice_Temp_Table__c> tempInv = openAndSentInvoiceMap.get(intId);
            List<T_QtCInvoice_ComparatorInternalId> tempComparatorList = new List<T_QtCInvoice_ComparatorInternalId>();
            for (QtC_Mig_Invoice_Temp_Table__c temp : tempInv) {
                tempComparatorList.add(new T_QtCInvoice_ComparatorInternalId(temp));
            }
            
            tempComparatorList.sort();
            
            List<QtC_Mig_Invoice_Temp_Table__c> sortedTempInvList = new List<QtC_Mig_Invoice_Temp_Table__c>();
            
            for (T_QtCInvoice_ComparatorInternalId tempComparator : tempComparatorList) {
                sortedTempInvList.add(tempComparator.tempTableRecord);
            }
            //integer indexPosition = sortedTempInvList.size();
            //lastSentInvoiceMap.put(intId,sortedTempInvList[0]);
            if(! lastSentInvoiceMap.containsKey(intId)){lastSentInvoiceMap.put(intId,sortedTempInvList[0]);}
            
        }
        //Map to Store the Next Invoice for the particular Sales Order Id
        Map<String,QtC_Mig_Invoice_Temp_Table__c> nextInvoiceDateMap = new Map<String,QtC_Mig_Invoice_Temp_Table__c>();
        Set<String> internalIdSet = new Set<String>();
        //Iterating List to sort by Internal Id in Descending Order
        for(String key :openInvoicesMap.keySet()){
            List<QtC_Mig_Invoice_Temp_Table__c> tempInv = openInvoicesMap.get(key);
            List<T_QtCInvoice_ComparatorInternalId> tempComparatorList = new List<T_QtCInvoice_ComparatorInternalId>();
            if(tempInv.size()>0){
                for (QtC_Mig_Invoice_Temp_Table__c temp : tempInv) {
                    tempComparatorList.add(new T_QtCInvoice_ComparatorInternalId(temp));
                }
                
                tempComparatorList.sort();
                
                List<QtC_Mig_Invoice_Temp_Table__c> sortedTempInvList = new List<QtC_Mig_Invoice_Temp_Table__c>();
                
                for (T_QtCInvoice_ComparatorInternalId tempComparator : tempComparatorList) {
                    sortedTempInvList.add(tempComparator.tempTableRecord);
                }
                Integer indexPosition;
                //Finding the Index position
                if(sortedTempInvList.size()>0){
                    for(QtC_Mig_Invoice_Temp_Table__c sortedTempInv :sortedTempInvList ){
                        if(lastSentInvoiceMap.containsKey(sortedTempInv.Sales_Order_Internal_Id__c)){
                            String tempOrderId = lastSentInvoiceMap.get(sortedTempInv.Sales_Order_Internal_Id__c).Internal_ID__c;
                            if(tempOrderId == sortedTempInv.Internal_ID__c ){
                                indexPosition = sortedTempInvList.indexOf(sortedTempInv); 
                                internalIdSet.add(sortedTempInv.Internal_ID__c);
                                if(indexPosition > 0){
                                    nextInvoiceDateMap.put(sortedTempInvList[indexPosition-1].Sales_Order_Internal_Id__c,sortedTempInvList[indexPosition-1]);    
                                } 
                            }
                        }           
                    }    
                }  
            }
        }
        //Updating the Next Billing Date
        List<QtC_Mig_Invoice_Temp_Table__c> recordsToUpdate = new List<QtC_Mig_Invoice_Temp_Table__c>();
        for(String orderId : lastSentInvoiceMap.keyset() ){
            QtC_Mig_Invoice_Temp_Table__c lastSentInvoice = lastSentInvoiceMap.get(orderId);
            if(nextInvoiceDateMap.containsKey(orderId)){
                QtC_Mig_Invoice_Temp_Table__c updateInv = nextInvoiceDateMap.get(orderId);
                lastSentInvoice.Next_Billing_Date__c = updateInv.Date__c;
                recordsToUpdate.add(lastSentInvoice);
            }
        }
        //Updating the records
        if(recordsToUpdate.size()>0){
            update recordsToUpdate; 
        }
    }
    //Batch job finishes
    public void finish(Database.BatchableContext bc){
        system.debug('Batch class finishes');
    }
}