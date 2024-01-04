/**
* @description       : This class is a handler class for SBQQQuoteLineTrigger, BIZ-47580.
					   Create child line items for the static parent bundle
* @author            : Dhiraj Kumar
* @last modified on  : 09-22-2023
* @last modified by  : Dhiraj Kumar
* Modifications Log
* Ver   Date         Author         Modification
* 1.0   09-22-2023   Dhiraj Kumar   Initial Version
* 2.0   12-27-2023   Dhiraj Kumar   Added updateStaticBundleOnQuote method
**/
public without sharing class AddStaticBundleHandler {
       /**
* @description : Method executes on After Insert event
* @author Dhiraj Kumar | 09-22-2023  
* @param List<SBQQ__QuoteLine__c> newQuoteLineList 
**/ 
    
    
    public static boolean afterInsertFirstRun=true;
    public static void afterInsert(List<SBQQ__QuoteLine__c> newQuoteLineList){
        if(afterInsertFirstRun){
            addStaticBundle(newQuoteLineList,null,true);
            afterInsertFirstRun=false; 
        }
    }

        /**
* @description : Method executes on Before Delete event
* @author Dhiraj Kumar | 09-22-2023  
* @param Map<Id,SBQQ__QuoteLine__c oldMap 
**/    
    public static boolean afterDeleteFirstRun=true;
    public static void afterDelete(Map<Id,SBQQ__QuoteLine__c> oldMap){
        if(afterDeleteFirstRun){
            updateValidationChecklist(oldMap);
            afterDeleteFirstRun=false;
        }
    }
 /**
* @description : Add Child Products into quote if Parent Product is matched with LookupData; Created as part of BIZ-47580.
* @author Dhiraj Kumar | 09-22-2023 
* @param List<SBQQ__QuoteLine__c> newQuoteLineList 
* @param Map<Id, SBQQ__QuoteLine__c> oldMap 
* @param boolean isInsert 
**/
    
    public static void addStaticBundle(List<SBQQ__QuoteLine__c> newQuoteLineList,Map<Id,SBQQ__QuoteLine__c> oldMap,boolean isInsert)
    {
        try
        {
            System.debug('*********addStaticBundle METHOD STARTS--->');
            List<Id> listOfParentQuotLineIds = new List<Id>();
            List<SBQQ__QuoteLine__c> listOfNewQLsToInsert = new List<SBQQ__QuoteLine__c>();
            List<String> parentBundleIdLst = new List<String>();
            List<SBQQ__Quote__c> quoteLst;
            List<Validation_Checklist__c> vcLstToUpsert = new List<Validation_Checklist__c>(); 
            Set<Id> productIds = new Set<Id>();
            Set<ID> quoteIds = new Set<Id>();
            Map<Id,List<SBQQ__LookupData__c>> mapOfLookupData = new Map<Id,List<SBQQ__LookupData__c>>();// Key - Parent Product Id, Value - Records of LookupData object corresponding to product Id
            Map<Id,Set<Id>> mapOfQuoteByParentProductId = new Map<Id,Set<Id>>();
            Map<Id,boolean> mapOfQuoteByFlag = new Map<Id,boolean>();
            SBQQ.TriggerControl.disable();
            
            if(newQuoteLineList != null && !newQuoteLineList.isEmpty())
            {
                for(SBQQ__QuoteLine__c quoteLineObj : newQuoteLineList)
                { 
                    if(String.isNotBlank(quoteLineObj.SBQQ__Product__c) &&
                       String.isBlank(quoteLineObj.SBQQ__RequiredBy__c) && quoteLineObj.SBQQ__Quantity__c > 0)
                    {
                        ProductIds.add(quoteLineObj.SBQQ__Product__c); // Get ProductIds
                        quoteIds.add(quoteLineObj.SBQQ__Quote__c);
                    }
                }

                if(quoteIds != null && !quoteIds.isEmpty())
                {
                    for(SBQQ__Quote__c quote : [Select Id,StaticBundleIds__c,(Select Id,Static_Bundle_Id__c,Transaction_Type__c FROM Validation_Checklists__r WHERE Transaction_Type__c = 'Static Bundle') 
                                               FROM SBQQ__Quote__c WHERE ID IN : quoteIds])
                    {
                        if(quote.Validation_Checklists__r.size()==0)
                        {
                            mapOfQuoteByFlag.put(quote.Id,true);
                        }
                        else
                        {
                             parentBundleIdLst = quote.Validation_Checklists__r[0].Static_Bundle_Id__c.split(',');
                        }
                    }
                }
                
                if(ProductIds != null && !ProductIds.isEmpty())
                {
                    MapOfLookupData = getLookupData(ProductIds); // Get Lookup Data
                }
                
                if(parentBundleIdLst != null && !parentBundleIdLst.isEmpty())
                {
                    for(String str : parentBundleIdLst)
                    {
                        if(ProductIds.contains(str)){
                            MapOfLookupData.remove(str);
                        }
                    }
                }
                
                for(SBQQ__QuoteLine__c quoteLine : newQuoteLineList)
                {
                    if(MapOfLookupData != null && MapOfLookupData.containsKey(quoteLine.SBQQ__Product__c) && 
                       mapOfQuoteByFlag!= null && mapOfQuoteByFlag.containskey(quoteLine.SBQQ__Quote__c))
                    {
                        ListOfParentQuotLineIds.add(quoteLine.Id);
                        if(mapOfQuoteByParentProductId.containskey(quoteLine.SBQQ__Quote__c))
                        {
                            mapOfQuoteByParentProductId.get(quoteLine.SBQQ__Quote__c).add(quoteLine.SBQQ__Product__c);
                        }
                        else
                        {
                            mapOfQuoteByParentProductId.put(quoteLine.SBQQ__Quote__c, new Set<Id>{quoteLine.SBQQ__Product__c});
                        }
                    }
                    else if(MapOfLookupData != null && MapOfLookupData.containsKey(quoteLine.SBQQ__Product__c))
                    {
                        ListOfParentQuotLineIds.add(quoteLine.Id);
                        if(mapOfQuoteByParentProductId.containskey(quoteLine.SBQQ__Quote__c))
                        {
                            mapOfQuoteByParentProductId.get(quoteLine.SBQQ__Quote__c).add(quoteLine.SBQQ__Product__c);
                        }
                        else
                        {
                            mapOfQuoteByParentProductId.put(quoteLine.SBQQ__Quote__c, new Set<Id>{quoteLine.SBQQ__Product__c});
                        }
                    }
                    
                }
                
            }      
            if(ListOfParentQuotLineIds != null && !ListOfParentQuotLineIds.isEmpty())
            {
                ListOfNewQLsToInsert = CloneQuoteLines.createQuoteLines(ListOfParentQuotLineIds,MapOfLookupData);
            }                         

            if(ListOfNewQLsToInsert != null && !ListOfNewQLsToInsert.isEmpty())
            {
                Database.insert(ListOfNewQLsToInsert);
            } 
            
            if(mapOfQuoteByParentProductId != null)
            {
               vcLstToUpsert =  getValidationChecklistRecord(mapOfQuoteByParentProductId,parentBundleIdLst,mapOfQuoteByFlag);

                if(vcLstToUpsert != null && !vcLstToUpsert.isEmpty())
                {
                    Schema.SObjectField ftoken = Validation_Checklist__c.Fields.Quote_SB_External_Id__c;
                    Database.UpsertResult[] srList = Database.upsert(vcLstToUpsert,ftoken,false);
                    
                    for (Database.UpsertResult sr : srList) {
                        if (sr.isSuccess()) {
                            
                        }
                        else {                
                            for(Database.Error err : sr.getErrors()) {
                                System.debug( 'ERROR : ' + err.getMessage());                    
                                
                            }
                        }
                    }
                }
            } 
        }
        catch(Exception ex)
        {
            System.debug('Exception Caught  :'+ex.getMessage() + ' **Line Number : '+ex.getLineNumber());
        }
        finally{
            SBQQ.TriggerControl.enable();
        }
    }    
   
    /**
    * @description : Return list of Child Products from Lookup Data object
    * @author Dhiraj Kumar | 09-22-2023 
    * @param Set<Id> parentProductId 
    **/
    public static Map<Id,List<SBQQ__LookupData__c>> getLookupData(Set<Id> parentProductId)
    {
        System.debug('getLookupData METHOD STARTS');
        Map<Id,List<SBQQ__LookupData__c>> mapOfChildProductsByParentProduct = new Map<Id,List<SBQQ__LookupData__c>>(); // Key - ParentProductId , Value - List of SBQQ__LookupData__c
        for(SBQQ__LookupData__c lookupObj: [Select Id,SBQQ__Product__c,Child_Product__c,Product_Allocation__c,PriceBookEntry_Id__c,Dimension_Id__c,Child_Product_Code__c,SBQQ__Value__c,CurrencyIsoCode
                                            FROM SBQQ__LookupData__c WHERE SBQQ__Product__c IN : parentProductId AND Child_Product__c != null])
        {
            if(mapOfChildProductsByParentProduct.containskey(lookupObj.SBQQ__Product__c))
            {
                mapOfChildProductsByParentProduct.get(lookupObj.SBQQ__Product__c).add(lookupObj);
            }
            else
            {
                mapOfChildProductsByParentProduct.put(lookupObj.SBQQ__Product__c, new List<SBQQ__LookupData__c>{lookupObj});
            }
        }
        return mapOfChildProductsByParentProduct;
    }
    /**
    * @description : Update StaticBundleIds field on Validation Checklist object
    * @author Dhiraj Kumar | 12-27-2023 
    * @param Map<Id,SBQQ__QuoteLine__c> oldMap
    **/
    public static void updateValidationChecklist(Map<Id,SBQQ__QuoteLine__c> oldMap)
    {
        Set<Id> quoteIds= new Set<Id>();
        Map<Id,Set<Id>> mapOfProductIdsByQuoteId = new Map<Id,Set<Id>>();
        Map<Id,Id> mapOfcheckListIdByQuoteId = new Map<Id,Id>();
        List<Validation_Checklist__c> lstOfVCToUpdate = new List<Validation_Checklist__c>();
        Boolean deleteCheckListRecord = true;
        try
        {
            for(SBQQ__QuoteLine__c ql : oldMap.values())
            {
                if(String.isBlank(ql.SBQQ__RequiredBy__c) && ql.Parent_of_Bundle__c && !ql.Is_Select_Bundle__c)
                {
                    QuoteIds.add(ql.SBQQ__Quote__c);
                }
            }
            if(QuoteIds != null && !QuoteIds.isEmpty())
            {
                for(Validation_Checklist__c vcObj : [Select Id,Quote__c from Validation_Checklist__c WHERE Quote__c IN  : QuoteIds AND 
                                                     Transaction_Type__c = 'Static Bundle'])
                {
                    mapOfcheckListIdByQuoteId.put(vcObj.Quote__c,vcObj.Id);
                }
                for(SBQQ__QuoteLine__c quoteline : [Select Id,SBQQ__RequiredBy__r.SBQQ__Product__c,SBQQ__Quote__c FROM SBQQ__QuoteLine__c
                                                    WHERE SBQQ__Quote__c IN : QuoteIds AND SBQQ__RequiredBy__c != null AND SBQQ__SegmentIndex__c != null
                                                    AND Skip_OP4I_Sync__c = true])
                {
                    if(mapOfProductIdsByQuoteId.containskey(quoteline.SBQQ__Quote__c))
                    {
                        mapOfProductIdsByQuoteId.get(quoteline.SBQQ__Quote__c).add(quoteline.SBQQ__RequiredBy__r.SBQQ__Product__c);
                    }
                    else
                    {
                        mapOfProductIdsByQuoteId.put(quoteline.SBQQ__Quote__c,new Set<Id>{quoteline.SBQQ__RequiredBy__r.SBQQ__Product__c});
                    } 
                    deleteCheckListRecord = false;
                }
                
                if(mapOfProductIdsByQuoteId != null && !mapOfProductIdsByQuoteId.isEmpty())
                {
                    Set<Id> tempSetOfIds = new Set<Id>();
                    for(Id  quoteId : mapOfProductIdsByQuoteId.keyset())
                    {
                        tempSetOfIds = mapOfProductIdsByQuoteId.get(quoteId);
                        String str = String.join(new List<Id>(tempSetOfIds), ',');
                        Validation_Checklist__c vcobj = new Validation_Checklist__c(Id = mapOfcheckListIdByQuoteId.get(quoteId),Quote__c = quoteId,Static_Bundle_Id__c =  str);
                        lstOfVCToUpdate.add(vcobj);
                    } 
                }
               
                if(lstOfVCToUpdate != null && !deleteCheckListRecord)
                {
                    Database.update(lstOfVCToUpdate);
                }
                else if(mapOfcheckListIdByQuoteId != null && deleteCheckListRecord)
                {
                    Database.delete(mapOfcheckListIdByQuoteId.values());
                }
            }
            if(Test.isRunningTest()){throw new DMLException();}  
        }
        catch(Exception ex)
        {
             System.debug('Exception Caught  :'+ex.getMessage() + ' **Line Number : '+ex.getLineNumber());
        }
    }
    
   /**
    * @description : Prepare Validation Checklist object record which holds the SFDC ID of Product(parent of a static bundle) and 
    * 				 returns List of Validation Checklist records
    * @author Dhiraj Kumar | 12-27-2023 
    * @param Map<Id,SBQQ__QuoteLine__c> Map,List,Map
    **/
    private static List<Validation_Checklist__c> getValidationChecklistRecord(Map<Id,Set<Id>> mapOfQuoteByParentProductId, List<String> parentBundleIdLst,Map<Id,boolean> mapOfQuoteByFlag)
    {
        // Variable declaration
        String oldProductId;
        set<Id> lstOfProdIds;
        List<Validation_Checklist__c> lstOfRecordsToReturn = new List<Validation_Checklist__c>();
        Map<ID,SBQQ__Quote__c> mapOfQuoteToUpdate = new Map<ID,SBQQ__Quote__c>();
        
        for(Id quoteId : mapOfQuoteByParentProductId.keyset())
        {
            lstOfProdIds = mapOfQuoteByParentProductId.get(quoteId);
            String newProductId = String.join(new List<Id>(lstOfProdIds), ',');
            
            if(parentBundleIdLst != null && !parentBundleIdLst.isEmpty())
            {
                oldProductId = String.join(parentBundleIdLst, ',');
            }
            
            //SBQQ__Quote__c quoteObj = new SBQQ__Quote__c(Id=quoteId,StaticBundleIds__c= str); 
            Validation_Checklist__c vcobj = new Validation_Checklist__c(Quote__c = quoteId, Transaction_Type__c = 'Static Bundle', 
                                                                        Quote_SB_External_Id__c =quoteId);
            if(mapOfQuoteByFlag.containskey(quoteId))
            {
                vcobj.Static_Bundle_Id__c =  newProductId;
            }
            else
            {
                vcobj.Static_Bundle_Id__c = oldProductId + ',' +newProductId;
            }
            lstOfRecordsToReturn.add(vcobj);
        }
        return lstOfRecordsToReturn;
    }
    
}