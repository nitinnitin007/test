/***** @name        : ServiceBillingProcessBatch 
 ***** @author      : KPMG
 ***** @date        : Oct 09th, 2023
 ***** @description : From Slip Header, collect the details to create Invoices
                      Type T : Goes to Res Summary >Billing Inv and Invoice Lines
                      Type F : Goes to Billing Inv and Invoice Lines
                      Differentiator : Billing Invoice and Invoice Lines have CreatedFromServiceBillingBatch flag

                      Step 1: From the OA Slip records generate Resource Summaries at Resource,Role level aggregation.
                      Step 2: Then aggregate the Resource Summaries at Order Product Level
                      Step 2.1: If no Order Products, then Aggregate at Contract level.
                      Step 3: Create Invoices based on the Resource Summaries aggregation (2).
                      Step 4: Create Invoice lines based on the Invoice (3) and Resource Summay Aggregation (2).
                      Step 5: After inserting the Invoices and Invoice Lines ,update the Slip Headers and Slip Records are procesed.
                      Type T:
                      Group By: By Project then By OA Invoice Id,Contract then By Order Product, then By Resource,Resource Role ==>Roll up Hours and Minutes,Total - Save it in Resource Summary
                      Group By: From Resource Summary, Group By Project, OA Invoice Id, Contract,Order Product , then Create Invoice and Invoice Lines.
                      Type F:
                      Group By: By Project then By OA Invoice Id,Contract then By Order Product,Description  ==>Roll up Total , don't save it in Resource Summary.Just used to hold the values.
                      Group By: From Resource Summary (not inserted), Group By Project, OA Invoice Id, Contract,Order Product , then Create Invoice and Invoice Lines.
                      Note:One invoice mapped to One Order ,One Order mapped to one Project
Enhancement          :* The OA Slip Headers and Lines will be pushed at any time, any day, this batch logic has changed to:
                        Step 1: Collect the OA Headers based on Processed flag.
                        Step 2: Do the same aggregation logic and Before creating Invoices:
                             * Check the Header OA exists in Billing Invoice with Type exists get the Invoice Id and Insert only Invoice Lines.
                             * Else create the Billing Invoices and Invoice Lines.
                             * Update the OA Slip lines are Processed.
                             * Check the OA Header amount matches with the Billing Invoice Amount, mark the OA Header record as Processed.
                      * If no Order Products then get the Tax,Billing details from Contract's Subsidiary/*
//To run on demand
//Database.executeBatch(new ServiceBillingProcessBatch(),100);
//To run as a scheduled job
ServiceBillingProcessBatch batch = new ServiceBillingProcessBatch();
String sch = '0 0 21 * * ?';//  Class runs every night at 9:00 PM.
System.schedule('Service Billing Process Batch - Create Invoice and Lines', sch, batch);
*/
//Run it for every 1 hr: 5:30 then 6:30
/*
  ServiceBillingProcessBatch batch = new ServiceBillingProcessBatch();
  System.schedule('Service Billing Process-Create Invoice and Lines', '0 30 * * * ?', batch);
 */ 
public class ServiceBillingProcessBatch implements Database.Batchable<sObject>, Database.stateful,Schedulable{
/**
 * @description : To Collect the error records to send the report.
 */ 
public static FINAL String INVOICE_TYPE_T_AND_M = 'T&M';//For Billing Invoice Creation
public static FINAL String SLIP_LINE_TYPE_T_AND_M = 'T';//For Slip Lines Aggregation
public static FINAL String SLIP_LINE_TYPE_F = 'F';//Fixed
public static FINAL String F_TYPE_NARRATIVE_YES = 'FYes';
public static FINAL String F_TYPE_NARRATIVE_NO = 'FNo';
public static FINAL Integer NET_30 = 30;//Payment Term default value if Order Prod is null and Contrcat's Payment Term is null
public static FINAL Integer DEFAULT_QUANTITY_FOR_BILLING = 1;
public static FINAL String ERR_STATUS_SUCCESS = 'Success';
public static FINAL String ERR_STATUS_ERROR = 'Error';
public static FINAL String BILLING_INVOICE_STATUS_DRAFT = 'Draft';
public Map<String,String> errorMessagesMap = new Map<String,String>();//ResourceSummary
public Map<String,String> invErrorMessagesMap = new Map<String, String>();//Billing Invoice
public Map<String,String> invLineErrorMessagesMap = new Map<String, String>();//Billing Invoice Lines
public Map<String,List<blng__Invoice__c>> oaInvoiceHeaderToBlngInvIdsMap = new Map<String,List<blng__Invoice__c>>();//OA Header to Billing Invoices
public Map<String,OA_Slip_Header__c> slipHeadersMap = new Map<String,OA_Slip_Header__c>();
/**
 * @description: Query to get the records
 * @param: Batch Context
 * @return:List of Slip Headers
 */ 
  public Database.QueryLocator start(Database.BatchableContext bc) {
    //Get the Slip Headers which are not processed
    String query = 'SELECT ID,Name,OA_Invoice_ID__c,OA_Invoice_Name__c,Invoice_Date__c,Processed__c,Processed_On__c,OA_Invoice_Subtotal__c, '
                   + ' OA_Invoice_Subtotal_Currency__c,Process_Status__c  '
                   + ' FROM OA_Slip_Header__c WHERE Processed__c = FALSE AND OA_Invoice_ID__c != NULL AND OA_Invoice_Subtotal__c != NULL ';
                   //+ ' AND Process_Status__c != :ERR_STATUS_ERROR ';
    return Database.getQueryLocator(query);   
    }
 /**
 * @description: Execute the records
 * @param: List of Slip Headers
 */ 
    public void execute(Database.BatchableContext bc, List<OA_Slip_Header__c> oaSlipHeaders){
    
    //Slip Header Map : OA Invoice Id to Slip Headers
   // Map<String,OA_Slip_Header__c> slipHeadersMap = new Map<String,OA_Slip_Header__c>();
    if(oaSlipHeaders.size() > 0){
     for(OA_Slip_Header__c header : oaSlipHeaders){
         if(! slipHeadersMap.containsKey(header.OA_Invoice_ID__c)){
            slipHeadersMap.put(header.OA_Invoice_ID__c,header);
          }
       }
    }
    //Validate Header and Lines for Error data
    //Update Error Records with Processed Flag as true to skip those records for the Billing process.
    slipHeadersMap = updateErrorRecords(slipHeadersMap);
    //Create Invoice and Invoice lines for the Header
    createInvAndInvLinesForHeader(slipHeadersMap,oaInvoiceHeaderToBlngInvIdsMap,errorMessagesMap,invErrorMessagesMap,invLineErrorMessagesMap);
}
 //Helpers
 /**
 * @description: Helper - Create Inv And InvLines For Header
 * @param: Slip Headers Map
 */ 
    public static void createInvAndInvLinesForHeader(Map<String,OA_Slip_Header__c> slipHeadersMap,Map<String,List<blng__Invoice__c>> oaInvoiceHeaderToBlngInvIdsMap,Map<String,String> errorMessagesMap,Map<String,String> invErrorMessagesMap,Map<String,String> invLineErrorMessagesMap){
        //Get the OA Invoice from Header to Billing Invoices Map
        if(slipHeadersMap.keySet().size() > 0){
            oaInvoiceHeaderToBlngInvIdsMap = getBillingInvoiceIdsForOAInvoceId(slipHeadersMap.keySet());
        //Get the Slip Records for the Headers
        List<OA_Slip__c> oaSlipRecords = new List<OA_Slip__c>();
        //Update Error Records with Processed Flag as true to skip those records for the Billing process.
        //Set<Id> errorSlipHeaderIds = updateErrorRecords(slipHeadersMap);
        oaSlipRecords = [SELECT ID,Name,Project__c,Project__r.Name,Product__c,Invoice__r.Name,Resource__c,Hour__c,Minute__c,Processed_On__c,
                         Product__r.Name,Order_Product__c,Type__c,Order_Product__r.blng__LegalEntity__c,Contract__c,Process_Status__c,
                         Order_Product__r.blng__TaxRule__c,Order_Product__r.blng__TaxTreatment__c,Job_Code_Resource_Role__c,
                         Rate__c,Date__c,Total__c,OA_Invoice_ID__c,Time_Entry_Narrative__c,Contract__r.Subsidiary__c,Product__r.SBQQ__TaxCode__c
                         FROM OA_Slip__c
                         WHERE OA_Invoice_ID__c in :slipHeadersMap.keySet() 
                         AND Processed__c = FALSE AND Project__c != NULL AND Contract__c != NULL
                         AND OA_Invoice_ID__c != NULL AND Type__c != NULL AND Total__c != NULL AND Process_Status__c != :ERR_STATUS_ERROR
                         ORDER BY Project__c,OA_Invoice_ID__c,Order_Product__c,Resource__c,Job_Code_Resource_Role__c Limit 10000];
        //Group by Project
        Map<String,List<OA_Slip__c>> pjtToOASlipMap = new Map<String,List<OA_Slip__c>>();
        //Group By OA Invoice
        Map<String,List<OA_Slip__c>> invToOASlipMap = new Map<String,List<OA_Slip__c>>();
        //Group By Contract
        Map<String,List<OA_Slip__c>> contractToOASlipMap = new Map<String,List<OA_Slip__c>>();
        //Group By OrederProdutcts
        Map<String,List<OA_Slip__c>> productToOASlipMap = new Map<String,List<OA_Slip__c>>();
        //Group By Resource for Type T (non Fixed)
        Map<String,List<OA_Slip__c>> resourceToOASlipMap = new Map<String,List<OA_Slip__c>>();
        //Group By Resource for Type T (non Fixed)
        //Map<String,List<OA_Slip__c>> resourceRoleToOASlipMap = new Map<String,List<OA_Slip__c>>();
        
        if(oaSlipRecords.size() > 0){
            pjtToOASlipMap.putAll(getPjtToOASlipMap(oaSlipRecords));
        }
        //Group by Invoice
        if(pjtToOASlipMap.keySet().size() > 0){
        for(String project : pjtToOASlipMap.keySet())
        {
            //Get the List of OASlip records per Project
            List<OA_Slip__c> oaSlipPerProject = pjtToOASlipMap.get(project);   
            if(oaSlipPerProject != null)
            {
                //Key : Project +Invoice
                invToOASlipMap.putAll(getInvToOASlipMap(oaSlipPerProject));
            }
        }
        }
        //Group by Contract
        /*if(invToOASlipMap.keySet().size() > 0){
        for(String invoice : invToOASlipMap.keySet())
        {
            //Get the List of OASlip records per Contract
            List<OA_Slip__c> oaSlipPerInvoice = invToOASlipMap.get(invoice);   
            if(oaSlipPerInvoice != null)
            {
                contractToOASlipMap.putAll(getContractToOASlipMap(oaSlipPerInvoice));
            }
        }
        }*/
        //Group by Order Product
        if(invToOASlipMap.keySet().size() > 0){
        for(String invoice : invToOASlipMap.keySet())
        {
            //Get the List of OASlip records per Invoice
            List<OA_Slip__c> oaSlipPerInvoice = invToOASlipMap.get(invoice);   
            if(oaSlipPerInvoice != null)
            {
                productToOASlipMap.putAll(getTheSlipPerInvoice(oaSlipPerInvoice));
            }
        }
        }
        //Group by Resource based on Contract, the Order Products may be null for Legacy Slip lines.
        if(contractToOASlipMap.keySet().size() > 0){
        for(String contract : contractToOASlipMap.keySet())
        {
            //Get the List of OASlip records per contract
            List<OA_Slip__c> oaSlipPerContract = productToOASlipMap.get(contract);   
            if(oaSlipPerContract != null)
            {
                resourceToOASlipMap.putAll(getTheResourceRoleToOASlipMap(oaSlipPerContract));
            }
        }
        }
        //Group by Resource based on Order Product
        if(productToOASlipMap.keySet().size() > 0){
        for(String product : productToOASlipMap.keySet())
        {
            //Get the List of OASlip records per Product
            List<OA_Slip__c> oaSlipPerProduct = productToOASlipMap.get(product);   
            if(oaSlipPerProduct != null)
            {
                resourceToOASlipMap.putAll(getTheResourceRoleToOASlipMap(oaSlipPerProduct));
            }
        }
        }
       
        
        //Now get the grouped values to create the Summary record. 
        //By Project then By OA Invoice Id,then By Order Product, then By Resource
        if(pjtToOASlipMap.keySet().size() > 0){
        List<Resource_Summary__c> resourceSummaryList = new List<Resource_Summary__c>();
        List<OA_Slip__c> oaSlipListForProcessedUpdate = new List<OA_Slip__c>();
        for(String project : pjtToOASlipMap.keySet())
        {
            //Get the Grouped values for Project,Invoice,Resource
            if(pjtToOASlipMap.containsKey(project))
            {
                //Get the aggregated values
                List<Resource_Summary__c> resourceSummaryListPerProject = getAggregatedValuesForProject(project,pjtToOASlipMap.get(project),invToOASlipMap,productToOASlipMap);
                if(resourceSummaryListPerProject != null) 
                {
                    //Get the unique records 
                    for(Resource_Summary__c summary : resourceSummaryListPerProject){
                       if(! resourceSummaryList.contains(summary)){
                        resourceSummaryList.add(summary);
                        }
                    }
                }
            }
        }
        if(resourceSummaryList.size() > 0)
        {
            try{
                //Get the Type F fixed products out of this list , don't indert into resource summary.
                List<Resource_Summary__c> slipsWithTypeTM = new List<Resource_Summary__c>();
                List<Resource_Summary__c> slipsWithTypeF = new List<Resource_Summary__c>();
                for(Resource_Summary__c slip : resourceSummaryList){
                    if(slip.Type__c == SLIP_LINE_TYPE_T_AND_M)
                    {slipsWithTypeTM.add(slip);}
                    else{slipsWithTypeF.add(slip);}
                }
                //Insert Fixed Product
                insertFixedProduct(slipsWithTypeF,oaSlipRecords,slipHeadersMap,oaInvoiceHeaderToBlngInvIdsMap,invErrorMessagesMap,invLineErrorMessagesMap);
                List<Database.SaveResult> results = Database.insert(slipsWithTypeTM);//resourceSummaryList);
                //Create Invoice and Invoice Lines from Summary Records
                Set<Id> successIds = new Set<Id>();
                for(Database.SaveResult result : results)
                {
                    if(result.isSuccess())
                    {successIds.add(result.getId());}
                    else{ 
                        // Operation failed, so get all errors                
                         for(Database.Error err : result.getErrors()) {
                         //System.debug('The following error has occurred.');                    
                         //System.debug(err.getStatusCode() + ': ' + err.getMessage());
                         //System.debug('Fields that affected this error: ' + err.getFields());
                         if(! errorMessagesMap.containsKey(result.Id))
                            {errorMessagesMap.put(result.Id,err.getStatusCode() + ': ' + err.getMessage() + ': '+err.getFields());}
                         }
                       }
                }
                //Get the records to collect the Invoice line details
                if(successIds.size() > 0)
                {
                    //Create Billing Invoice and Invoice Lines
                    createInvAndLinesBasedOnResSummary(successIds,oaSlipRecords,slipHeadersMap,oaInvoiceHeaderToBlngInvIdsMap,invErrorMessagesMap,invLineErrorMessagesMap);
                }
            }
            catch(Exception e)
            {
               // Send Email Alert//
               System.debug('Exception:'+e.getMessage());
                if(! errorMessagesMap.containsKey('ResourceSummary Exp:'))
                   {errorMessagesMap.put('ResourceSummary Exp:','Exception ResourceSummary' + ': ' + e.getMessage());}
            }
        }
        }
    }
    }
    /**
 * @description: Helper - Update the Error slip records
 * @param: Set of OA Header Invoices
 * @return: Map of Header with OA Invoice Ids without Error Headers
 */
    public static Map<String,OA_Slip_Header__c> updateErrorRecords(Map<String,OA_Slip_Header__c> slipHeadersMap){
        List<OA_Slip__c> oaSlipErrorRecordsUpdate = new List<OA_Slip__c>();
        List<OA_Slip_Header__c> oaSlipErrorHeaderRecordsUpdate = new List<OA_Slip_Header__c>();
        Map<String,List<String>> slipErrorHeaderIdsMap = new Map<String,List<String>>();
        Set<Id> slipErrorIdsSet = new Set<Id>();
        List<OA_Slip__c> oaSlipErrorRecords = new List<OA_Slip__c>();
         oaSlipErrorRecords = [SELECT ID,Name,Project__c,Project__r.Name,Product__c,Invoice__r.Name,Resource__c,Hour__c,Minute__c,Processed_On__c,
                         Product__r.Name,Order_Product__c,Type__c,Order_Product__r.blng__LegalEntity__c,Contract__c,Process_Status__c,
                         Order_Product__r.blng__TaxRule__c,Order_Product__r.blng__TaxTreatment__c,Job_Code_Resource_Role__c,OA_Error__c,
                         Rate__c,Date__c,Total__c,OA_Invoice_ID__c,Time_Entry_Narrative__c,Contract__r.Subsidiary__c,Product__r.SBQQ__TaxCode__c
                         FROM OA_Slip__c
                         WHERE OA_Invoice_ID__c in :slipHeadersMap.keySet() 
                         AND Processed__c = FALSE AND (Project__c = NULL OR Contract__c = NULL
                         OR OA_Invoice_ID__c = NULL OR Type__c = NULL OR Total__c = NULL OR Resource__c = NULL OR Job_Code_Resource_Role__c = NULL )
                         ORDER BY Project__c,OA_Invoice_ID__c,Order_Product__c,Resource__c,Job_Code_Resource_Role__c Limit 1000]; 
        if(oaSlipErrorRecords.size() > 0){
            for(OA_Slip__c slip : oaSlipErrorRecords){
                if(slip.Contract__c == null){slip.OA_Error__c = slip.OA_Error__c == null ? ''+'No Contract__c.' : slip.OA_Error__c + 'No Contract__c.';}
                if(slip.Project__c == null){slip.OA_Error__c = slip.OA_Error__c == null ? ''+'No Project__c.' : slip.OA_Error__c + 'No Project__c.';}
                if(slip.Type__c == null){
                    slip.OA_Error__c = slip.OA_Error__c == null ? ''+'No Type__c and make sure the Resource__c and Resource_Role__c for Type T.' : slip.OA_Error__c + 'No Type__c and make sure the Resource__c and Resource_Role__c for Type T.';}
                else{
                    if(slip.Type__c == SLIP_LINE_TYPE_T_AND_M && slip.Resource__c == null){
                        slip.OA_Error__c = slip.OA_Error__c == null ? ''+'No Resource__c for Type T.' : slip.OA_Error__c + 'No Resource__c for Type T.';}
                    if(slip.Type__c == SLIP_LINE_TYPE_T_AND_M && slip.Job_Code_Resource_Role__c == null){
                        slip.OA_Error__c = slip.OA_Error__c == null ? ''+'No Job_Code_Resource_Role__c for Type T.' : slip.OA_Error__c + 'No Job_Code_Resource_Role__c for Type T.';}
                }
                if(slip.OA_Invoice_ID__c == null){slip.OA_Error__c = slip.OA_Error__c == null ? ''+'No OA_Invoice_ID__c.' : slip.OA_Error__c + 'No OA_Invoice_ID__c.';}
                if(slip.Total__c == null){slip.OA_Error__c = slip.OA_Error__c == null ? ''+'No Total__c.' : slip.OA_Error__c + 'No Total__c.';}
                if(slip.OA_Error__c != null){
                    if(slipErrorHeaderIdsMap.containsKey(slip.OA_Invoice_ID__c)){
                        slipErrorHeaderIdsMap.get(slip.OA_Invoice_ID__c).add(slip.Name + ':' + slip.OA_Error__c);
                    }
                    else{slipErrorHeaderIdsMap.put(slip.OA_Invoice_ID__c, new List<String> {slip.Name + ':' + slip.OA_Error__c});}
                    slip.Processed__c = true;slip.Processed_On__c = System.DateTime.Now();slip.Process_Status__c = ERR_STATUS_ERROR  ;oaSlipErrorRecordsUpdate.add(slip);}
            }
            if(oaSlipErrorRecordsUpdate.size()>0){
                List<Database.saveResult> results = Database.update(oaSlipErrorRecordsUpdate);
                if(results!= null){for(Database.saveResult result : results){if(result.isSuccess()){slipErrorIdsSet.add(result.getId());}}}
                //Update the Header Records
                for( String headerOAInvId : slipErrorHeaderIdsMap.keySet()) {
                    if(slipHeadersMap.containsKey(headerOAInvId)){
                        OA_Slip_Header__c header = slipHeadersMap.get(headerOAInvId);
                        if(header != null){
                            header.Process_Status__c = ERR_STATUS_ERROR;
                            header.SF_Process_Error__c = String.join(slipErrorHeaderIdsMap.get(headerOAInvId),',');
                            header.Processed__c = true;
                            header.Processed_On__c = System.DateTime.Now();
                            oaSlipErrorHeaderRecordsUpdate.add(header);
                            slipHeadersMap.remove(headerOAInvId);
                        }
                    }
                }
                if(oaSlipErrorHeaderRecordsUpdate.size() > 0){
                    List<Database.saveResult> resultsHeader = Database.update(oaSlipErrorHeaderRecordsUpdate);
                }
            }
        }
        return slipHeadersMap;
    }
    /**
 * @description: Helper - Get the Billing Invoice Ids for the OA Header Invoice Ids
 * @param: Set of OA Header Invoice Ids
 * @return: Map of OA Invoice Id to Billing Invoice Lines
 */
    public static Map<String,List<blng__Invoice__c>> getBillingInvoiceIdsForOAInvoceId(Set<String> oaHeaderInvIds){
        Map<String,List<blng__Invoice__c>> oaInvoiceHeaderToBlngInvIdsMap = new Map<String,List<blng__Invoice__c>>();
        //Get the Billing Invoices for the OA InvoiceIds.
        List<blng__Invoice__c> blngInvoices = [SELECT Id,OA_Invoice_Id__c,Invoice_Type__c,Contract__c,CreatedFromServiceBillingBatch__c,blng__Order__c
                                               FROM blng__Invoice__c
                                               WHERE OA_Invoice_Id__c in :oaHeaderInvIds
                                               AND blng__InvoiceStatus__c  = :BILLING_INVOICE_STATUS_DRAFT
                                               AND OA_Invoice_Id__c != NULL
                                               AND CreatedFromServiceBillingBatch__c = TRUE];
        if(blngInvoices.size() > 0){
            for(blng__Invoice__c inv : blngInvoices){
                if(oaInvoiceHeaderToBlngInvIdsMap.containsKey(inv.OA_Invoice_Id__c))
                {oaInvoiceHeaderToBlngInvIdsMap.get(inv.OA_Invoice_Id__c).add(inv);}
                else{
                    oaInvoiceHeaderToBlngInvIdsMap.put(inv.OA_Invoice_Id__c,new List<blng__Invoice__c>{inv});
                }
            }
        }
        return oaInvoiceHeaderToBlngInvIdsMap;
    } 
 //Craete invoice and lines for Fixed type
  public static void insertFixedProduct(List<Resource_Summary__c> slipsWithTypeF,List<OA_Slip__c> oaSlipRecords, Map<String,OA_Slip_Header__c> slipHeadersMap,Map<String,List<blng__Invoice__c>> oaInvoiceHeaderToBlngInvIdsMap,Map<String,String> invErrorMessagesMap,Map<String,String> invLineErrorMessagesMap){
        List<OA_Slip__c> oaSlipListForProcessedUpdate = new List<OA_Slip__c>();
        List<OA_Slip_Header__c> oaSlipHeaderListForProcessedUpdate = new List<OA_Slip_Header__c>();
        List<Resource_Summary__c> summaryList = slipsWithTypeF;
        Set<Id> successIds = new Set<Id>();
                    if(summaryList.size() > 0)
                    {
                        //Create Invoices and Invoice Lines
                        List<blng__InvoiceLine__c> invLinesForCreate = new List<blng__InvoiceLine__c>();
                        //Create Invoices then CreateBillingInvLines
                        invLinesForCreate = createBillingInvLines(summaryList,slipHeadersMap,oaInvoiceHeaderToBlngInvIdsMap,invErrorMessagesMap);
                        if(invLinesForCreate.size() > 0)
                        {
                            List<Database.SaveResult> results = Database.insert(invLinesForCreate);
                            for(Database.SaveResult result : results)
                            {
                               if(result.isSuccess())
                                {successIds.add(result.getId());}
                                else{ 
                                // Operation failed, so get all errors                
                                for(Database.Error err : result.getErrors()) {
                                //System.debug('The following error has occurred.');                    
                                //System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                //System.debug('Fields that affected this error: ' + err.getFields());
                                if(! invLineErrorMessagesMap.containsKey(result.Id))
                                {invLineErrorMessagesMap.put(result.Id,err.getStatusCode() + ': ' + err.getMessage() + ': '+err.getFields());}
                                }
                                }
                            }
                            //Update the Processed Records in Slip Object
                            for(OA_Slip__c slip : oaSlipRecords){
                                //Update the records for Type F
                                if(slip.Type__c != null && slip.Type__c == SLIP_LINE_TYPE_F){
                                slip.Processed__c  = true;
                                slip.Process_Status__c = ERR_STATUS_SUCCESS;
                                slip.Processed_On__c = System.DateTime.Now();
                                oaSlipListForProcessedUpdate.add(slip);
                                }
                            }
                            if(oaSlipListForProcessedUpdate.size() > 0)
                            {Database.update(oaSlipListForProcessedUpdate);}
                        }
                    }
  }
 /**
 * @description: Helper - Create Inv And Lines BasedOn ResSummary
 * @param: Successfully inserted Resource Summaries,Slip Records,SlipHeadersMap
 */
    public static void createInvAndLinesBasedOnResSummary(Set<Id> successIds, List<OA_Slip__c> oaSlipRecords, Map<String,OA_Slip_Header__c> slipHeadersMap,Map<String,List<blng__Invoice__c>> oaInvoiceHeaderToBlngInvIdsMap,Map<String,String> invErrorMessagesMap,Map<String,String> invLineErrorMessagesMap){
        List<OA_Slip__c> oaSlipListForProcessedUpdate = new List<OA_Slip__c>();
        List<OA_Slip_Header__c> oaSlipHeaderListForProcessedUpdate = new List<OA_Slip_Header__c>();
        List<Resource_Summary__c> summaryList = [SELECT Id,Project__c,OA_Invoice_ID__c,Product__c,Order_Product__r.OrderId,
                                                 Order_Product__c,Product__r.Name,Order_Product__r.Order.AccountId,
                                                 Resource__c,Hours__c,Type__c,Total__c,Order_AccountId__c,Contract__c,Contract__r.AccountId,
                                                 Contract__r.Account.ShippingStreet,Contract__r.Account.ShippingCity,Contract__r.Account.ShippingCountry,
                                                 Contract__r.Account.ShippingPostalCode,Contract__r.Subsidiary__c,Contract__r.Software_Payment_Terms__c
                                                 FROM Resource_Summary__c 
                                                 WHERE Id in : successIds 
                                                 Order By Project__c,OA_Invoice_ID__c,Order_Product__c,Resource__c 
                                                 Limit 100];
                    if(summaryList.size() > 0)
                    {
                        //Create Invoices
                        List<blng__InvoiceLine__c> invLinesForCreate = new List<blng__InvoiceLine__c>();
                        //Create Invoices then CreateBillingInvLines
                        invLinesForCreate = createBillingInvLines(summaryList,slipHeadersMap,oaInvoiceHeaderToBlngInvIdsMap,invErrorMessagesMap);
                        if(invLinesForCreate.size() > 0)
                        {
                            List<Database.SaveResult> results = Database.insert(invLinesForCreate);
                            for(Database.SaveResult result : results)
                            {
                               if(result.isSuccess())
                                {successIds.add(result.getId());}
                                else{ 
                                // Operation failed, so get all errors                
                                for(Database.Error err : result.getErrors()) {
                                //System.debug('The following error has occurred.');                    
                                //System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                //System.debug('Fields that affected this error: ' + err.getFields());
                                if(! invLineErrorMessagesMap.containsKey(result.Id))
                                {invLineErrorMessagesMap.put(result.Id,err.getStatusCode() + ': ' + err.getMessage() + ': '+err.getFields());}
                                }
                                }
                            }
                            //Update the Processed Records in Slip Object
                            for(OA_Slip__c slip : oaSlipRecords){
                                if(slip.Type__c != null && slip.Type__c == SLIP_LINE_TYPE_T_AND_M){
                                slip.Processed__c  = true;
                                slip.Process_Status__c = ERR_STATUS_SUCCESS;
                                slip.Processed_On__c = System.DateTime.Now();
                                oaSlipListForProcessedUpdate.add(slip);
                            }
                            }
                            if(oaSlipListForProcessedUpdate.size() > 0)
                            {Database.update(oaSlipListForProcessedUpdate);}
                        }
                    }
    }
 /**
 * @description: Helper - Get Pjt To OASlip Map
 * @param: Slip Records
 * @return: Map of Project to Slips
 */
    public static Map<String,List<OA_Slip__c>> getPjtToOASlipMap(List<OA_Slip__c> oaSlipRecords){
            Map<String,List<OA_Slip__c>> pjtToOASlipMap = new Map<String,List<OA_Slip__c>>();
            for(OA_Slip__c osaSli : oaSlipRecords)
            {
                if(pjtToOASlipMap.containsKey(osaSli.Project__c))
                {pjtToOASlipMap.get(osaSli.Project__c).add(osaSli);}
                else{pjtToOASlipMap.put(osaSli.Project__c,new List<OA_Slip__c>{osaSli});}
            }
            return pjtToOASlipMap;
    }
     /**
 * @description: Helper - Get OA Inv Id To OASlip Map
 * @param: Slip Records per Project
 * @return: Map of OA InvoiceId to Slips
 */
    public static Map<String,List<OA_Slip__c>> getInvToOASlipMap(List<OA_Slip__c> oaSlipPerProject){
        Map<String,List<OA_Slip__c>> invToOASlipMap = new Map<String,List<OA_Slip__c>>();
        for(OA_Slip__c slipForInv : oaSlipPerProject)
        {
           if(invToOASlipMap.containsKey(slipForInv.Project__c + '-'+slipForInv.OA_Invoice_ID__c))
           {invToOASlipMap.get(slipForInv.Project__c + '-'+slipForInv.OA_Invoice_ID__c).add(slipForInv);}
           else{invToOASlipMap.put(slipForInv.Project__c + '-'+slipForInv.OA_Invoice_ID__c,new List<OA_Slip__c>{slipForInv});}
        }
        return invToOASlipMap; 
    }
        /**
 * @description: Helper - Get Contract To OASlip Map
 * @param: Slip Records per Project
 * @return: Map of OA InvoiceId to Slips
 */
    public static Map<String,List<OA_Slip__c>> getContractToOASlipMap(List<OA_Slip__c> oaSlipPerInvoice){
        Map<String,List<OA_Slip__c>> contractToOASlipMap = new Map<String,List<OA_Slip__c>>();
        for(OA_Slip__c slipForContract : oaSlipPerInvoice)
        {
           if(contractToOASlipMap.containsKey(slipForContract.Contract__c + '-'+slipForContract.OA_Invoice_ID__c))
           {contractToOASlipMap.get(slipForContract.Contract__c + '-'+slipForContract.OA_Invoice_ID__c).add(slipForContract);}
           else{contractToOASlipMap.put(slipForContract.Contract__c + '-'+slipForContract.OA_Invoice_ID__c,new List<OA_Slip__c>{slipForContract});}
        }
        return contractToOASlipMap; 
    }
 /**
 * @description: Helper - Get Resource To OASlip Map For Type T
 * @param: Slip Records
 * @return: Map of Resource to Slips
 */
    /*public static Map<String,List<OA_Slip__c>>  getTheResourceToOASlipMap(List<OA_Slip__c> oaSlipPerProduct){
        Map<String,List<OA_Slip__c>> resourceToOASlipMap = new Map<String,List<OA_Slip__c>>();
        for(OA_Slip__c slipForProd : oaSlipPerProduct)
                {
                    //Check for the Type
                    if(slipForProd.Type__c == SLIP_LINE_TYPE_T_AND_M )//&& slipForProd.Job_Code_Resource_Role__c != null && slipForProd.Rate__c != null){
                    {    if(resourceToOASlipMap.containsKey(slipForProd.Resource__c))//+'-'+slipForProd.Job_Code_Resource_Role__c+'-'+slipForProd.Rate__c))
                        {resourceToOASlipMap.get(slipForProd.Resource__c).add(slipForProd);}
                        else{resourceToOASlipMap.put(slipForProd.Resource__c,new List<OA_Slip__c>{slipForProd});}}
                }
        return resourceToOASlipMap;
    }*/
/**
 * @description: Helper - Get Resource Role To OASlip Map For Type T
 * @param: Slip Records
 * @return: Map of Resource Role to Slips
 */
    public static Map<String,List<OA_Slip__c>>  getTheResourceRoleToOASlipMap(List<OA_Slip__c> oaSlipPerOrdProd){
        Map<String,List<OA_Slip__c>> resourceRoleToOASlipMap = new Map<String,List<OA_Slip__c>>();
        for(OA_Slip__c slipForOrdProd : oaSlipPerOrdProd)
                {
                    //For Legacy Records the Order Prod is null, add them with Contract Key
                     if(slipForOrdProd.Order_Product__c == null){}
                    //Check for the Type
                    if(slipForOrdProd.Type__c == SLIP_LINE_TYPE_T_AND_M && slipForOrdProd.Job_Code_Resource_Role__c != null && slipForOrdProd.Resource__c != null){
                       if(resourceRoleToOASlipMap.containsKey(slipForOrdProd.Resource__c+'-'+slipForOrdProd.Job_Code_Resource_Role__c))
                        {resourceRoleToOASlipMap.get(slipForOrdProd.Resource__c+'-'+slipForOrdProd.Job_Code_Resource_Role__c).add(slipForOrdProd);}
                        else{resourceRoleToOASlipMap.put(slipForOrdProd.Resource__c+'-'+slipForOrdProd.Job_Code_Resource_Role__c,new List<OA_Slip__c>{slipForOrdProd});}}
                }
       
        return resourceRoleToOASlipMap;
    }
 /**
 * @description: Helper - Get Resource Rate To OASlip Map For Type T
 * @param: Slip Records
 * @return: Map of Resource to Slips
 */
  public static Map<String,List<OA_Slip__c>>  getTheResourceRateToOASlipMap(List<OA_Slip__c> oaSlipPerResourceRole){
        Map<String,List<OA_Slip__c>> resourceRateToOASlipMap = new Map<String,List<OA_Slip__c>>();
        for(OA_Slip__c slipForResourceRole : oaSlipPerResourceRole)
                {
                    //Check for the Type
                    if(slipForResourceRole.Type__c == SLIP_LINE_TYPE_T_AND_M && slipForResourceRole.Rate__c != null)
                    {   //if(slipForResourceRole.Job_Code_Resource_Role__c != null && 
                           //if(slipForResourceRole.Rate__c != null){}
                        if(resourceRateToOASlipMap.containsKey(slipForResourceRole.Resource__c +'-'+slipForResourceRole.Job_Code_Resource_Role__c+'-'+String.valueOf(slipForResourceRole.Rate__c)))
                        {resourceRateToOASlipMap.get(slipForResourceRole.Resource__c +'-'+slipForResourceRole.Job_Code_Resource_Role__c+'-'+String.valueOf(slipForResourceRole.Rate__c)).add(slipForResourceRole);}
                        else{resourceRateToOASlipMap.put(slipForResourceRole.Resource__c +'-'+slipForResourceRole.Job_Code_Resource_Role__c+'-'+String.valueOf(slipForResourceRole.Rate__c),new List<OA_Slip__c>{slipForResourceRole});}
                    }
                
                }
        return resourceRateToOASlipMap;
    }
 /**
 * @description: Helper - Get the Slip records per Invoice,Add the Invoice in the Key as one order product can be in 2 invoices.
 * @param: Slip Records per Invoice
 * @return: Map of Order Prod + OA Inv to Slips
 */
    //If no Order Product ,Contract will be the key.
   public static Map<String,List<OA_Slip__c>> getTheSlipPerInvoice(List<OA_Slip__c> oaSlipPerInvoice){
        Map<String,List<OA_Slip__c>> productToOASlipMap = new Map<String,List<OA_Slip__c>>();
        //Get the Product values and Group it
        for(OA_Slip__c slipForInv : oaSlipPerInvoice)
        {
            if(productToOASlipMap.containsKey(slipForInv.Contract__c+'-'+slipForInv.Order_Product__c + '-'+slipForInv.OA_Invoice_ID__c))
            {productToOASlipMap.get(slipForInv.Contract__c+'-'+slipForInv.Order_Product__c + '-'+slipForInv.OA_Invoice_ID__c).add(slipForInv);}
            else{productToOASlipMap.put(slipForInv.Contract__c+'-'+slipForInv.Order_Product__c + '-'+slipForInv.OA_Invoice_ID__c,new List<OA_Slip__c>{slipForInv});}
        }
        return productToOASlipMap;
    }
    //Billing Inv lines
 /**
 * @description: Helper - Create Billing Inv Lines
 * @param: Inserted Res Summary,Slip Headers Map
 * @return: List of Billing Inv Line
 */
    public static List<blng__InvoiceLine__c> createBillingInvLines(List<Resource_Summary__c> summaryList,Map<String,OA_Slip_Header__c> slipHeadersMap,Map<String,List<blng__Invoice__c>> oaInvoiceHeaderToBlngInvIdsMap,Map<String,String> invErrorMessagesMap){
        List<blng__InvoiceLine__c> invLinesForCreate = new List<blng__InvoiceLine__c>();
        List<blng__Invoice__c> invoicesForCreate = new List<blng__Invoice__c>();
        //Aggregate the ResourceSummary based on Project,Invoice,InvLine,Resource
        List<Resource_Summary__c> resourceSummaryForInvLinesList = getAggregatedValuesForInvLines(summaryList);
        if(resourceSummaryForInvLinesList != null){
            //Create Invoices
            //Get the Order for Order Product 
            Map<String,Order> orderProdToOrder = getOrderForOrderProd(resourceSummaryForInvLinesList);
            //Get the Contract Billing Account Map - for Type F if Order Prod is null
            Map<String,Contract> contractToAccountMap = getContractIdToContractForAccount(resourceSummaryForInvLinesList);
            //Get the Produt Id To Product for Summaries: as the Type F Summaries are not stored in ResourceSummary 
            Map<String,Product2> prodIdToProdMap = getProdIdsToProducts(resourceSummaryForInvLinesList);
            //Get the Order Product for Order Product Ids - not able to get the Project's Order Product's Tax details
            Map<String,OrderItem> orderProdIdToOrderProd = getOrderProdForOrderProdIds(resourceSummaryForInvLinesList);
            Map<String,List<Resource_Summary__c>> resourceSummaryForInvoices = getAggregatedValuesForInvoices(resourceSummaryForInvLinesList);
            //Create Invoices
            //One invoice mapped to One Order
            //One Order mapped to one Project
            Map<String,Resource_Summary__c> summaryToExistingOABlngInvoiceMap = new Map<String,Resource_Summary__c>();
            if(resourceSummaryForInvoices != null && resourceSummaryForInvoices.keySet().size() > 0){
               List<Resource_Summary__c> existingOAInvoiceNewToInsert = new List<Resource_Summary__c>();
               for(String invoiceIdWithOrdProdAndType : resourceSummaryForInvoices.keySet())
               {
                    Resource_Summary__c summary = resourceSummaryForInvoices.get(invoiceIdWithOrdProdAndType)[0];
                    if(summary != null){
                        //Check for the OA Header Invoice and Type already exists in Billing Invoice
                        //Get the OA Invoice Id from the combo key OA Invoice : Contract : OrderProd - Type
                        String oAInvId = invoiceIdWithOrdProdAndType.split(':')[0];
                        //System.debug('invoiceIdWithOrdProdAndType.split[0]:'+invoiceIdWithOrdProdAndType.split(':')[0]);
                        //System.debug('invoiceIdWithOrdProdAndType.split[0]:'+invoiceIdWithOrdProdAndType.split(':')[1]);
                        //System.debug('invoiceIdWithOrdProdAndType.split[0]:'+invoiceIdWithOrdProdAndType.split('-')[1]);
                        //String contractId = ((invoiceIdWithOrdProdAndType.split(':')[1]).split('-')[0]).split(':')[0];
                        //String ordProdId = invoiceIdWithOrdProdAndType.split(':')[1];//.split('-')[0]).split(':')[1];
                        //String type = invoiceIdWithOrdProdAndType.split('-')[1];                                                                      
                        if(oaInvoiceHeaderToBlngInvIdsMap.containsKey(oAInvId)){
                            //OAInvTypeFrmSvcBlngProcess__c Invoice_Type__c
                            List<blng__Invoice__c> invoices = oaInvoiceHeaderToBlngInvIdsMap.get(oAInvId);
                            if(invoices != null){
                                for(blng__Invoice__c invTemp : invoices){
                                    if(invTemp.blng__Order__c != null 
                                       && (orderProdToOrder != null && orderProdToOrder.keySet().size() > 0 
                                           && orderProdToOrder.containsKey(summary.Order_Product__c) 
                                       && invTemp.blng__Order__c == orderProdToOrder.get(summary.Order_Product__c).Id )
                                       && invTemp.Contract__c == summary.Contract__c)
                                      {
                                         //Collect the Invoices and Create Only Invoice lines for these Invoices
                                          if(! summaryToExistingOABlngInvoiceMap.containsKey(invTemp.Id)){
                                                summaryToExistingOABlngInvoiceMap.put(invTemp.Id,summary);
                                          }
                                       }
                                    //For Legacy Slip Lines , Only Contrat exists, no Order Product
                                    else if(invTemp.blng__Order__c == null && invTemp.Contract__c != null && invTemp.Contract__c == summary.Contract__c ){
                                         //Collect the Invoices and Create Only Invoice lines for these Invoices
                                          if(! summaryToExistingOABlngInvoiceMap.containsKey(invTemp.Id)){
                                                summaryToExistingOABlngInvoiceMap.put(invTemp.Id,summary);
                                          }
                                    }
                                    //Else Create New Invoice and Invoice Lines for those new Invoices
                                    else{
                                         //Create Billing Invoice - For new OA Invoice Ids
                                         if(! existingOAInvoiceNewToInsert.contains(summary)){existingOAInvoiceNewToInsert.add(summary);
                                        // if(orderProdToOrder != null && orderProdToOrder.keySet().size() > 0 && orderProdToOrder.containsKey(summary.Order_Product__c))
                                         //{
                                             //Create Billing Invoice - For new OA Invoice Ids
                                            blng__Invoice__c invoice = createBillingInvoice(summary,contractToAccountMap,orderProdToOrder,slipHeadersMap);
                                            if(invoice != null && (! invoicesForCreate.contains(invoice)))
                                            {invoicesForCreate.add(invoice);}
                                        // }
                                                                                             }
                                    }
                                }
                            }
                            //Step 1: Compare the Invoice values Project,Order,Type with Current summary record.
                            //Step 2: If matches, create invoice lines for the Invoice
                            //Step 3: Else Create Invoice and Invoice lines.
                            //Create only Invoice Lines and Check for the Invoice amount with OA Header Amount,both are matches update Invoice with Processed flag.
                            if(summaryToExistingOABlngInvoiceMap.size() > 0){
                                //Create Only Invoice Lines for this Invoices.
                            }
                        }
                        else {
                        // if(orderProdToOrder != null && orderProdToOrder.keySet().size() > 0 && orderProdToOrder.containsKey(summary.Order_Product__c))
                        // {
                             //Create Billing Invoice - For new OA Invoice Ids
                             blng__Invoice__c invoice = createBillingInvoice(summary,contractToAccountMap,orderProdToOrder,slipHeadersMap);
                             if(invoice != null && (! invoicesForCreate.contains(invoice)))
                             {invoicesForCreate.add(invoice);}
                        // }
                        }
                    }
               }
            }
            if(invoicesForCreate.size() > 0){
               //Insert the Invoices
               Set<String> invIds = new Set<String>();
               List<Database.SaveResult> results = Database.Insert(invoicesForCreate);
               if(results != null && results.size()>0)
               {
                  for(Database.SaveResult result : results){
                  if(result.IsSuccess())
                    {invIds.add(result.getId());}
                  else{ 
                        // Operation failed, so get all errors                
                         for(Database.Error err : result.getErrors()) {
                         //System.debug('The following error has occurred.');                    
                         //System.debug(err.getStatusCode() + ': ' + err.getMessage());
                         //System.debug('Fields that affected this error: ' + err.getFields());
                         if(! invErrorMessagesMap.containsKey(result.Id))
                            {invErrorMessagesMap.put(result.Id,err.getStatusCode() + ': ' + err.getMessage() + ': '+err.getFields());}
                         }
                       }
                  }
               }
               if(invIds.size() > 0){
                //Order to Invoice Map
                Map<String,blng__Invoice__c> orderToInvoiceMap = new Map<String,blng__Invoice__c>();
                //Contract To InvoiceMap
                Map<String,blng__Invoice__c> contractToInvoiceMap = new Map<String,blng__Invoice__c>();
                //Get the Created Invoice Records
                List<blng__Invoice__c> newInvoices = [SELECT Id,blng__Account__c,blng__Order__c,SFDC_Services_Project__c,
                                                      blng__InvoiceDate__c,OA_Invoice_Name__c,OA_Invoice_ID__c,OA_Slip_Header__c,
                                                      OA_Invoice_Subtotal__c,OA_Invoice_Subtotal_Currency__c,Contract__c  
                                                      FROM blng__Invoice__c where 
                                                      (Id in :invIds //New Invoices
                                                       OR Id in :summaryToExistingOABlngInvoiceMap.keySet()) //Existing Invoices 
                                                      AND CreatedFromServiceBillingBatch__c = TRUE];
                if(newInvoices.size() > 0)
                {
                   for(blng__Invoice__c newInv : newInvoices){
                       if(newInv.blng__Order__c != null){
                          if(! orderToInvoiceMap.containsKey(newInv.blng__Order__c)){
                          orderToInvoiceMap.put(newInv.blng__Order__c,newInv);
                        }
                       }
                       else{
                          if(! contractToInvoiceMap.containsKey(newInv.Contract__c+':'+newInv.OA_Invoice_ID__c)){
                          contractToInvoiceMap.put(newInv.Contract__c+':'+newInv.OA_Invoice_ID__c,newInv);
                          }
                       }
                   }
                }
                   
                //Get the LegalEntity Name To Legal Entity for Summaries
                Map<String,String> nameToLegalEntitiesMap = getLegalEntities(resourceSummaryForInvLinesList);
                //Get the Produt Tax Code,LegalEntity To Tax Treatment for Summaries
                Map<String,String> prodToTaxTreatmentMap = getTaxTreatMentForProducts(resourceSummaryForInvLinesList);
                //Create Invoice Lines
                invLinesForCreate = setupBillingInvoiceLines(resourceSummaryForInvLinesList,orderProdToOrder,nameToLegalEntitiesMap ,orderProdIdToOrderProd, prodIdToProdMap, prodToTaxTreatmentMap,contractToInvoiceMap,orderToInvoiceMap,slipHeadersMap);
                   
                }
               }
            
        }
        return invLinesForCreate;
    }
    //Populate data for Billing  Invoice Lines
    public static  List<blng__InvoiceLine__c> setupBillingInvoiceLines(List<Resource_Summary__c> resourceSummaryForInvLinesList, Map<String,Order> orderProdToOrder,Map<String,String> nameToLegalEntitiesMap ,Map<String,OrderItem> orderProdIdToOrderProd,Map<String,Product2> prodIdToProdMap,Map<String,String> prodToTaxTreatmentMap,Map<String,blng__Invoice__c> contractToInvoiceMap,Map<String,blng__Invoice__c> orderToInvoiceMap,Map<String,OA_Slip_Header__c> slipHeadersMap){
       List<blng__InvoiceLine__c> invLinesForCreate = new List<blng__InvoiceLine__c>();
        for(Resource_Summary__c resSummary : resourceSummaryForInvLinesList ){
                  blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
                  if(orderProdToOrder != null && orderProdToOrder.keySet().size() > 0 && orderProdToOrder.containsKey(resSummary.Order_Product__c)){
                     // System.debug('In Inv Line:'+resSummary.Order_Product__c+'-'+orderProdToOrder.get(resSummary.Order_Product__c).Id);
                     invLine.blng__Invoice__c = resSummary.Order_Product__c == null ? contractToInvoiceMap.get(resSummary.Contract__c+':'+resSummary.OA_Invoice_ID__c).Id : orderToInvoiceMap.get(orderProdToOrder.get(resSummary.Order_Product__c).Id).Id;
                     invLine.blng__Subtotal__c = resSummary.Total__c;
                     invLine.blng__OrderProduct__c = resSummary.Order_Product__c;
                     //Tax details from Order Product's Account
                     invLine.blng__TaxStreet__c = resSummary.Order_Product__c == null ? resSummary.Contract__r.Account.ShippingStreet : orderProdToOrder.get(resSummary.Order_Product__c).Account.ShippingStreet;
                     invLine.blng__TaxCity__c = resSummary.Order_Product__c == null ? resSummary.Contract__r.Account.ShippingCity : orderProdToOrder.get(resSummary.Order_Product__c).Account.ShippingCity;
                     invLine.blng__TaxState__c = resSummary.Order_Product__c == null ? resSummary.Contract__r.Account.ShippingState : orderProdToOrder.get(resSummary.Order_Product__c).Account.ShippingState;
                     invLine.blng__TaxCountry__c = resSummary.Order_Product__c == null ? resSummary.Contract__r.Account.ShippingCountry : orderProdToOrder.get(resSummary.Order_Product__c).Account.ShippingCountry;
                     invLine.blng__TaxZipCode__c = resSummary.Order_Product__c == null ? resSummary.Contract__r.Account.ShippingPostalCode : orderProdToOrder.get(resSummary.Order_Product__c).Account.ShippingPostalCode;
                     invLine.blng__TaxRule__c = orderProdIdToOrderProd.get(resSummary.Order_Product__c).blng__TaxRule__c;
                     invLine.blng__TaxTreatment__c = orderProdIdToOrderProd.get(resSummary.Order_Product__c).blng__TaxTreatment__c;
                     invLine.blng__LegalEntity__c = orderProdIdToOrderProd.get(resSummary.Order_Product__c).blng__LegalEntity__c;
                     invLine.blng__StartDate__c = orderProdIdToOrderProd.get(resSummary.Order_Product__c).ServiceDate;
                     invLine.blng__EndDate__c = orderProdIdToOrderProd.get(resSummary.Order_Product__c).EndDate;
                     invLine.Name = orderProdIdToOrderProd.get(resSummary.Order_Product__c).Product_Name__c;
                     }
                  else if(resSummary.Order_Product__c == null && contractToInvoiceMap != null && contractToInvoiceMap.keySet().size() > 0 
                          && resSummary.Contract__c != null && contractToInvoiceMap.containsKey(resSummary.Contract__c+':'+resSummary.OA_Invoice_ID__c)){
                     // System.debug('In Inv Line:'+resSummary.Order_Product__c+'-'+orderProdToOrder.get(resSummary.Order_Product__c).Id);
                     invLine.blng__Invoice__c = contractToInvoiceMap.get(resSummary.Contract__c+':'+resSummary.OA_Invoice_ID__c).Id;
                     invLine.blng__Subtotal__c = resSummary.Total__c;
                     invLine.blng__OrderProduct__c = resSummary.Order_Product__c;
                     //Tax details from Contract's Account
                     invLine.blng__TaxStreet__c = resSummary.Contract__r.Account ?. ShippingStreet;
                     invLine.blng__TaxCity__c = resSummary.Contract__r.Account?. ShippingCity;
                     invLine.blng__TaxState__c = resSummary.Contract__r.Account?. ShippingState;
                     invLine.blng__TaxCountry__c = resSummary.Contract__r.Account?. ShippingCountry;
                     invLine.blng__TaxZipCode__c = resSummary.Contract__r.Account?. ShippingPostalCode;
                     invLine.blng__TaxRule__c =  prodIdToProdMap != null && prodIdToProdMap.containsKey(resSummary.Product__c) ? prodIdToProdMap.get(resSummary.Product__c).blng__TaxRule__c : null;
                     String legalEntityName = resSummary.Contract__r.Subsidiary__c != null ? (resSummary.Contract__r.Subsidiary__c.split(':'))[0] : null;
                     invLine.blng__TaxTreatment__c = prodToTaxTreatmentMap != null && legalEntityName != null && resSummary.Product__r.SBQQ__TaxCode__c != null && prodToTaxTreatmentMap.containsKey(resSummary.Product__r.SBQQ__TaxCode__c + '-'+legalEntityName) ? prodToTaxTreatmentMap.get(resSummary.Product__r.SBQQ__TaxCode__c + '-'+legalEntityName) : null; 
                     invLine.blng__LegalEntity__c = nameToLegalEntitiesMap != null && legalEntityName != null && nameToLegalEntitiesMap.containsKey(legalEntityName) ? nameToLegalEntitiesMap.get(legalEntityName) : null;
                     invLine.blng__StartDate__c = null;
                     invLine.blng__EndDate__c = null;
                     invLine.Name = prodIdToProdMap != null && prodIdToProdMap.containsKey(resSummary.Product__c)  ? prodIdToProdMap.get(resSummary.Product__c).Name : resSummary.Product__c;
                     }
                  invLine.OA_Slip_Header__c = slipHeadersMap.containsKey(resSummary.OA_Invoice_ID__c) ? (slipHeadersMap.get(resSummary.OA_Invoice_ID__c)).Id : null;
                  invLine.blng__Product__c = resSummary.product__c;
                  invLine.Project__c = resSummary.Project__c;
                  //invLine.Resource__c = resSummary.Resource__c; // No Need for Invoice Lines
                  /* Qty = 1 For Type Fixed, Order Prod is null ;
                     Qty = Invoice Line amount / Order Product Amount. For Type Fixed, Order Prod is not null ;
                     Qty = 1 For Type T&M, Order Prod is null ; 
                     Qty = 1 For Type T&M,//Rollup hours with Minutes, For Type T&M, Order Prod is not null ;                   
                 */
                    if(resSummary.Type__c != null ){
                        if(resSummary.Type__c == SLIP_LINE_TYPE_T_AND_M){ 
                            /*if(resSummary.Order_Product__c == null){invLine.blng__Quantity__c = DEFAULT_QUANTITY_FOR_BILLING;}
                            else { invLine.blng__Quantity__c = resSummary.Hours__c;}*/
                            invLine.blng__Quantity__c = DEFAULT_QUANTITY_FOR_BILLING;
                        }
                        if(resSummary.Type__c == SLIP_LINE_TYPE_F){ 
                            if(resSummary.Order_Product__c == null){invLine.blng__Quantity__c = DEFAULT_QUANTITY_FOR_BILLING;}
                            else { 
                                 if(orderProdIdToOrderProd.containsKey(resSummary.Order_Product__c) && 
                                     orderProdIdToOrderProd.get(resSummary.Order_Product__c).TotalPrice != null && orderProdIdToOrderProd.get(resSummary.Order_Product__c).TotalPrice > 0)
                                     {invLine.blng__Quantity__c = resSummary.Total__c/orderProdIdToOrderProd.get(resSummary.Order_Product__c).TotalPrice;}
                                else invLine.blng__Quantity__c = DEFAULT_QUANTITY_FOR_BILLING;
                             }
                        }
                    }
                  invLine.CreatedFromServiceBillingBatch__c = true;
                  if(! invLinesForCreate.contains(invLine)){invLinesForCreate.add(invLine);}
                  }
        return invLinesForCreate;
    }
   //Get the Tax Treatments
    public static Map<String,String> getTaxTreatMentForProducts(List<Resource_Summary__c> resourceSummaryForInvLinesList){
        Map<String,String> prodTaxToTaxTreatMentMap =  new Map<String,String>();
        Set<String> taxCodesSet = new Set<String>();
        Set<String> legalEntitiesSet = new Set<String>();
        for(Resource_Summary__c resSummary : resourceSummaryForInvLinesList ){
            //if(resSummary.Order_Product__c == null && (resSummary.Contract__c != null ) && (resSummary.Product__c != null && resSummary.Product__r.SBQQ__TaxCode__c != null)){}
            if(resSummary.Contract__r.Subsidiary__c  != null && resSummary.Product__r.SBQQ__TaxCode__c != null){
                String legalEntityName = resSummary.Contract__r.Subsidiary__c.split(':')[0];
                if(! prodTaxToTaxTreatMentMap.containsKey(resSummary.Product__r.SBQQ__TaxCode__c+ '-'+legalEntityName)){
                    prodTaxToTaxTreatMentMap.put(resSummary.Product__r.SBQQ__TaxCode__c + '-'+legalEntityName,'');
                }
                //else {prodTaxToSummariesMap.put(resSummary.Product__r.SBQQ__TaxCode__c + '-'+legalEntityName, new List<Resource_Summary__c> {resSummary});}
               //Get the tax codes
               taxCodesSet.add(resSummary.Product__r.SBQQ__TaxCode__c);
               //Get the Legal Entities
               legalEntitiesSet.add(legalEntityName);
            }
            
        }
        if(legalEntitiesSet.size() > 0 && taxCodesSet.size() > 0){
        List<blng__TaxTreatment__c> taxTreatments = [SELECT Id,blng__TaxCode__c,blng__TaxLegalEntity__r.Name FROM blng__TaxTreatment__c 
                                                     WHERE blng__TaxLegalEntity__r.Name != NULL AND blng__TaxCode__c != NULL
                                                     AND blng__TaxLegalEntity__r.Name in :legalEntitiesSet 
                                                     AND blng__TaxCode__c in :taxCodesSet ];
        if(taxTreatments.size() > 0){
            for(blng__TaxTreatment__c taxTreatment : taxTreatments ){
             if(prodTaxToTaxTreatMentMap.containsKey(taxTreatment.blng__TaxCode__c+ '-'+taxTreatment.blng__TaxLegalEntity__r.Name)){
                    prodTaxToTaxTreatMentMap.put(taxTreatment.blng__TaxCode__c+ '-'+taxTreatment.blng__TaxLegalEntity__r.Name,taxTreatment.Id);
                }
            }
        }
        }
        //Get the Tax Treatments
        return prodTaxToTaxTreatMentMap;
    }
     //Get the Legal Entities
    public static Map<String,String> getLegalEntities(List<Resource_Summary__c> resourceSummaryForInvLinesList){
        Map<String,String> nameToLegalEntityMap =  new Map<String,String>();
        Set<String> legalEntitiesSet = new Set<String>();
        for(Resource_Summary__c resSummary : resourceSummaryForInvLinesList ){
            if(resSummary.Contract__r.Subsidiary__c  != null ){
                String legalEntityName = resSummary.Contract__r.Subsidiary__c.split(':')[0];
                if(! nameToLegalEntityMap.containsKey(legalEntityName)){
                    nameToLegalEntityMap.put(legalEntityName,'');
                }            
            }
        }
        if(nameToLegalEntityMap.size() > 0){
        List<blng__LegalEntity__c > legalEntities = [SELECT Id FROM blng__LegalEntity__c  
                                                     WHERE Name != NULL
                                                     AND Name in :nameToLegalEntityMap.keySet() ];
        //Map the Legal Entity with Name
        if(legalEntities.size() > 0){
            for(blng__LegalEntity__c  legalEntity : legalEntities ){
             if(nameToLegalEntityMap.containsKey(legalEntity.Name)){
                    nameToLegalEntityMap.put(legalEntity.Name,legalEntity.Id);
                }
            }
        }
        }
        //return the Legal Entities
        return nameToLegalEntityMap;
    }
 //Create Invoices
    public static blng__Invoice__c createBillingInvoice(Resource_Summary__c summary,Map<String,Contract> contractToAccountMap,Map<String,Order> orderProdToOrder, Map<String,OA_Slip_Header__c> slipHeadersMap){
       blng__Invoice__c invoice = new blng__Invoice__c();
       //Legacy Slip Line, get the Billing Account from Contract
       invoice.blng__Account__c = summary.Order_Product__c == null ? contractToAccountMap.get(summary.Contract__c).AccountId : (orderProdToOrder != null && orderProdToOrder.containsKey(summary.Order_Product__c) ? orderProdToOrder.get(summary.Order_Product__c).AccountId : null);//Order_Product__r.Order.AccountId;
       invoice.blng__Order__c = summary.Order_Product__c == null ? null : (orderProdToOrder != null && orderProdToOrder.containsKey(summary.Order_Product__c) ? orderProdToOrder.get(summary.Order_Product__c).Id : null);//summary.Order_Product__r.OrderId;
       invoice.SFDC_Services_Project__c = summary.Project__c;
       invoice.Invoice_Type__c = INVOICE_TYPE_T_AND_M;
       invoice.Contract__c = summary.Contract__c;
       if(slipHeadersMap.containsKey(summary.OA_Invoice_ID__c))//From Slip Header
       invoice.blng__InvoiceDate__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).Invoice_Date__c;
       //Invoice Due date = Invoice Date + Order's Payment Term
       //Legacy Lines: Payment Term default value : 30 when Order Prod is null and Contrcat's Payment Term is null
       try{
           if( slipHeadersMap.get(summary.OA_Invoice_ID__c).Invoice_Date__c != null ){
                Integer orderPaymentTerm  = summary.Order_Product__c == null ? (summary.Contract__c != null && summary.Contract__r.Software_Payment_Terms__c == null ? NET_30 : ((summary.Contract__r.Software_Payment_Terms__c).contains('Net ') ?  
                Integer.valueOf((summary.Contract__r.Software_Payment_Terms__c).split('Net ')[1]) : 0)) : 
                (orderProdToOrder != null && orderProdToOrder.containsKey(summary.Order_Product__c) && orderProdToOrder.get(summary.Order_Product__c).Payment_Term_Software__c != null && (orderProdToOrder.get(summary.Order_Product__c).Payment_Term_Software__c).contains('Net ') ?  
                Integer.valueOf((orderProdToOrder.get(summary.Order_Product__c).Payment_Term_Software__c).split('Net ')[1]) : 0);
                invoice.blng__DueDate__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).Invoice_Date__c + orderPaymentTerm;
            }
       }
       catch(Exception ex){ System.debug('ServiceBillingBatch Invoice Creation Error:'+ ex.getMessage() );}
       invoice.OA_Invoice_ID__c = summary.OA_Invoice_ID__c;
       if(slipHeadersMap.containsKey(summary.OA_Invoice_ID__c))//From Slip Header
       invoice.OA_Slip_Header__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).Id;
       invoice.OA_Invoice_Name__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).OA_Invoice_Name__c;
       if(slipHeadersMap.containsKey(summary.OA_Invoice_ID__c))//From Slip Header
       invoice.OA_Invoice_Subtotal__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).OA_Invoice_Subtotal__c;
       if(slipHeadersMap.containsKey(summary.OA_Invoice_ID__c))//From Slip Header
       invoice.OA_Invoice_Subtotal_Currency__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).OA_Invoice_Subtotal_Currency__c;
       invoice.CreatedFromServiceBillingBatch__c = true;    
       return invoice;
    }
     //Get the Product for Product Ids
    public static Map<String,Product2> getProdIdsToProducts(List<Resource_Summary__c> resourceSummaryForInvLinesList){
        Set<String> prodIds = new Set<String>();
        Map<String,Product2> prodIdToProuctMap = new Map<String,Product2>();
        //Get the Order Prod Ids
        for(Resource_Summary__c resSummary : resourceSummaryForInvLinesList)
        {if(resSummary.Product__c != null){prodIds.add(resSummary.Product__c);}}
         List<Product2> products = [SELECT Id,Name,blng__TaxRule__c
                                    FROM Product2
                                    WHERE Id in :prodIds];
        prodIdToProuctMap = new Map<String,Product2>(products);
        return prodIdToProuctMap;
    }
          
    //Get the Order Item for the Order Item Ids
 /**
 * @description: Helper - Get OrderProd For OrderProdIds
 * @param: Inserted Res Summary,Slip Headers Map
 * @return: Map of OrderProdId to OrderId , as we can't get data from Order Product, need to query
 */
    public static Map<String,OrderItem> getOrderProdForOrderProdIds(List<Resource_Summary__c> resourceSummaryForInvLinesList) {
        Set<String> ordProdIds = new Set<String>();
        Map<String,String> ordProdToOrderIdMap = new Map<String,String>();
        //Get the Order Prod Ids
        for(Resource_Summary__c resSummary : resourceSummaryForInvLinesList)
        {if(resSummary.Order_Product__c != null){ordProdIds.add(resSummary.Order_Product__c);}}
         List<OrderItem> orderProds = [SELECT Id,OrderId,blng__TaxRule__c,blng__TaxTreatment__c,blng__LegalEntity__c,ServiceDate,EndDate,TotalPrice,
                                       Product_Name__c FROM OrderItem
                                       WHERE Id in :ordProdIds];
        Map<String,OrderItem> ordProdIdToOrderProdMap = new Map<String,OrderItem>(orderProds);
        return ordProdIdToOrderProdMap;
    }
    //Get the Order Details for Order Product
/**
 * @description: Helper - Get Account for Contract
 * @param:  Res Summary
 * @return: Map of Contract To Account
 */
    public static Map<String,Contract> getContractIdToContractForAccount(List<Resource_Summary__c> resourceSummaryForInvLinesList) {
        Set<String> contractIds = new Set<String>();
        Map<String,Contract> contractIdToContractMap = new Map<String,Contract>();
        //Get the Order Prod Ids
        for(Resource_Summary__c resSummary : resourceSummaryForInvLinesList)
        {if(resSummary.Order_Product__c == null && resSummary.Contract__c != null){contractIds.add(resSummary.Contract__c);}}
        if(contractIds.size() > 0){
         List<Contract> contracts = [SELECT Id,AccountId,Account.ShippingStreet,Account.ShippingCity,Account.ShippingCountry,Account.ShippingState,
                                     Account.ShippingPostalCode
                                     FROM Contract
                                     WHERE Id in :contractIds];
         if(contracts.size() >0){
            for(Contract cont : contracts){
                if(! contractIdToContractMap.containsKey(cont.Id)){
                    contractIdToContractMap.put(cont.Id,cont);
                }
            }
        }
        }
        return contractIdToContractMap;
    }
    //Get the Order Details for Order Product
/**
 * @description: Helper - Get Order For OrderProd
 * @param: Inserted Res Summary
 * @return: Map of OrderProdId to Order
 */
    public static Map<String,Order> getOrderForOrderProd(List<Resource_Summary__c> resourceSummaryForInvLinesList) {
        Set<String> ordProdIds = new Set<String>();
        Map<String,String> ordProdToOrderIdMap = new Map<String,String>();
        Map<String,Order> ordProdToOrderMap = new Map<String,Order>();
        //Get the Order Prod Ids
        for(Resource_Summary__c resSummary : resourceSummaryForInvLinesList)
        {if(resSummary.Order_Product__c != null){ordProdIds.add(resSummary.Order_Product__c);}}
         List<OrderItem> orderProds = [SELECT Id,OrderId FROM OrderItem
                                       WHERE Id in :ordProdIds];
         if(orderProds.size() >0){
            for(OrderItem ordItem : orderProds){
                if(! ordProdToOrderIdMap.containsKey(ordItem.Id)){
                    ordProdToOrderIdMap.put(ordItem.Id,ordItem.OrderId);
                }
            }
        }
        if(ordProdToOrderIdMap.keySet().size() > 0){
            //Get the Orders
            List<Order> orders = [SELECT Id,AccountId,Account.ShippingCity,Account.ShippingStreet,Account.ShippingState,
                                       Account.ShippingCountry,Account.ShippingPostalCode,Payment_Term_Software__c FROM Order WHERE Id in :ordProdToOrderIdMap.values()];
            if(orders.size() >0){
            Map<String,Order> orderMap = new Map<String,Order>(orders);
                for(String ordProdId : ordProdToOrderIdMap.keySet()){
                    if(orderMap.containsKey(ordProdToOrderIdMap.get(ordProdId))){
                        if(! ordProdToOrderMap.containsKey(ordProdId)){
                            ordProdToOrderMap.put(ordProdId,orderMap.get(ordProdToOrderIdMap.get(ordProdId)));
                        }
                    } 
                }
            }
        }
        return ordProdToOrderMap;
    }
    //Get Aggregated values for Invoices
/**
 * @description: Helper - Get Aggregated Values For Invoices
 * @param: Inserted Res Summary
 * @return: Map of OA Invoice Id Res Summaries
 */
    public static Map<String,List<Resource_Summary__c>> getAggregatedValuesForInvoices(List<Resource_Summary__c> resourceSummaryForInvLinesList){
        Map<String,List<Resource_Summary__c>> invToResourcesMap = new Map<String,List<Resource_Summary__c>>();
        for(Resource_Summary__c resSummary : resourceSummaryForInvLinesList)
        {
           if(invToResourcesMap.containsKey(resSummary.OA_Invoice_ID__c +':'+resSummary.Contract__c+':'+resSummary.Order_Product__c+'-'+resSummary.Type__c)){// resSummary.Type__c)){
                invToResourcesMap.get(resSummary.OA_Invoice_ID__c+':'+resSummary.Contract__c +':'+resSummary.Order_Product__c+'-'+resSummary.Type__c).add(resSummary);
            }
            else {invToResourcesMap.put(resSummary.OA_Invoice_ID__c+':'+resSummary.Contract__c +':'+resSummary.Order_Product__c+'-'+resSummary.Type__c,new List<Resource_Summary__c>{resSummary});}
        }
        return invToResourcesMap;
    }
    //Get aggregated values for Invoice Lines
 /**
 * @description: Helper - Get Aggregated Values For Invoices Lines
 * @param: Inserted Res Summary
 * @return: List of Res Summaries
 */
    public static List<Resource_Summary__c> getAggregatedValuesForInvLines(List<Resource_Summary__c> resSummaries){
       List<Resource_Summary__c> resourceSummaryForInvLinesList = new List<Resource_Summary__c>();
       Map<String,List<Resource_Summary__c>> pjtToResSummaryMap = new Map<String,List<Resource_Summary__c>>();
       for(Resource_Summary__c summary : resSummaries)
       {
           if(pjtToResSummaryMap.containsKey(summary.Project__c))
           {pjtToResSummaryMap.get(summary.Project__c).add(summary);}
           else
           {
               pjtToResSummaryMap.put(summary.Project__c,new List<Resource_Summary__c>{summary});
           }
       }
       Map<String,List<Resource_Summary__c>> invToResSummaryMap = new Map<String,List<Resource_Summary__c>>();
       if(pjtToResSummaryMap.keySet().Size()>0){
       for(String pjt : pjtToResSummaryMap.keySet())
       {
           List<Resource_Summary__c> summaryForInv =  pjtToResSummaryMap.get(pjt);
           if(summaryForInv != null){
               for(Resource_Summary__c inv :summaryForInv)
               {    if(invToResSummaryMap.containsKey(inv.Project__c+'-'+inv.OA_Invoice_ID__c))
                    {invToResSummaryMap.get(inv.Project__c+'-'+inv.OA_Invoice_ID__c).add(inv);}
                    else
                    {invToResSummaryMap.put(inv.Project__c+'-'+inv.OA_Invoice_ID__c,new List<Resource_Summary__c>{inv});}
               }
           }
       }
       }
       //Order Prod
      Map<String,List<Resource_Summary__c>> orderProdToResSummaryMap = new Map<String,List<Resource_Summary__c>>();
      if(invToResSummaryMap.keySet().Size()>0){
      for(String pjt : invToResSummaryMap.keySet())
       {
           List<Resource_Summary__c> summaryForInv =  invToResSummaryMap.get(pjt);
           if(summaryForInv != null){
               for(Resource_Summary__c ordProd :summaryForInv)
               {    if(orderProdToResSummaryMap.containsKey(ordProd.Contract__c+'-'+ordProd.Order_Product__c))
                    {orderProdToResSummaryMap.get(ordProd.Contract__c+'-'+ordProd.Order_Product__c).add(ordProd);}
                    else
                    {orderProdToResSummaryMap.put(ordProd.Contract__c+'-'+ordProd.Order_Product__c,new List<Resource_Summary__c>{ordProd});}
               }
           }
       }
       }
       //Resource
      Map<String,List<Resource_Summary__c>> resourceToResSummaryMap = new Map<String,List<Resource_Summary__c>>();
       if(orderProdToResSummaryMap.keySet().Size()>0){
       for(String pjt : orderProdToResSummaryMap.keySet())
       {
           List<Resource_Summary__c> summaryForResource =  orderProdToResSummaryMap.get(pjt);
           if(summaryForResource != null){
               for(Resource_Summary__c ordProd :summaryForResource)
               {    if(ordProd.Resource__c != null){
                    if(resourceToResSummaryMap.containsKey(ordProd.Resource__c))
                    {resourceToResSummaryMap.get(ordProd.Resource__c).add(ordProd);}
                    else
                    {resourceToResSummaryMap.put(ordProd.Resource__c,new List<Resource_Summary__c>{ordProd});}
               }
               }
           }
       }
       }
       //Get the Aggregated values
       for(String pjt : pjtToResSummaryMap.keySet())
       {
           List<Resource_Summary__c> summaryForPjt = pjtToResSummaryMap.get(pjt);
           if(summaryForPjt != null)
           {
               for(Resource_Summary__c forPjt : summaryForPjt){
               if(invToResSummaryMap.containsKey(pjt+'-'+forPjt.OA_Invoice_ID__c) && forPjt.Project__c == pjt){
                   List<Resource_Summary__c> summaryForInv = invToResSummaryMap.get(pjt+'-'+forPjt.OA_Invoice_ID__c);
                   if(summaryForInv != null){
                       for(Resource_Summary__c summaryFororderProd : summaryForInv)
                       {
                           Decimal hours = 0;
                           Decimal amount = 0;
                                   
                           if(orderProdToResSummaryMap.containsKey(summaryFororderProd.Contract__c+'-'+summaryFororderProd.Order_Product__c) && summaryFororderProd.OA_Invoice_ID__c == forPjt.OA_Invoice_ID__c
                             && summaryFororderProd.Project__c == pjt)
                           {
                               List<Resource_Summary__c> summaryforResource = orderProdToResSummaryMap.get(summaryFororderProd.Contract__c+'-'+summaryFororderProd.Order_Product__c);
                               if(summaryforResource != null)
                               {
                                   for(Resource_Summary__c resource : summaryforResource){
                                   if(resource.Resource__c != null && resource.Type__c == SLIP_LINE_TYPE_T_AND_M && resourceToResSummaryMap.containsKey(resource.Resource__c) 
                                   && resource.OA_Invoice_ID__c == forPjt.OA_Invoice_ID__c
                                   //&& resource.Project__c == pjt && resource.Order_Product__c == summaryFororderProd.Order_Product__c)
                                   && resource.Project__c == pjt && resource.Contract__c == summaryFororderProd.Contract__c && 
                                      resource.Order_Product__c == summaryFororderProd.Order_Product__c)
                                   {
                                       hours = hours + resource.Hours__c;
                                       amount = amount + resource.Total__c;
                                   }
                                   else if (resource.Type__c == SLIP_LINE_TYPE_F && resource.OA_Invoice_ID__c == forPjt.OA_Invoice_ID__c // resource.Resource__c == null 
                                   && resource.Project__c == pjt && resource.Contract__c == summaryFororderProd.Contract__c && 
                                      resource.Order_Product__c == summaryFororderProd.Order_Product__c)
                                   {
                                      // if(resource.Type__c == SLIP_LINE_TYPE_F){
                                           //Generate Resource Summary for each records - Aggregated the amount earlier at Per Project function.
                                           //Create Resource Summary with Aggregated values for Invoice Lines and Invoice Creation
                                        Resource_Summary__c resSummary = new Resource_Summary__c();
                                        resSummary.Project__c = resource.Project__c;
                                        resSummary.OA_Invoice_ID__c = resource.OA_Invoice_ID__c;
                                        resSummary.Product__c = resource.Product__c;
                                        resSummary.Order_Product__c = resource.Order_Product__c;
                                        resSummary.Type__c = resource.Type__c;
                                        //resSummary.Hours__c = ;
                                        resSummary.Total__c = resource.Total__c;
                                        resSummary.Contract__c = resource.Contract__c;
                                        if( ! resourceSummaryForInvLinesList.contains(resSummary))
                                          {resourceSummaryForInvLinesList.add(resSummary);}
                                       //}
                                       //amount = amount + resource.Total__c;
                                   }
                                   }
                               }
                           }
                           if(summaryFororderProd.Type__c == SLIP_LINE_TYPE_T_AND_M){
                           //Create Resource Summary with Aggregated values for Invoice Lines and Invoice Creation
                            Resource_Summary__c resSummary = new Resource_Summary__c();
                                 resSummary.Project__c = summaryFororderProd.Project__c;
                                 resSummary.OA_Invoice_ID__c = summaryFororderProd.OA_Invoice_ID__c;
                                 resSummary.Product__c = summaryFororderProd.Product__c;
                                 resSummary.Order_Product__c = summaryFororderProd.Order_Product__c;
                                 resSummary.Type__c = summaryFororderProd.Type__c;
                                 resSummary.Hours__c =  hours;
                                 resSummary.Total__c = amount;
                                 resSummary.Contract__c = summaryFororderProd.Contract__c;
                                 if( ! resourceSummaryForInvLinesList.contains(resSummary))
                                 {resourceSummaryForInvLinesList.add(resSummary);}
                           }
                       }
                   }
               }
           }
           }
       }
       return resourceSummaryForInvLinesList;
   }
    //Get the aggregated values for Project
 /**
 * @description: Helper - Get Aggregated Values For Projects
 * @param: Project,Slip Records for Project,Invocies,Order Product,Resources
 * @return: List of Res Summaries
 */
    public static List<Resource_Summary__c> getAggregatedValuesForProject(String project, List<OA_Slip__c> pjtToOASlipList, Map<String, List<OA_Slip__c>> invoiceToOASlipMap, Map<String, List<OA_Slip__c>> productToOASlipMap) {
    List<Resource_Summary__c> resourceSummaryList = new List<Resource_Summary__c>();
    for (OA_Slip__c pjt : pjtToOASlipList) {
        if (invoiceToOASlipMap.containsKey(pjt.Project__c+'-'+pjt.OA_Invoice_ID__c) && pjt.Project__c == project) {
            List<OA_Slip__c> invToOASlipList = invoiceToOASlipMap.get(pjt.Project__c+'-'+pjt.OA_Invoice_ID__c);
            
            for (OA_Slip__c inv : invToOASlipList) {
                if (productToOASlipMap.containsKey(inv.Contract__c+'-'+inv.Order_Product__c + '-'+ inv.OA_Invoice_ID__c) && inv.Project__c == project ){//&& inv.Invoice__c == pjt.Invoice__c) {
                   List<OA_Slip__c> products = productToOASlipMap.get(inv.Contract__c+'-'+inv.Order_Product__c + '-'+inv.OA_Invoice_ID__c);
                    // System.debug('At Res Summ Logic orderProdToFixedSlipMap products:'+inv.Order_Product__c + '-'+inv.OA_Invoice_ID__c);
                    //For Fixed Type records get the aggregated records based on the Time Narrtive (Description)
                    Map<String,List<OA_Slip__c>> orderProdToFixedSlipMap = getFixedSlips(products,project ,inv.OA_Invoice_ID__c);
                    //System.debug('At Res Summ Logic orderProdToFixedSlipMap:'+orderProdToFixedSlipMap.keySet().size());
                    Map<String,Decimal> orderToFixedAggregatedAmt = new Map<String,Decimal>();
                    if(orderProdToFixedSlipMap.keySet().size() > 0){
                        for(String orderProdWithTimeNarrative : orderProdToFixedSlipMap.keySet()){
                            List<OA_Slip__c> slips = orderProdToFixedSlipMap.get(orderProdWithTimeNarrative);
                            Decimal amountForFixed = 0;
                            for(OA_Slip__c slipF : slips){
                                amountForFixed = amountForFixed + slipF.Total__c;
                            }
                            //System.debug('At Res Summ Logic orderProdWithTimeNarrative:'+orderProdWithTimeNarrative);
                            if(orderToFixedAggregatedAmt.containsKey(orderProdWithTimeNarrative)){
                                Decimal temp = orderToFixedAggregatedAmt.get(orderProdWithTimeNarrative) != null ?  orderToFixedAggregatedAmt.get(orderProdWithTimeNarrative) : 0;
                                orderToFixedAggregatedAmt.put(orderProdWithTimeNarrative,temp + amountForFixed);
                            }
                            else {orderToFixedAggregatedAmt.put(orderProdWithTimeNarrative,amountForFixed);}
                        }
                         //System.debug('orderToFixedAggregatedAmt:'+orderToFixedAggregatedAmt.keySet());
                         //System.debug('orderToFixedAggregatedAmt:'+orderToFixedAggregatedAmt);
                        //Create Resource Summary for each F type with and without Description 
                        if(orderToFixedAggregatedAmt != null){
                            for(String ordProdWithTypeNarrativeKey : orderToFixedAggregatedAmt.keySet()){
                                Resource_Summary__c resSummary = new Resource_Summary__c();
                                resSummary.Project__c = project;
                                resSummary.OA_Invoice_ID__c = inv.OA_Invoice_ID__c;
                                resSummary.Product__c = inv.Product__c;
                                resSummary.Order_Product__c = inv.Order_Product__c;
                                resSummary.Type__c = SLIP_LINE_TYPE_F;
                                resSummary.Contract__c = inv.Contract__c;
                                //inv.Order_Product__c + '-' + F_TYPE_NARRATIVE_YES)) or F_TYPE_NARRATIVE_NO
                                resSummary.Total__c = orderToFixedAggregatedAmt.get(ordProdWithTypeNarrativeKey);//amount;
                                if (!resourceSummaryList.contains(resSummary)) {
                                resourceSummaryList.add(resSummary);
                                }
                            }
                        }
                        
                        //System.debug('At Res Summ Logic:'+resourceSummaryList.size());
                        }
                    Map<String,List<OA_Slip__c>> orderProdToResourcesMap = getResources(products,project ,inv.OA_Invoice_ID__c);
                    //Aggregate and Insert the T Type Records.
                    //for (OA_Slip__c product : products) {
                        //Collect all the resources for the Product,Invoice,Project for Type T
                        //Map<String,List<OA_Slip__c>> orderProdToResourcesMap = getResources(products,project ,inv.OA_Invoice_ID__c);
                        Map<String,String> resMap = new Map<String,String>();
                        if(orderProdToResourcesMap.size() > 0 && inv.Type__c == SLIP_LINE_TYPE_T_AND_M){
                        for(String orderProdRes : orderProdToResourcesMap.keySet()){
                            List<OA_Slip__c> resources = orderProdToResourcesMap.get(orderProdRes);
                            Decimal hours = 0;
                            Decimal amount = 0;
                            Decimal minutes = 0;
                            //Map<String,String> resMap = new Map<String,String>();
                            for (OA_Slip__c resource : resources) {
                                Decimal resMinute = resource.Minute__c == null ? 0.0 : resource.Minute__c;
                                /*Integer modValue = resMinute > 59 ? System.Math.Mod(Integer.valueOf(resMinute),60) : Integer.valueOf(resMinute);
                                Integer hoursFromMinutes = resMinute > 59 ? Integer.valueOf(resMinute)/60 : 0;
                                hours = hours + resource.Hour__c + hoursFromMinutes;*/
                                hours = hours + resource.Hour__c;
                                amount += resource.Total__c;
                                minutes = minutes + resMinute;
                                //resMap.put(orderProdRes,String.valueOf(hours)+'='+String.valueOf(amount)+'-'+resource.Rate__c);
                                //Hours : Minutes = Amount - Rate
                                resMap.put(orderProdRes,String.valueOf(hours)+':'+String.valueOf(minutes)+'='+String.valueOf(amount)+'-'+resource.Rate__c);
                                /*if(resMap.containsKey(resource.Resource__c+'-'+resource.Job_Code_Resource_Role__c) ){
                                    String hrsAmount = resMap.get(resource.Resource__c+'-'+resource.Job_Code_Resource_Role__c);
                                    Decimal existingHours = Decimal.valueOf(hrsAmount.split('=')[0]);
                                    Decimal existingAmount = Decimal.valueOf(hrsAmount.split('=')[1]);
                                    String rollupHrsAmt = String.valueOf(existingHours+hours)+'='+ String.valueOf(existingAmount+amount);
                                    resMap.put(resource.Resource__c+'-'+resource.Job_Code_Resource_Role__c,rollupHrsAmt);
                                    //String.valueOf(hours)+'='+String.valueOf(amount));}
                                }
                                else{
                                    resMap.put(resource.Resource__c+'-'+resource.Job_Code_Resource_Role__c,String.valueOf(resource.Hour__c)+'='+String.valueOf(resource.Total__c));}*/
                            }
                            for(String res : resMap.keySet()){
                            Resource_Summary__c resSummary = new Resource_Summary__c();
                            resSummary.Project__c = project;
                            resSummary.OA_Invoice_ID__c = inv.OA_Invoice_ID__c;
                            resSummary.Product__c = inv.Product__c;//product.Product__c;
                            resSummary.Order_Product__c = inv.Order_Product__c;//product.Order_Product__c;
                            resSummary.Type__c = inv.Type__c;// product.Type__c;
                            resSummary.Contract__c = inv.Contract__c;
                            resSummary.Resource__c = res;
                            //Hours : Minutes = Amount - Rate
                            resSummary.Rate__c = Decimal.ValueOf(resMap.get(res).split('-')[1]);//product.Rate__c;
                            //Hours : Minutes = Amount - Rate
                            String hrsMins = resMap.get(res).split('=')[0];
                            Decimal hrsFromStrHrsMins = Decimal.valueOf(hrsMins.split(':')[0]);
                            Integer minsFromStrHrsMins = Integer.valueOf(hrsMins.split(':')[1]);
                            Integer minutesAfterHours = minsFromStrHrsMins > 59 ? System.Math.Mod(minsFromStrHrsMins,60) : minsFromStrHrsMins;
                            Integer hoursFromMinutes = minsFromStrHrsMins > 59 ? minsFromStrHrsMins/60 : 0;
                            Decimal finalHrs = hrsFromStrHrsMins + hoursFromMinutes + (Decimal.valueOf(minutesAfterHours)/100);
                            resSummary.Hours__c = finalHrs;//Decimal.ValueOf(resMap.get(res).split('=')[0]);//hours;
                            resSummary.Total__c = Decimal.ValueOf((resMap.get(res).split('=')[1]).split('-')[0]);//amount;
                            if (!resourceSummaryList.contains(resSummary)) {
                                resourceSummaryList.add(resSummary);
                            }
                        }
                        }
                    }
                        
                    
                    //}
                }
            }
        }
    }
         //System.('At Res Summ Logic OUT:'+resourceSummaryList.size());
    return resourceSummaryList;
}
    //Get Aggregated values for resources.
 /**
 * @description: Helper - Get Resources
 * @param: Order Products to Slips,Inv+Project, Invoice
 * @return: Map of resource to Res Summaries
 */
    public static Map<String,List<OA_Slip__c>> getResources(List<OA_Slip__c> products,String invProject , String invInvoice){
    Map<String,List<OA_Slip__c>> resourceMap = new Map<String,List<OA_Slip__c>>();
    for(OA_Slip__c prod : products)
    {
        if(prod.OA_Invoice_ID__c == invInvoice && prod.Project__c == invProject && prod.Resource__c != null
           && prod.Job_Code_Resource_Role__c != null
           && prod.Type__c == SLIP_LINE_TYPE_T_AND_M){
            if(resourceMap.containsKey(prod.Resource__c +'-'+prod.Job_Code_Resource_Role__c)){
            resourceMap.get(prod.Resource__c +'-'+prod.Job_Code_Resource_Role__c).add(prod);}
            else {
                resourceMap.put(prod.Resource__c +'-'+prod.Job_Code_Resource_Role__c,new List<OA_Slip__c>{prod});
            }
        }
    }
    return resourceMap;
    }
    public static Map<String,List<OA_Slip__c>> getFixedSlips(List<OA_Slip__c> products,String invProject , String invInvoice){
    //System.debug('In getFixedSlips');
    Map<String,List<OA_Slip__c>> typeFixedMap = new Map<String,List<OA_Slip__c>>();
    for(OA_Slip__c prod : products)
    {
        //System.debug('In getFixedSlips');
        if(prod.OA_Invoice_ID__c == invInvoice && prod.Project__c == invProject && prod.Resource__c == null & prod.Type__c == SLIP_LINE_TYPE_F){
           //Get the Null Description with F_TYPE_NARRATIVE_KEY_NO
            if(prod.Time_Entry_Narrative__c == null){
                if(typeFixedMap.containsKey(prod.Contract__c+'-'+prod.Order_Product__c + '-' + F_TYPE_NARRATIVE_NO)){
                    typeFixedMap.get(prod.Contract__c+'-'+prod.Order_Product__c + '-' + F_TYPE_NARRATIVE_NO).add(prod);
                }
                else{
                    typeFixedMap.put(prod.Contract__c+'-'+prod.Order_Product__c + '-' + F_TYPE_NARRATIVE_NO,new List<OA_Slip__c> {prod});
                }
            }
            else{
                if(typeFixedMap.containsKey(prod.Contract__c+'-'+prod.Order_Product__c + '-' + F_TYPE_NARRATIVE_YES)){
                    typeFixedMap.get(prod.Contract__c+'-'+prod.Order_Product__c + '-' + F_TYPE_NARRATIVE_YES).add(prod);
                }
                else{
                    typeFixedMap.put(prod.Contract__c+'-'+prod.Order_Product__c + '-' + F_TYPE_NARRATIVE_YES,new List<OA_Slip__c> {prod});
                }
            }
        }
    }
    //System.debug('typeFixedMap:'+typeFixedMap.size());
    return typeFixedMap;
    }
 /**
 * @description: Helper - Batch Finish
 * @param: Batch Context
 */
    public void finish(Database.BatchableContext bc) {
        //Update the OA Header and Slip Lines for the Processed Flag 
        //If Line amounts are matched with OA Header Amount
        //Update Processed flag Header
        //Get the Invoices based on the OA Invoice Ids
       //Get the Invoice Amount to validate ot with OA Header map
       Map<String,Decimal> oaInvoiceIdToBillingInvAmount = new Map<String,Decimal>();
       Map<String,List<blng__Invoice__c>> oaInvoiceToBillingMap = new Map<String,List<blng__Invoice__c>>();
       List<blng__Invoice__c> invoices = [SELECT Id,OA_Invoice_Id__c,blng__TotalAmount__c,CreatedFromServiceBillingBatch__c,OA_Slip_Header__c
                                           FROM blng__Invoice__c
                                           WHERE OA_Invoice_Id__c in :slipHeadersMap.keySet()
                                           AND OA_Invoice_Id__c != NULL
                                           AND CreatedFromServiceBillingBatch__c = TRUE 
                                           AND blng__TotalAmount__c != NULL];
        if(invoices.size() > 0){
        //Step 1: Get the OA Invoice Amount from Billing Invoices
        for(blng__Invoice__c inv : invoices){
           // if(oaInvoiceToBillingMap.containsKey(inv.OA_Invoice_ID__c)){
                if(oaInvoiceIdToBillingInvAmount.containsKey(inv.OA_Invoice_ID__c)){
                   oaInvoiceIdToBillingInvAmount.put(inv.OA_Invoice_ID__c,(oaInvoiceIdToBillingInvAmount.get(inv.OA_Invoice_ID__c) + inv.blng__TotalAmount__c));
                }
                else {oaInvoiceIdToBillingInvAmount.put(inv.OA_Invoice_ID__c,inv.blng__TotalAmount__c);}
         }
        //Step 2: Compare the OA Invoice Amount from OA Header
        //Step 3: If same , mark the OA Header record as Processed.
         List<OA_Slip_Header__c> headerToUpdateProcessedList = new List<OA_Slip_Header__c>();
           for(String oaInvId : slipHeadersMap.keySet()){
               if(oaInvoiceIdToBillingInvAmount.containsKey(oaInvId)){
                   if(slipHeadersMap.get(oaInvId).OA_Invoice_Subtotal__c != null &&
                      slipHeadersMap.get(oaInvId).OA_Invoice_Subtotal__c == oaInvoiceIdToBillingInvAmount.get(oaInvId)){
                       OA_Slip_Header__c header = slipHeadersMap.get(oaInvId);
                       header.Processed__c = true;
                       header.Process_Status__c = ERR_STATUS_SUCCESS;
                       header.Processed_On__c = System.DateTime.Now();
                       headerToUpdateProcessedList.add(header);
                   }
               }
            }
         //Update Header
            if(headerToUpdateProcessedList.size() >0 ){
                Database.update(headerToUpdateProcessedList);
            }
        }
        
        //Send Email Alert for any error messages.
        String subject = 'Service Billing Process Batch Result';
        String body = 'Dear '+ UserInfo.getName() + ',\n Please refer the excel sheet for the errors occured in the Service Billing Process Scheduled process.\n'
                      +'This process will Create Invoice and Invoice Lines based on the OA Slip Headers and Lines.\n\nThank you.';
            // Define the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            // Define email file attachment list
            List<Messaging.EmailFileAttachment> emailAttList = new List<Messaging.EmailFileAttachment>();
            //Resource Summary 
            if(! errorMessagesMap.isEmpty()){
            // Creating the CSV file for error
            String finalstr = 'Erro Id,Message\n';
            String attName = 'ServiceBillingProcessBatch_ResourceSummaryErrors_' + System.now().format('YYYYMMDDhhmm') + '.csv';
            for(String errId  : errorMessagesMap.keySet()){
                String recordString = '"'+ errId +'","'+errorMessagesMap.get(errId)+'"\n';
                finalstr = finalstr +recordString;
            }
            // Create the email attachment    
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(attName);
            efa.setBody(Blob.valueOf(finalstr));
            emailAttList.add(efa);
           }
            //Invoices
            if(! invErrorMessagesMap.isEmpty()){
            // Creating the CSV file for error
            String finalstr = 'Erro Id,Message\n';
            String attName = 'ServiceBillingProcessBatch_InvoiceErrors_' + System.now().format('YYYYMMDDhhmm') + '.csv';
            for(String errId  : invErrorMessagesMap.keySet()){
                String recordString = '"'+errId+'","'+invErrorMessagesMap.get(errId)+'"\n';
                finalstr = finalstr +recordString;
            }
            // Create the email attachment    
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(attName);
            efa.setBody(Blob.valueOf(finalstr));
            emailAttList.add(efa);
           }
            //Invoices
            if(! invLineErrorMessagesMap.isEmpty()){
            // Creating the CSV file for error
            String finalstr = 'Erro Id,Message\n';
            String attName = 'ServiceBillingProcessBatch_Invoice_Line_Errors_' + System.now().format('YYYYMMDDhhmm') + '.csv';
            for(String errId  : invLineErrorMessagesMap.keySet()){
                String recordString = '"'+errId+'","'+invLineErrorMessagesMap.get(errId)+'"\n';
                finalstr = finalstr +recordString;
            }
            // Create the email attachment    
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(attName);
            efa.setBody(Blob.valueOf(finalstr));
            emailAttList.add(efa);
           }
            // Sets the paramaters of the email
            List<String> toAddresses = new List<String>{UserInfo.getUserEmail()};
            email.setSubject( subject );
            email.setToAddresses( toAddresses);//{UserInfo.getUserEmail()} );
            email.setPlainTextBody( body );
            email.setFileAttachments(emailAttList);
            if(emailAttList.size() > 0)
            // Sends the email
            {Messaging.SendEmailResult [] result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
             }
    }
 /** 
  * @description : Schedule the Batch
  * @param: Schedulable context
  */
 public void execute(SchedulableContext sc) {
      ServiceBillingProcessBatch batch = new ServiceBillingProcessBatch();
      Database.executeBatch(batch, 100);
    }
}