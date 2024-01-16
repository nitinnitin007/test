/**** @Name        : T_PopulateInvDateTempOrdProdBatch
***** @Created By  : KPMG
***** @Created On  : Jan 03th, 2024
***** @Description : Populate Term Start Date based on Temp Inv Line with Temp Order Prod and update  OL Summary and Inv Line Temp table.
******/
//Database.executeBatch(new T_PopulateInvDateTempOrdProdBatch(),200);
public class T_PopulateInvDateTempOrdProdBatch implements Database.Batchable<sObject>,Database.Stateful {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //Get the Order Line Summary records
        String query = 'SELECT Id,Internal_ID__c, Line_ID__c, Line_Sequence_Number__c, Invoice_Internal_ID__c, Contract_Item_Start_Date__c, '
                       +'Contract_Item_End_Date__c, Rev_Rec_Start_Date__c, Rev_Rec_End_Date__c FROM QTC_Mig_OrderProducts__c '
                       +'WHERE  Internal_ID__c != NULL AND  Line_ID__c != NULL  '//Invoice_Start_Date__c = NULL AND
                       +'ORDER BY Internal_ID__c, Line_ID__c, Line_Sequence_Number__c, Invoice_Internal_ID__c'; 
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<QTC_Mig_OrderProducts__c> migOrderProdList){
        List<QTC_Mig_OrderProducts__c> migOrderProdToUpdate = new List<QTC_Mig_OrderProducts__c>();
        Map<String,QTC_Mig_OrderProducts__c> internalIdLineIdToMigOrderProdMap = new Map<String,QTC_Mig_OrderProducts__c>();
        //Get the Invoice line matched for the SalesOrder Internal Id and Line Id
        Map<String,List<QtC_Mig_Invoice_Lines_Temp_Table__c>> internalIdLineIdToInvLinesMap = new Map<String,List<QtC_Mig_Invoice_Lines_Temp_Table__c>>();
        //Get the Invoice Map 
        Map<String,QtC_Mig_Invoice_Temp_Table__c> internalIdToMigInvoiceMap = new Map<String,QtC_Mig_Invoice_Temp_Table__c>();
        //Sales Order Internal Ids
        Set<String> salesOrderInternalIds = new Set<String>();
        //Mig Invoice Internal Ids
        Set<String> invoiceInternalIds = new Set<String>();
        for(QTC_Mig_OrderProducts__c migOrderProd : migOrderProdList){
            if(! internalIdLineIdToMigOrderProdMap.containsKey(migOrderProd.Internal_ID__c + '-' + migOrderProd.Line_ID__c)){
                internalIdLineIdToMigOrderProdMap.put(migOrderProd.Internal_ID__c + '-' + migOrderProd.Line_ID__c,migOrderProd);
                salesOrderInternalIds.add(migOrderProd.Internal_ID__c);
           }
        }
        //Get the Temp Invoice lines for the Sales Order Internal Id + Line Id
        List<QtC_Mig_Invoice_Lines_Temp_Table__c> migInvLineList = [SELECT Id,Internal_ID__c, Line_ID__c, Line_Sequence_Number__c, Sales_Order_Internal_Id__c,
                                                                    Sales_Order_Line_Id__c,Contract_Start_Date__c, Contract_End_Date__c, Rev_Rec_Start_Date__c, Rev_Rec_End_Date__c,
                                                                    Term_Start_Date__c, Term_End_Date__c   
                                                                    FROM QtC_Mig_Invoice_Lines_Temp_Table__c 
                                                                    WHERE Sales_Order_Internal_Id__c != NULL 
                                                                    AND Sales_Order_Internal_Id__c IN :salesOrderInternalIds
                                                                    AND Sales_Order_Line_Id__c != NULL
                                                                    ORDER BY Sales_Order_Internal_Id__c,Sales_Order_Line_Id__c,Internal_ID__c ];
        //Get the Inv Lines for the Sales Order Internal Id+Line Id
        if(migInvLineList.size() > 0){
            for(QtC_Mig_Invoice_Lines_Temp_Table__c migInvLine :  migInvLineList){
                if(internalIdLineIdToInvLinesMap.containsKey(migInvLine.Sales_Order_Internal_Id__c + '-' +  migInvLine.Sales_Order_Line_Id__c)){
                    internalIdLineIdToInvLinesMap.get(migInvLine.Sales_Order_Internal_Id__c + '-' +  migInvLine.Sales_Order_Line_Id__c).add(migInvLine);
                }
                else{
                    internalIdLineIdToInvLinesMap.put(migInvLine.Sales_Order_Internal_Id__c + '-' +  migInvLine.Sales_Order_Line_Id__c,new List<QtC_Mig_Invoice_Lines_Temp_Table__c>{migInvLine});
                }
               invoiceInternalIds.add(migInvLine.Internal_ID__c); 
            }
        }
        //Get the Invoices for the Invoice Ids from Invoice line 
        if(internalIdLineIdToInvLinesMap.keySet().size() > 0){
            List<QtC_Mig_Invoice_Temp_Table__c> migInvoiceList = [SELECT Id,Internal_ID__c, Term_Start_Date__c, Term_End_Date__c, Start_Date__c, End_Date__c 
                                     							  FROM QtC_Mig_Invoice_Temp_Table__c 
                                     							  WHERE Internal_ID__c in :invoiceInternalIds
                                                                  AND Term_Start_Date__c != NULL
                                                                  ORDER BY Internal_ID__c];
            //Get the Map of Mig Invoices for the Invoice Internal Id
            if(migInvoiceList.size() > 0){
                for(QtC_Mig_Invoice_Temp_Table__c migInv : migInvoiceList){
                    if(! internalIdToMigInvoiceMap.containsKey(migInv.Internal_Id__c)){
                        internalIdToMigInvoiceMap.put(migInv.Internal_Id__c,migInv);
                    }
                }
            }
            for(String salesOrderIntIdLineIdMigOrderProd : internalIdLineIdToMigOrderProdMap.keySet()){
                if(internalIdLineIdToInvLinesMap.containsKey(salesOrderIntIdLineIdMigOrderProd)){
                    List<QtC_Mig_Invoice_Lines_Temp_Table__c> migInvLines = internalIdLineIdToInvLinesMap.get(salesOrderIntIdLineIdMigOrderProd);
                    //For one record get the Invoice detail and update else get the minimum Invoice Internal Id
            	    if(migInvLines != null && migInvLines.size() == 1){
                        if(internalIdToMigInvoiceMap.containsKey(migInvLines[0].Internal_Id__c)){
                          QTC_Mig_OrderProducts__c migOrderProd = internalIdLineIdToMigOrderProdMap.get(salesOrderIntIdLineIdMigOrderProd);
                          migOrderProd.Invoice_Start_Date__c = internalIdToMigInvoiceMap.get(migInvLines[0].Internal_Id__c).Term_Start_Date__c;
                          migOrderProdToUpdate.add(migOrderProd);
                        }
                    }
                    else if(migInvLines != null && migInvLines.size() > 1){
                        //Get the Min Invoice Internal 
                        QtC_Mig_Invoice_Lines_Temp_Table__c minInvInternalMigInvLine = getMinInvInternalId(migInvLines);
                        if(minInvInternalMigInvLine != null){
                            QTC_Mig_OrderProducts__c migOrderProd = internalIdLineIdToMigOrderProdMap.get(salesOrderIntIdLineIdMigOrderProd);
                            migOrderProd.Invoice_Start_Date__c = internalIdToMigInvoiceMap.get(minInvInternalMigInvLine.Internal_Id__c).Term_Start_Date__c;
                            migOrderProdToUpdate.add(migOrderProd);
                        }
                    }
                }
            }
        }
        //Update the records
        if(migOrderProdToUpdate.size() > 0){
            update migOrderProdToUpdate;
        }
    }
    //Helper
    public static QtC_Mig_Invoice_Lines_Temp_Table__c getMinInvInternalId(List<QtC_Mig_Invoice_Lines_Temp_Table__c> migInvLines){
        QtC_Mig_Invoice_Lines_Temp_Table__c migInvLineWithMinInternalId = null;
        for(QtC_Mig_Invoice_Lines_Temp_Table__c migInvLine : migInvLines){
            if(migInvLineWithMinInternalId == null ){migInvLineWithMinInternalId = migInvLine;}
            else {
                if(migInvLine.Internal_ID__c < migInvLineWithMinInternalId.Internal_ID__c ){
                    migInvLineWithMinInternalId = migInvLine;
                }
                 }
        }
        return migInvLineWithMinInternalId;
    }
    public void finish(Database.BatchableContext bc) {
    }    
}