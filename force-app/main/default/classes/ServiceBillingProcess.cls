/***** Name :ServiceBillingProcess 
 ***** Created By : KPMG - Seena
 ***** Created On : Oct 09th, 2023
 ***** Description : From Slip Header, Create the Invoices
					 From the OA Slip records generate Resource Summaries at Resource level aggregation , 
					 Then aggregate the Resource Summaries at Order Product Level and  Create Invoice lines
                     After insert update the Slip Header Records, Slip Records are procesed.
 *****             : This file is just for Demo Purpose, Main file name is: ServiceBillingProcessBatch
******/
//Create Invoice lines based on the OA Slip records
public with sharing class ServiceBillingProcess {
    //Get the Records from OA Slip records Processed flag = False
    @AuraEnabled(cacheable=false)
	public static Boolean createInvoiceLinesFromOASlipRecords()
    {
     //Get the Header
     try{
          List<OA_Slip_Header__c> oaSlipHeaders = new List<OA_Slip_Header__c>();
          oaSlipHeaders = [SELECT ID,Name,OA_Invoice_ID__c,OA_Invoice_Name__c,Invoice_Date__c,
                           Processed__c,OA_Invoice_Subtotal__c,OA_Invoice_Subtotal_Currency__c
                           FROM OA_Slip_Header__c WHERE Processed__c = FALSE
                            AND OA_Invoice_ID__c != NULL];
         //Slip Header Map : OA Invoice Id to Slip Headers
         Map<String,OA_Slip_Header__c> slipHeadersMap = new Map<String,OA_Slip_Header__c>();
         if(oaSlipHeaders.size() > 0)
         {
             for(OA_Slip_Header__c header : oaSlipHeaders)
             {
                 if(! slipHeadersMap.containsKey(header.OA_Invoice_ID__c))
                 {
                    slipHeadersMap.put(header.OA_Invoice_ID__c,header);
                 }
             }
         }
        	//Create Invoices for the Header and Update the Slip Records
        List<OA_Slip__c> oaSlipRecords = new List<OA_Slip__c>();
        oaSlipRecords = [SELECT ID,Name,Project__c,Project__r.Name,Product__c,Invoice__r.Name,Resource__c,Hour__c,
                         Product__r.Name,Order_Product__c,Type__c,Order_Product__r.blng__LegalEntity__c,
                         Order_Product__r.blng__BillingAccount__r.ShippingStreet,Order_Product__r.blng__BillingAccount__r.ShippingCity,
                         Order_Product__r.blng__BillingAccount__r.ShippingState,Order_Product__r.blng__BillingAccount__r.ShippingCountry,
                         Order_Product__r.blng__BillingAccount__r.ShippingPostalCode,
                         Order_Product__r.blng__TaxRule__c,Order_Product__r.blng__TaxTreatment__c,
                         Rate__c,Date__c,Total__c,OA_Invoice_ID__c FROM OA_Slip__c
                         WHERE OA_Invoice_ID__c in :slipHeadersMap.keySet() AND
                         Processed__c = FALSE AND Project__c != NULL
                         AND OA_Invoice_ID__c != NULL AND Type__c != NULL //AND TYPE__c = 'F'
                         //AND Order_Product__c = '802D7000001jqkLIAQ' //AND Project__r.Name = 'Project 1'
                         ORDER BY Project__c,OA_Invoice_ID__c,Order_Product__c,Resource__c Limit 100];
        //System.debug('oaSlipRecords:'+oaSlipRecords.size());
       //Group by Project
        Map<String,List<OA_Slip__c>> pjtToOASlipMap = new Map<String,List<OA_Slip__c>>();
        //Group By Invoice
        Map<String,List<OA_Slip__c>> invToOASlipMap = new Map<String,List<OA_Slip__c>>();
        //Group By Invoice 
        Map<String,List<OA_Slip__c>> productToOASlipMap = new Map<String,List<OA_Slip__c>>();
        //Group By Resource
        Map<String,List<OA_Slip__c>> resourceToOASlipMap = new Map<String,List<OA_Slip__c>>();
        if(oaSlipRecords.size() > 0)
        {
            pjtToOASlipMap.putAll(getPjtToOASlipMap(oaSlipRecords));
            
        }
        //Group by Invoice
        System.debug('pjtToOASlipMap.keySet():'+pjtToOASlipMap.keySet().size());
        if(pjtToOASlipMap.keySet().size() > 0){
        for(String project : pjtToOASlipMap.keySet())
        {
            // invToOASlipMap.clear(); productToOASlipMap.clear(); resourceToOASlipMap.clear();
            //Get the List of OASlip records per Project
			List<OA_Slip__c> oaSlipPerProject = pjtToOASlipMap.get(project);   
            if(oaSlipPerProject != null)
            {
                invToOASlipMap.putAll(getInvToOASlipMap(oaSlipPerProject));
                //Get the Invoice values and Group it
                
            }
        }
        }
        //Group by Order Product
        System.debug('invToOASlipMap.keySet():'+invToOASlipMap.keySet().size());
        if(invToOASlipMap.keySet().size() > 0){
        for(String invoice : invToOASlipMap.keySet())
        {
            //Get the List of OASlip records per Invoice
			List<OA_Slip__c> oaSlipPerInvoice = invToOASlipMap.get(invoice);   
            if(oaSlipPerInvoice != null)
            {
                System.debug('oaSlipPerInvoice:'+oaSlipPerInvoice.size());
                productToOASlipMap.putAll(getTheSlipPerInvoice(oaSlipPerInvoice));
                System.debug('productToOASlipMap.keyset():'+invoice + '-'+productToOASlipMap.keySet().size());
                //System.debug('getTheSlipPerInvoice(oaSlipPerInvoice):'+getTheSlipPerInvoice(oaSlipPerInvoice));
            }
        }
        }
        //Group by Resource
        System.debug('productToOASlipMap.keySet():'+productToOASlipMap.keySet().size());
        if(productToOASlipMap.keySet().size() > 0){
        for(String product : productToOASlipMap.keySet())
        {
            //Get the List of OASlip records per Product
			List<OA_Slip__c> oaSlipPerProduct = productToOASlipMap.get(product);   
            if(oaSlipPerProduct != null)
            {
                resourceToOASlipMap.putAll(getTheResourceToOASlipMap(oaSlipPerProduct));
                //Get the Product values and Group it
                
            }
        }
        }
        System.debug('resourceToOASlipMap.keySet():'+resourceToOASlipMap.keySet().size());
        //Now get the grouped values to create the Summary record.
        if(pjtToOASlipMap.keySet().size() > 0){
        List<Resource_Summary__c> resourceSummaryList = new List<Resource_Summary__c>();
        List<OA_Slip__c> oaSlipListForProcessedUpdate = new List<OA_Slip__c>();
        for(String project : pjtToOASlipMap.keySet())
        {
            //System.debug('Aggregate');
            //Get the Grouped values for Project,Invoice,Resource
            if(pjtToOASlipMap.containsKey(project))
            {
                System.debug('Per Project:'+project + '-'+ pjtToOASlipMap.get(project).size());
                System.debug('Per Project Inv:'+invToOASlipMap.keySet().Size()+'-Prod:'+productToOASlipMap.keyset().Size()+'-'+resourceToOASlipMap.keyset().Size());
                //Get the aggregated values
                List<Resource_Summary__c> resourceSummaryListPerProject = getAggregatedValuesForProject(project,pjtToOASlipMap.get(project),invToOASlipMap,productToOASlipMap,resourceToOASlipMap);
                System.debug('resourceSummaryListPerProject Main:'+resourceSummaryListPerProject.size());
                System.debug('resourceSummaryList Main:'+resourceSummaryList.size());
                if(resourceSummaryListPerProject != null) 
                {
                    //System.debug('resourceSummaryListPerProject:'+resourceSummaryListPerProject.size());
                    //Get the unique records 
                    for(Resource_Summary__c summary : resourceSummaryListPerProject){
                       System.debug('Test:'+summary.Project__c);
                        if(! resourceSummaryList.contains(summary)){
                    	resourceSummaryList.add(summary);
                        }
                    }
                }
            }
        }
        System.debug('resourceSummaryList:'+resourceSummaryList.size());
        if(resourceSummaryList.size() > 0)
        {
            try{
                List<Database.SaveResult> results = Database.insert(resourceSummaryList);
                //Create Invoice and Invoice Lines from Summary Records
                Set<Id> successIds = new Set<Id>();
                for(Database.SaveResult result : results)
                {
                    if(result.isSuccess())
                        successIds.add(result.getId());
                }
                //Get the records to collect the Invoice line details
                if(successIds.size() > 0)
                {
                    //Create Billing Invoice and Invoice Lines
                    createInvAndLinesBasedOnResSummary(successIds,oaSlipRecords,slipHeadersMap);
                }
            }
            Catch(Exception e)
            {//System.debug('Exception:'+e.getMessage());
             return false;
            }
        }
        }
            return true;
        }
        Catch(Exception ex)
        {
			return false;            
        }
    }
    public static void createInvAndLinesBasedOnResSummary(Set<Id> successIds, List<OA_Slip__c> oaSlipRecords,Map<String,OA_Slip_Header__c> slipHeadersMap)
    {
        List<OA_Slip__c> oaSlipListForProcessedUpdate = new List<OA_Slip__c>();
        List<OA_Slip_Header__c> oaSlipHeaderListForProcessedUpdate = new List<OA_Slip_Header__c>();
        List<Resource_Summary__c> summaryList = [SELECT Id,Project__c,OA_Invoice_ID__c,Product__c,Order_Product__r.OrderId,
                                                 Order_Product__c,Product__r.Name,Order_Product__r.Order.AccountId,
                                                 Resource__c,Hours__c,Type__c,Total__c,Order_Product__r.blng__LegalEntity__c,
                                                 Order_Product__r.blng__BillingAccount__r.ShippingStreet,Order_Product__r.blng__BillingAccount__r.ShippingCity,
		                          				 Order_Product__r.blng__BillingAccount__r.ShippingState,Order_Product__r.blng__BillingAccount__r.ShippingCountry,
                                                 Order_Product__r.blng__BillingAccount__r.ShippingPostalCode,
                                                 Order_Product__r.blng__TaxRule__c,Order_Product__r.blng__TaxTreatment__c,Order_AccountId__c
                                                 FROM Resource_Summary__c 
                                                 WHERE Id in : successIds 
                                                 Order By Project__c,OA_Invoice_ID__c,Order_Product__c,Resource__c Limit 100];
                    System.debug('summaryList:'+summaryList.size());
        		    System.debug('summaryList:'+summaryList);
                    if(summaryList.size() > 0)
                    {
                        //Create Invoices
                        List<blng__InvoiceLine__c> invLinesForCreate = new List<blng__InvoiceLine__c>();
                        //CreateBillingInvLines
                        invLinesForCreate = createBillingInvLines(summaryList,slipHeadersMap);
                        //}
                        //System.debug('invLinesForCreate Size:'+invLinesForCreate.size());
                        if(invLinesForCreate.size() > 0)
                        {Database.insert(invLinesForCreate);
                        //Update the Processed Records in Slip Header Object
                        for(String oaInvId : slipHeadersMap.keySet())
                        {
                            slipHeadersMap.get(oaInvId).Processed__c = true;
                            oaSlipHeaderListForProcessedUpdate.add(slipHeadersMap.get(oaInvId));
                        }
                        //Update the Processed Records in Slip Object
                        for(OA_Slip__c slip : oaSlipRecords){
                        slip.Processed__c  = true;
                        oaSlipListForProcessedUpdate.add(slip);
                        }
                         if(oaSlipHeaderListForProcessedUpdate.size() > 0){
                         Database.update(oaSlipHeaderListForProcessedUpdate);
                         if(oaSlipListForProcessedUpdate.size() > 0)
                         {Database.update(oaSlipListForProcessedUpdate);
                         }
                         }
                        }
                    }
    }
    /*
public static class PjtWrapper{
Map<String,List<SummaryWrapper> 
}
* public static class SummaryWrapper{
Map<String,List<Resource_Summary__c> pjtToSummary;
}
     */
    public static Map<String,List<OA_Slip__c>> getPjtToOASlipMap(List<OA_Slip__c> oaSlipRecords)
    {
             Map<String,List<OA_Slip__c>> pjtToOASlipMap = new Map<String,List<OA_Slip__c>>();
            for(OA_Slip__c osaSli : oaSlipRecords)
            {
                if(pjtToOASlipMap.containsKey(osaSli.Project__c))
                {pjtToOASlipMap.get(osaSli.Project__c).add(osaSli);}
                else{pjtToOASlipMap.put(osaSli.Project__c,new List<OA_Slip__c>{osaSli});}
            }
            return pjtToOASlipMap;
            
        }
    public static Map<String,List<OA_Slip__c>> getInvToOASlipMap(List<OA_Slip__c> oaSlipPerProject)
    {
         Map<String,List<OA_Slip__c>> invToOASlipMap = new Map<String,List<OA_Slip__c>>();
        for(OA_Slip__c slipForInv : oaSlipPerProject)
                {
                    if(invToOASlipMap.containsKey(slipForInv.Project__c + '-'+slipForInv.OA_Invoice_ID__c))
                	{invToOASlipMap.get(slipForInv.Project__c + '-'+slipForInv.OA_Invoice_ID__c).add(slipForInv);}
                	else{invToOASlipMap.put(slipForInv.Project__c + '-'+slipForInv.OA_Invoice_ID__c,new List<OA_Slip__c>{slipForInv});}
                }
        return invToOASlipMap; 
    }
    public static  Map<String,List<OA_Slip__c>>  getTheResourceToOASlipMap(List<OA_Slip__c> oaSlipPerProduct)
    {
        Map<String,List<OA_Slip__c>> resourceToOASlipMap = new Map<String,List<OA_Slip__c>>();
        for(OA_Slip__c slipForProd : oaSlipPerProduct)
                {
                    if(resourceToOASlipMap.containsKey(slipForProd.Resource__c))
                	{resourceToOASlipMap.get(slipForProd.Resource__c).add(slipForProd);}
                	else{resourceToOASlipMap.put(slipForProd.Resource__c,new List<OA_Slip__c>{slipForProd});}
                }
        return resourceToOASlipMap;
    }
    //Add the Invoice in the Key as one oreder product can be in 2 invoices.
    public static Map<String,List<OA_Slip__c>> getTheSlipPerInvoice(List<OA_Slip__c> oaSlipPerInvoice)
    {
        System.debug('TS:'+oaSlipPerInvoice.size()+'-'+oaSlipPerInvoice);
        Map<String,List<OA_Slip__c>> productToOASlipMap = new Map<String,List<OA_Slip__c>>();
        //Get the Product values and Group it
                for(OA_Slip__c slipForInv : oaSlipPerInvoice)
                {
                    system.debug('t:'+slipForInv.Order_Product__c + '-'+slipForInv.OA_Invoice_ID__c);
                    if(productToOASlipMap.containsKey(slipForInv.Order_Product__c + '-'+slipForInv.OA_Invoice_ID__c))
                	{productToOASlipMap.get(slipForInv.Order_Product__c + '-'+slipForInv.OA_Invoice_ID__c).add(slipForInv);}
                	else{productToOASlipMap.put(slipForInv.Order_Product__c + '-'+slipForInv.OA_Invoice_ID__c,new List<OA_Slip__c>{slipForInv});}
                }
        return productToOASlipMap;
    }
    //Billing Inv lines
    public static List<blng__InvoiceLine__c> createBillingInvLines(List<Resource_Summary__c> summaryList,Map<String,OA_Slip_Header__c> slipHeadersMap)
    {
        List<blng__InvoiceLine__c> invLinesForCreate = new List<blng__InvoiceLine__c>();
        List<blng__Invoice__c> invoicesForCreate = new List<blng__Invoice__c>();
        //Aggregate the ResourceSummary based on Project,Invoice,InvLine,Resource
                        List<Resource_Summary__c> resourceSummaryForInvLinesList = getAggregatedValuesForInvLines(summaryList);
        				System.debug('resourceSummaryForInvLinesList:'+resourceSummaryForInvLinesList);
                        if(resourceSummaryForInvLinesList != null){
                         //Create Invoices
                         //Get the Order for Order Product
                         Map<String,Order> orderProdToOrder = getOrderForOrderProd(resourceSummaryForInvLinesList);
                         //Get the Order Product for Order Product Ids - not able to get the Project's Order Product's Tax details
                         Map<String,OrderItem> orderProdIdToOrderProd = getOrderProdForOrderProdIds(resourceSummaryForInvLinesList);
                         System.debug('orderProdToOrder:'+orderProdToOrder);
                         Map<String,List<Resource_Summary__c>> resourceSummaryForInvoices = getAggregatedValuesForInvoices(resourceSummaryForInvLinesList);
                         System.debug('resourceSummaryForInvoices:'+resourceSummaryForInvoices);
                         //Create Invoices
                         //One invoice mapped to One Order
                         //One Order mapped to one Project
                            if(resourceSummaryForInvoices != null && resourceSummaryForInvoices.keySet().size() > 0){
                                for(String invoiceIdWithType : resourceSummaryForInvoices.keySet())
                                {
                                    Resource_Summary__c summary = resourceSummaryForInvoices.get(invoiceIdWithType)[0];
                                    System.debug('summary:'+summary);
                                    if(summary != null){
                                       // for(Resource_Summary__c summary : temp){
                                            blng__Invoice__c invoice = new blng__Invoice__c();
                                            System.debug('AccId:'+summary.Order_Product__c);
                                            //System.debug('AccId:'+summary.Order_Product__r.OrderId);
                                            if(orderProdToOrder != null && orderProdToOrder.keySet().size() > 0 && orderProdToOrder.containsKey(summary.Order_Product__c))
                                            {invoice.blng__Account__c = orderProdToOrder.get(summary.Order_Product__c).AccountId;//Order_Product__r.Order.AccountId;
                                            invoice.blng__Order__c = orderProdToOrder.get(summary.Order_Product__c).Id;//summary.Order_Product__r.OrderId;
                                            invoice.SFDC_Services_Project__c = summary.Project__c;
                                            if(slipHeadersMap.containsKey(summary.OA_Invoice_ID__c))//From Slip Header
                                            invoice.blng__InvoiceDate__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).Invoice_Date__c;
                                            //Invoice Bue date = Invoice Date + Order's Payment Term
                                             try{
                                            if( slipHeadersMap.get(summary.OA_Invoice_ID__c).Invoice_Date__c != null && orderProdToOrder.get(summary.Order_Product__c).Payment_Term_Software__c != null ){
                                                Integer orderPaymentTerm  = (orderProdToOrder.get(summary.Order_Product__c).Payment_Term_Software__c).contains('Net ') ?  
                                                    				Integer.valueOf((orderProdToOrder.get(summary.Order_Product__c).Payment_Term_Software__c).split('Net ')[1]) : 0;
                                                invoice.blng__DueDate__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).Invoice_Date__c + orderPaymentTerm;
                                             }
                                             }
                                             catch(Exception ex){ System.debug('ServiceBillingInvoice Creation Error:'+ ex.getMessage() );}
                                            invoice.OA_Invoice_ID__c = summary.OA_Invoice_ID__c;
                                           // if(slipHeadersMap.containsKey(summary.OA_Invoice_ID__c))//From Slip Header
                                            invoice.OA_Invoice_Name__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).OA_Invoice_Name__c;
                                            if(slipHeadersMap.containsKey(summary.OA_Invoice_ID__c))//From Slip Header
                                            invoice.OA_Invoice_Subtotal__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).OA_Invoice_Subtotal__c;
                                            if(slipHeadersMap.containsKey(summary.OA_Invoice_ID__c))//From Slip Header
                                            invoice.OA_Invoice_Subtotal_Currency__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).OA_Invoice_Subtotal_Currency__c;
                                            invoice.CreatedFromServiceBillingBatch__c = true;
                                            if(! invoicesForCreate.contains(invoice))
                                            invoicesForCreate.add(invoice);
                                            }
                                       // }
                                    }
                                   //Get the list of records for Invoice Id
                                 /*   List<Resource_Summary__c> temp = resourceSummaryForInvoices.get(invoiceIdWithType);
                                    if(temp != null){
                                        for(Resource_Summary__c summary : temp){
                                            blng__Invoice__c invoice = new blng__Invoice__c();
                                            invoice.blng__Account__c = summary.Order_Product__r.Order.AccountId;
                                            invoice.blng__Order__c = summary.Order_Product__r.OrderId;
                                            invoice.SFDC_Services_Project__c = summary.Project__c;
                                            if(slipHeadersMap.containsKey(summary.OA_Invoice_ID__c))//From Slip Header
                                            invoice.blng__InvoiceDate__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).Invoice_Date__c;
                                            invoice.OA_Invoice_ID__c = summary.OA_Invoice_ID__c;
                                            if(slipHeadersMap.containsKey(summary.OA_Invoice_ID__c))//From Slip Header
                                            invoice.OA_Invoice_Name__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).OA_Invoice_Name__c;
                                            if(slipHeadersMap.containsKey(summary.OA_Invoice_ID__c))//From Slip Header
                                            invoice.OA_Invoice_Subtotal__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).OA_Invoice_Subtotal__c;
                                            if(slipHeadersMap.containsKey(summary.OA_Invoice_ID__c))//From Slip Header
                                            invoice.OA_Invoice_Subtotal_Currency__c = slipHeadersMap.get(summary.OA_Invoice_ID__c).OA_Invoice_Subtotal_Currency__c;
                                            invoice.CreatedFromServiceBilling__c = true;
                                            if(! invoicesForCreate.contains(invoice))
                                            invoicesForCreate.add(invoice);
                                        }
                                    }*/
                                }
                            }
                            if(invoicesForCreate.size() > 0){
                                //Insert the Invoices
                                Set<String> invIds = new Set<String>();
                                List<Database.SaveResult> results = Database.Insert(invoicesForCreate);
                                if(results != null && results.size()>0)
                                {
                                    for(Database.SaveResult result : results)   {
                                        if(result.IsSuccess())
                                        {invIds.add(result.getId());}
                                    }
                                }
                                if(invIds.size() > 0){
                                 //Order to Invoice Map
                                 Map<String,blng__Invoice__c> orderToInvoiceMap = new Map<String,blng__Invoice__c>();
                                //Get the Created Invoice Records
                                List<blng__Invoice__c> newInvoices = [SELECT Id,blng__Account__c,blng__Order__c,SFDC_Services_Project__c,
                                                                      blng__InvoiceDate__c,OA_Invoice_Name__c,OA_Invoice_ID__c,
                                                                      OA_Invoice_Subtotal__c,OA_Invoice_Subtotal_Currency__c  
                                                                      FROM blng__Invoice__c where Id in :invIds 
                                                                      AND CreatedFromServiceBillingBatch__c = TRUE];
                                if(newInvoices.size() > 0)
                                {
                                    for(blng__Invoice__c newInv : newInvoices){
                                        if(! orderToInvoiceMap.containsKey(newInv.blng__Order__c)){
                                            orderToInvoiceMap.put(newInv.blng__Order__c,newInv);
                                        }
                                    }
                                }
                            		System.debug('In Inv orderToInvoiceMap:'+orderToInvoiceMap.size());
                        			//Create Invoice Lines
                         			for(Resource_Summary__c resSummary : resourceSummaryForInvLinesList ){
                        			//for(Resource_Summary__c resSummary : summaryList ){
                        			 blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
                                        //if(orderToInvoiceMap.containsKey(resSummary.Order_Product__r.OrderId)){
                                        System.debug('In Inv:'+resSummary.Order_Product__c+'-'+orderProdToOrder.keySet().size());
                                        if(orderProdToOrder != null && orderProdToOrder.keySet().size() > 0 && orderProdToOrder.containsKey(resSummary.Order_Product__c)){
                                            System.debug('In Inv Line:'+resSummary.Order_Product__c+'-'+orderProdToOrder.get(resSummary.Order_Product__c).Id);
                                            invLine.blng__Invoice__c = orderToInvoiceMap.get(orderProdToOrder.get(resSummary.Order_Product__c).Id).Id;
                                             invLine.blng__Subtotal__c = resSummary.Total__c;
                                             invLine.blng__OrderProduct__c = resSummary.Order_Product__c;
                                             //Tax details from Order Product's Account ////////////////////TO DO
                                             invLine.blng__TaxStreet__c = orderProdToOrder.get(resSummary.Order_Product__c).Account.ShippingStreet;
                                             invLine.blng__TaxCity__c = orderProdToOrder.get(resSummary.Order_Product__c).Account.ShippingCity;
                                             invLine.blng__TaxState__c = orderProdToOrder.get(resSummary.Order_Product__c).Account.ShippingState;
                                             invLine.blng__TaxCountry__c = orderProdToOrder.get(resSummary.Order_Product__c).Account.ShippingCountry;
                                             invLine.blng__TaxZipCode__c = orderProdToOrder.get(resSummary.Order_Product__c).Account.ShippingPostalCode;
                                            if(orderProdIdToOrderProd != null){
                                             invLine.blng__TaxRule__c = orderProdIdToOrderProd.get(resSummary.Order_Product__c).blng__TaxRule__c;
                                             invLine.blng__TaxTreatment__c = orderProdIdToOrderProd.get(resSummary.Order_Product__c).blng__TaxTreatment__c;
                                             invLine.blng__LegalEntity__c = orderProdIdToOrderProd.get(resSummary.Order_Product__c).blng__LegalEntity__c;
                                             invLine.blng__StartDate__c = orderProdIdToOrderProd.get(resSummary.Order_Product__c).ServiceDate;
                                             invLine.blng__EndDate__c = orderProdIdToOrderProd.get(resSummary.Order_Product__c).EndDate;
                                             invLine.Name = orderProdIdToOrderProd.get(resSummary.Order_Product__c).Product_Name__c;/////////////To DO
                                             }
                                             invLine.blng__Product__c = resSummary.product__c;
                                             invLine.Project__c = resSummary.Project__c;
                                             //invLine.Resource__c = resSummary.Resource__c;
                                             invLine.blng__Quantity__c = resSummary.Hours__c;
                                             invLine.CreatedFromServiceBillingBatch__c = true;
                                             if(! invLinesForCreate.contains(invLine)){invLinesForCreate.add(invLine);}
                                        }
                                    }
                                }
                            }
                        }
        System.debug('Inv Lines create size():'+invLinesForCreate.size());
        return invLinesForCreate;
    
    }
    //Get the Order Item for the Order Item Ids
    public static Map<String,OrderItem> getOrderProdForOrderProdIds(List<Resource_Summary__c> resourceSummaryForInvLinesList) {
        Set<String> ordProdIds = new Set<String>();
        Map<String,String> ordProdToOrderIdMap = new Map<String,String>();
        //Get the Order Prod Ids
        for(Resource_Summary__c resSummary : resourceSummaryForInvLinesList)
        {ordProdIds.add(resSummary.Order_Product__c);}
         List<OrderItem> orderProds = [SELECT Id,OrderId,blng__TaxRule__c,blng__TaxTreatment__c,blng__LegalEntity__c,ServiceDate,EndDate,
                                       Product_Name__c FROM OrderItem
                                       WHERE Id in :ordProdIds];
        Map<String,OrderItem> ordProdIdToOrderProdMap = new Map<String,OrderItem>(orderProds);
        return ordProdIdToOrderProdMap;
    }
    //Get the Order Details for Order Product
    public static Map<String,Order> getOrderForOrderProd(List<Resource_Summary__c> resourceSummaryForInvLinesList) {
        Set<String> ordProdIds = new Set<String>();
        Map<String,String> ordProdToOrderIdMap = new Map<String,String>();
        Map<String,Order> ordProdToOrderMap = new Map<String,Order>();
        //Get the Order Prod Ids
        for(Resource_Summary__c resSummary : resourceSummaryForInvLinesList)
        {ordProdIds.add(resSummary.Order_Product__c);}
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
    public static Map<String,List<Resource_Summary__c>> getAggregatedValuesForInvoices(List<Resource_Summary__c> resourceSummaryForInvLinesList)
    {
        Map<String,List<Resource_Summary__c>> invToResourcesMap = new Map<String,List<Resource_Summary__c>>();
        for(Resource_Summary__c resSummary : resourceSummaryForInvLinesList)
        {
            //System.debug('invToResourcesMap.containsKey(resSummary.OA_Invoice_ID__c + resSummary.Type__:'+resSummary.OA_Invoice_ID__c +'-'+ resSummary.Type__c);
            //System.debug('invToResourcesMap.containsKey(resSummary.OA_Invoice_ID__c + resSummary.Type__:'+invToResourcesMap.containsKey(resSummary.OA_Invoice_ID__c + resSummary.Type__c));
            if(invToResourcesMap.containsKey(resSummary.OA_Invoice_ID__c + resSummary.Type__c)){
                invToResourcesMap.get(resSummary.OA_Invoice_ID__c + resSummary.Type__c).add(resSummary);
            }
            else {invToResourcesMap.put(resSummary.OA_Invoice_ID__c + resSummary.Type__c,new List<Resource_Summary__c>{resSummary});}
        }
        System.debug('invToResourcesMap:'+invToResourcesMap.keySet().size());
        return invToResourcesMap;
    }
    //Get aggregated values for Invoice Lines
     //Get the aggregated values for Project
    public static List<Resource_Summary__c> getAggregatedValuesForInvLines(List<Resource_Summary__c> resSummaries)
   {
       System.debug('getAggregatedValuesForProject');
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
               {	if(invToResSummaryMap.containsKey(inv.Project__c+'-'+inv.OA_Invoice_ID__c))
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
               {	if(orderProdToResSummaryMap.containsKey(ordProd.Order_Product__c))
           			{orderProdToResSummaryMap.get(ordProd.Order_Product__c).add(ordProd);}
           			else
           			{orderProdToResSummaryMap.put(ordProd.Order_Product__c,new List<Resource_Summary__c>{ordProd});}
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
               {	if(resourceToResSummaryMap.containsKey(ordProd.Resource__c))
           			{resourceToResSummaryMap.get(ordProd.Resource__c).add(ordProd);}
           			else
           			{resourceToResSummaryMap.put(ordProd.Resource__c,new List<Resource_Summary__c>{ordProd});}
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
                                   
                           if(orderProdToResSummaryMap.containsKey(summaryFororderProd.Order_Product__c) && summaryFororderProd.OA_Invoice_ID__c == forPjt.OA_Invoice_ID__c
                             && summaryFororderProd.Project__c == pjt)
                           {
                               List<Resource_Summary__c> summaryforResource = orderProdToResSummaryMap.get(summaryFororderProd.Order_Product__c);
                               if(summaryforResource != null)
                               {
                                   for(Resource_Summary__c resource : summaryforResource){
                                   if(resourceToResSummaryMap.containsKey(resource.Resource__c) && resource.OA_Invoice_ID__c == forPjt.OA_Invoice_ID__c
                                   && resource.Project__c == pjt && resource.Order_Product__c == summaryFororderProd.Order_Product__c)
                                   {
                                       hours = hours + resource.Hours__c;
                                       amount = amount + resource.Total__c;
                                   }
                                   }
                                   //Create Resource Summary
                       			 
                               }
                           }
                           Resource_Summary__c resSummary = new Resource_Summary__c();
       							 resSummary.Project__c = summaryFororderProd.Project__c;
                        		 //resSummary.Invoice__c = summaryFororderProd.Invoice__c;
                        		 resSummary.OA_Invoice_ID__c = summaryFororderProd.OA_Invoice_ID__c;
                        		 resSummary.Product__c = summaryFororderProd.Product__c;
                        		 resSummary.Order_Product__c = summaryFororderProd.Order_Product__c;
                                // resSummary.Resource__c = summaryFororderProd.Resource__c;//inv.Resource__c;
                                 resSummary.Type__c = summaryFororderProd.Type__c;
                                 resSummary.Hours__c =  hours;
                                 resSummary.Total__c = amount;
                                 
                                 if( ! resourceSummaryForInvLinesList.contains(resSummary))
                                     resourceSummaryForInvLinesList.add(resSummary);
                       }
                   }
               }
           }
           }
       }
       System.debug('resourceSummaryForInvLinesList:'+resourceSummaryForInvLinesList.size());
       return resourceSummaryForInvLinesList;
   }
    //Get the aggregated values for Project
public static List<Resource_Summary__c> getAggregatedValuesForProject(String project, List<OA_Slip__c> pjtToOASlipList, Map<String, List<OA_Slip__c>> invoiceToOASlipMap, Map<String, List<OA_Slip__c>> productToOASlipMap, Map<String, List<OA_Slip__c>> resourceToOASlipMap) {
    List<Resource_Summary__c> resourceSummaryList = new List<Resource_Summary__c>();
    for (OA_Slip__c pjt : pjtToOASlipList) {
        if (invoiceToOASlipMap.containsKey(pjt.Project__c+'-'+pjt.OA_Invoice_ID__c) && pjt.Project__c == project) {
            System.debug('project:'+project+'-'+pjt.OA_Invoice_ID__c);
            List<OA_Slip__c> invToOASlipList = invoiceToOASlipMap.get(pjt.Project__c+'-'+pjt.OA_Invoice_ID__c);
            for (OA_Slip__c inv : invToOASlipList) {
                if (productToOASlipMap.containsKey(inv.Order_Product__c + '-'+ inv.OA_Invoice_ID__c) && inv.Project__c == project ){//&& inv.Invoice__c == pjt.Invoice__c) {
                   //if(inv.Order_Product__c)
                    List<OA_Slip__c> products = productToOASlipMap.get(inv.Order_Product__c + '-'+inv.OA_Invoice_ID__c);
                    System.debug('project IN:'+project+'-'+pjt.OA_Invoice_ID__c+'-'+inv.Order_Product__c + '-'+products.size());
                    for (OA_Slip__c product : products) {
                        //Collect all the resources for the Product,Invoice,Project
                        Map<String,List<OA_Slip__c>> orderProdToResourcesMap = getResources(products,project ,inv.OA_Invoice_ID__c);
                        //if (resourceToOASlipMap.containsKey(product.Resource__c) && product.Project__c == project ){//&& product.Invoice__c == inv.Invoice__c && product.Order_Product__c == inv.Order_Product__c) {
                        System.debug('project IN:'+project+'-'+pjt.OA_Invoice_ID__c+'-'+inv.Order_Product__c + '-'+products.size()+'-'+orderProdToResourcesMap.keySet().size());
                        for(String orderProdRes : orderProdToResourcesMap.keySet()){
                            List<OA_Slip__c> resources = orderProdToResourcesMap.get(orderProdRes);
                            System.debug('resources:'+resources);
                            System.debug('resources:'+resources.size());
                            Decimal hours = 0;
                            Decimal amount = 0;
                            Map<String,String> resMap = new Map<String,String>();
                            for (OA_Slip__c resource : resources) {
                                    hours += resource.Hour__c;
                                    amount += resource.Total__c;
                              //if(! resMap.containsKey(resource.Resource__c))
                                 //{
                               resMap.put(resource.Resource__c,String.valueOf(hours)+'='+String.valueOf(amount));
                            }
                            for(String res : resMap.keySet()){
                            Resource_Summary__c resSummary = new Resource_Summary__c();
                            resSummary.Project__c = project;
                            //resSummary.Invoice__c = inv.Invoice__c;
                            resSummary.OA_Invoice_ID__c = inv.OA_Invoice_ID__c;
                            resSummary.Product__c = product.Product__c;
                            resSummary.Order_Product__c = product.Order_Product__c;
                            resSummary.Type__c = product.Type__c;
                            resSummary.Resource__c = res;
                            if(resMap.containsKey(res))
                            { resSummary.Hours__c = Decimal.ValueOf(resMap.get(res).split('=')[0]);//hours;
                            resSummary.Total__c = Decimal.ValueOf(resMap.get(res).split('=')[1]);//amount;
                            }
                           // resSummary.Hours__c = hours;
                            //resSummary.Total__c = amount;
                            if (!resourceSummaryList.contains(resSummary)) {
                                resourceSummaryList.add(resSummary);
                            }
                        }
                        }
                        //}
                    }
                }
            }
        }
    }
    return resourceSummaryList;
}


public static Map<String,List<OA_Slip__c>> getResources(List<OA_Slip__c> products,String invProject , String invInvoice)
{
    Map<String,List<OA_Slip__c>> resourceMap = new Map<String,List<OA_Slip__c>>();
    for(OA_Slip__c prod : products)
    {
        System.debug('getResources:Input'+invProject+'-'+invInvoice);
        System.debug('getResources:Cond'+prod.OA_Invoice_ID__c+'-'+prod.Project__c);
        if(prod.OA_Invoice_ID__c == invInvoice && prod.Project__c == invProject)
        {
            if(resourceMap.containsKey(prod.Resource__c))
            {resourceMap.get(prod.Resource__c).add(prod);}
            else {
                resourceMap.put(prod.Resource__c,new List<OA_Slip__c>{prod});
            }
        }
    }
    return resourceMap;
	    
}
}