/*
Trigger on Opportunity Products (after insert/update/delete) to Create or update Opportunity Product Component records based on 
Product ACV splits
Do the following only if Opportunity is not Closed-
- For each Opp product, get "ACV allocations" from product's Item Master 
- Split List Price and Sales Price on Opp Products per ACV allocations split
- Create an "Opportunity Product Component" for each ACV allocation/Product line with its split amounts. 
Populate Opportunity, Product Line, and Amount fields on the new records. 
Set currency to the currency of Opp product. 
If a Component record exists for a given Product Line then update the amounts
- If ACV allocations are not defined then skip the process (make sure existing records are not deleted if we follow delete/recreate approach)
*/
public class OpportunityProductTriggerHandler {
    public static void afterInsert(List<OpportunityLineItem> lstOLI) {
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityLineItem oli : lstOli) {
            oppIds.add(oli.OpportunityId);
        }
        recalculateOppProdComponents(oppIds);
        opportunityProductEventafterInsert(lstOLI);
    }
    
    public static void afterUpdate(List<OpportunityLineItem> lstOLI, Map<Id, OpportunityLineItem> oldMap) {
        //createOppProdComponent(lstOLI, oldMap);
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityLineItem oli : lstOli) {
            if (isNewOrChanged(oli, 'ListPrice', oldMap) || isNewOrChanged(oli, 'UnitPrice', oldMap) 
                || isNewOrChanged(oli, 'Customer_List_Price__c', oldMap) 
                || isNewOrChanged(oli, 'Quantity', oldMap)
                || isNewOrChanged(oli, 'CurrencyIsoCode', oldMap)
                || isNewOrChanged(oli, 'TotalPrice', oldMap)
                || isNewOrChanged(oli, 'CPI__c', oldMap)
                || isNewOrChanged(oli, 'Recurring_Amount_Change__c', oldMap)
                || isNewOrChanged(oli, 'Recurring_Adjustment__c', oldMap)
                || isNewOrChanged(oli, 'Active__c', oldMap)
               ) {
                   oppIds.add(oli.OpportunityId);
               }
        }
        recalculateOppProdComponents(oppIds);
        opportunityProductEventafterUpdate(lstOLI,oldMap);
    }
    
    public static void afterDelete(List<OpportunityLineItem> lstOLI) {
        //deleteOppProdComponent(lstOLI);
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityLineItem oli : lstOli) {
            oppIds.add(oli.OpportunityId);
        }
        recalculateOppProdComponents(oppIds);
        opportunityProductEventafterDelete(lstOLI);
    }
    
    public static void afterUnDelete(List<OpportunityLineItem> lstOLI) {
        //deleteOppProdComponent(lstOLI);
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityLineItem oli : lstOli) {
            oppIds.add(oli.OpportunityId);
        }
        recalculateOppProdComponents(oppIds);
    }
    
    //--------------------------------------------------------------------------------------------------------------------
    // 1. Get all oppLines
    // 2. Get Map<MasterItemId, Allocations>
    // 3. Map<OppId + ProductLine, existingComponentRec>
    // 4. loop oppline check for masterId
    // 4.1 Map<OppId + ProductLine, ListPrice>
    // 4.2 Map<OppId + ProductLine, SalesPrice>
    //--------------------------------------------------------------------------------------------------------------------
    private static void recalculateOppProdComponents (Set<Id> oppIds) {
        // 1. Get all oppLines
        Map<Id, List<OpportunityLineItem>> mapOppAndOli = getOppAndLinesMap(oppIds);
        
        // 2. Get Map<MasterItemId, Allocations>
        Map<Id, List<ACV_Allocation__c>> mapMasterItemIdAndAlloc = new Map<Id, List<ACV_Allocation__c>> ();
        Set<Id> itemMasterIds = new Set<Id>();
        for (List<OpportunityLineItem> lstOli : mapOppAndOli.values()) {
            for (OpportunityLineItem oli : lstOli) {
                if(oli.Active__c)
                    itemMasterIds.add(oli.Item_Master_ID__c);
            }
        }
        Map<Id, Item_Master_Product__c> mapItemMaster = getItemMasterProductMap(itemMasterIds);
        
        // 3. Map<OppId + ProductLine, existingComponentRec>
        Map<String, Opportunity_Product_Component__c> mapOliProdLineAndOppComp = getOppAndCompMap(oppIds);
        
        // 4. loop oppline check for masterId
        Map<String, OpportunityPrductCompWrapper> mapOppAndProdCompWrap = new Map<String, OpportunityPrductCompWrapper> ();
        
        for (Id oppId : mapOppAndOli.keySet()) {
            Opportunity_Product_Component__c opc;
            for (OpportunityLineItem oli : mapOppAndOli.get(oppId)) {
                Id masterItemId = oli.Item_Master_Id__c;
                if (mapItemMaster.containsKey(masterItemId)) {
                    Decimal unitPrice = (oli.quantity * oli.UnitPrice);
                    Decimal listPrice = oli.quantity * oli.ListPrice;
                    //Decimal totalPrice = oli.TotalPrice;
                    //Decimal CPI = oli.CPI__c == null? 0 : oli.CPI__c;
                    Decimal rAC = oli.Recurring_Amount_Change__c == null? 0: oli.Recurring_Amount_Change__c;
                    //Decimal OTC = oli.Recurring_Adjustment__c == null? 0: oli.Recurring_Adjustment__c;
                    
                    //Decimal totalPrice = oli.CPI__c
                    Decimal totalPrice = rAC;
                    
                    Decimal custPrice = 0;
                    if (oli.Customer_List_Price__c != null) {
                        custPrice = oli.quantity * oli.Customer_List_Price__c;
                    }
                    for (ACV_Allocation__c alloc : mapItemMaster.get(masterItemId).ACV_Allocations__r) {
                        String key = oli.OpportunityId + alloc.Product_Line__c;
                        
                        if (!mapOppAndProdCompWrap.containsKey(key)) {
                            if (mapOliProdLineAndOppComp.containsKey(key)) {
                                mapOppAndProdCompWrap.put(key, new OpportunityPrductCompWrapper(oppId, alloc.Product_Line__c, mapOliProdLineAndOppComp.get(key)));
                            } else {
                                mapOppAndProdCompWrap.put(key, new OpportunityPrductCompWrapper(oppId, alloc.Product_Line__c, null));
                            }
                        }
                        opc = mapOppAndProdCompWrap.get(key).opc;
                        if (oli.UnitPrice == null) { oli.UnitPrice = 0;}
                        if (oli.Customer_List_Price__c == null) { oli.Customer_List_Price__c = 0;}
                        
                        opc.CurrencyIsoCode = oli.CurrencyIsoCode;
                        opc.Product_LineNew__c = alloc.Product_LineNew__c;
                        opc.List_Price_Recurring__c += ((alloc.Percent_Allocation__c * listPrice)/100).setScale(2);
                        opc.Recurring_Amount_Change__c += (( totalPrice * alloc.Percent_Allocation__c)/100).setScale(2);
                        opc.Customer_List_Price__c += ((custPrice * alloc.Percent_Allocation__c)/100).setScale(2);
                    }
                }
            }
        }
        
        
        List<Opportunity_Product_Component__c> lstOppProdCompToUpsert = new List<Opportunity_Product_Component__c>();
        for (OpportunityPrductCompWrapper opcWrap : mapOppAndProdCompWrap.values()) {
            lstOppProdCompToUpsert.add(opcWrap.opc);
        }
        if (!lstOppProdCompToUpsert.isEmpty()) {
            upsert lstOppProdCompToUpsert;
        }
        delete [Select id from Opportunity_Product_Component__c where id not in :lstOppProdCompToUpsert AND Opportunity__c in :oppIds];
    }
    
    //--------------------------------------------------------------------------------------------------------------------
    // Wrapper
    //--------------------------------------------------------------------------------------------------------------------
    private class OpportunityPrductCompWrapper {
        Id oppId;
        String productLine;
        Opportunity_Product_Component__c opc;
        public OpportunityPrductCompWrapper(Id oppId, String productLine, Opportunity_Product_Component__c opc) {
            this.oppId = oppId;
            this.productLine = productLine;
            this.opc = opc;
            if (opc == null) {
                this.opc = new Opportunity_Product_Component__c();
            }
            this.opc.Opportunity__c = oppId;
            this.opc.Product_Line__c = productLine;
            this.opc.List_Price_Recurring__c = 0;
            this.opc.Recurring_Amount_Change__c = 0;
            this.opc.Customer_List_Price__c = 0;
        }
    }
    
    //--------------------------------------------------------------------------------------------------------------------
    // Returns List of OppLines related to opportunity
    //--------------------------------------------------------------------------------------------------------------------
    private static Map<String, Opportunity_Product_Component__c> getOppAndCompMap(Set<Id> oppIds) {
        Map<String, Opportunity_Product_Component__c> mapOppProdLineAndComp = new Map<String, Opportunity_Product_Component__c>();
        for(Opportunity_Product_Component__c opc : [Select ID, Opportunity__c, Product_Line__c, Customer_List_Price__c 
                                                    From Opportunity_Product_Component__c 
                                                    where Opportunity__c IN : oppIds]){
                                                        String key = opc.Opportunity__c + '' + opc.Product_Line__c;
                                                        mapOppProdLineAndComp.put(key, opc);
                                                    }
        return mapOppProdLineAndComp;
    }   
    
    
    //--------------------------------------------------------------------------------------------------------------------
    // Returns List of OppLines related to opportunity
    //--------------------------------------------------------------------------------------------------------------------
    private static Map<Id, List<OpportunityLineItem>> getOppAndLinesMap (Set<Id> oppIds) {
        Map<Id, List<OpportunityLineItem>> mapOppAndOli = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : [Select  currencyIsoCode, o.Opportunity.stageName, Active__c, Item_Master_ID__c, listPrice, UnitPrice, Quantity, 
                                        o.PricebookEntry.Product2Id, o.TotalPrice,o.OpportunityId, 
                                        o.PricebookEntryId, Customer_List_Price__c, o.Recurring_Adjustment__c,
                                        o.CPI__c, o.Recurring_Amount_Change__c
                                        From OpportunityLineItem o 
                                        Where OpportunityId in :oppIds]){
                                            //AND Opportunity.IsClosed = false]) {
                                            if (!mapOppAndOli.containsKey(oli.OpportunityId)) {
                                                mapOppAndOli.put(oli.OpportunityId, new List<OpportunityLineItem>());
                                            }
                                            mapOppAndOli.get(oli.OpportunityId).add(oli);
                                        }
        return mapOppAndOli;
    }
    
    //--------------------------------------------------------------------------------------------------------------------
    // Returns List of OppLines related to opportunity
    //--------------------------------------------------------------------------------------------------------------------
    private static Map<Id, Item_Master_Product__c> getItemMasterProductMap (Set<Id> itemMasterIds) {
        return new Map<Id, Item_Master_Product__c> ([
            Select Name, Item_Name__c, Id, Product_Line__c, 
            (   Select ID , Percent_Allocation__c, Product_Line__c, Product_LineNew__c
             From ACV_Allocations__r 
             Where Percent_Allocation__c != null) 
            From Item_Master_Product__c 
            where ID IN :itemMasterIds]);
    }
    
    
    //----------------------------------------------------------------------------------------------------------
    // Returns true if field value is added or changed 
    //----------------------------------------------------------------------------------------------------------
    public static Boolean isNewOrChanged(Sobject obj, String fldName, Map<Id, Sobject> oldMap) {
        if (obj != null && fldName != null && oldMap != null) {
            return ((obj.get(fldName) != oldMap.get((Id)obj.get('id')).get(fldName) ? true : false));
        } 
        return (obj.get(fldName) != null);
    }
    
    public Static void opportunityProductEventafterInsert(list<OpportunityLineItem> oppprodNewList) {
     List<OpportunityLineItem> opportunityItemList = new List<OpportunityLineItem>();
     Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                 .get('Migration_Opportunity').getRecordTypeId();
     set<Id> setOfOli = new set<id>();
     for(OpportunityLineItem oli : oppprodNewList)
     {
       setOfOli.add(oli.id);     
     }
     String strQuery = createQuery(setOfOli);
     List<OpportunityLineItem> lstOfOpportunityItem = Database.query(strQuery);
     for(OpportunityLineItem oppLineItem : lstOfOpportunityItem){
      if(oppLineItem.Opportunity.RecordTypeId != oppRecordTypeId){
        opportunityItemList.add(oppLineItem);  
      }     
     }

     if(opportunityItemList.Size() > 0)
     {
       publishOppLineItemAfterInsert(opportunityItemList);
     }
    }
    
    public Static void opportunityProductEventafterUpdate(list<OpportunityLineItem> oppprodNewList,Map<Id,OpportunityLineItem> oppprod) {
     List<OpportunityLineItem> opportunityItemList = new List<OpportunityLineItem>();
     Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                 .get('Migration_Opportunity').getRecordTypeId();
     set<Id> setOfOli = new set<id>();
     for(OpportunityLineItem oli : oppprodNewList)
     {
       setOfOli.add(oli.id);     
     }
     String strQuery = createQuery(setOfOli);
     List<OpportunityLineItem> lstOfOpportunityItem = Database.query(strQuery);
     for(OpportunityLineItem oppLineItem : lstOfOpportunityItem){
      if(oppLineItem.Opportunity.RecordTypeId != oppRecordTypeId){
        opportunityItemList.add(oppLineItem);  
      }     
     }

     if(opportunityItemList.Size() > 0)
     {
      publishOppLineItemOnUpdate(opportunityItemList,oppprod);
     }
    } 
    
    public Static void opportunityProductEventafterDelete(list<OpportunityLineItem> oppprodOldList) {
     List<OpportunityLineItem> opportunityItemList = new List<OpportunityLineItem>();
     Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                 .get('Migration_Opportunity').getRecordTypeId();
     set<Id> setOfOli = new set<id>();
     for(OpportunityLineItem oli : oppprodOldList)
     {
       setOfOli.add(oli.id);     
     }
     String strQuery = createQuery(setOfOli);
     List<OpportunityLineItem> lstOfOpportunityItem = Database.query(strQuery);
     for(OpportunityLineItem oppLineItem : lstOfOpportunityItem){
      if(oppLineItem.Opportunity.RecordTypeId != oppRecordTypeId){
        opportunityItemList.add(oppLineItem);  
      }     
     }

     if(opportunityItemList.Size() > 0)
     {
      IntegrationUtility.publishsObjectRecords(opportunityItemList,'OpportunityLineItem','Delete');
     }
    }
    
    public Static void publishOppLineItemAfterInsert(list<OpportunityLineItem> oppprodNewList) {
      if(!oppprodNewList.IsEmpty())
      {
        try{
            Map<string,set<id>> mapOfParentToChildQli = new Map<string,set<id>>();
            set<id> lstOfQliChild = new set<id>();
            set<id> setOfOliIds = new set<id>();
            set<id> setOfQliIds = new set<id>();
            set<id> setOfOliIdsChild = new set<id>();
            set<id> setToPublishParent = new set<id>();
            set<id> setOfIndependentOli = new set<id>();
            for(OpportunityLineItem oli : oppprodNewList)
            {
             setOfOliIds.add(oli.Id);
             setOfQliIds.add(oli.SBQQ__QuoteLine__c);
            }
            List<OpportunityLineItem> lstOfOpportunityProducts  = getListOfOppProducts(setOfOliIds);  
            
            if(!lstOfOpportunityProducts.IsEmpty())
            {
              for(OpportunityLineItem oli : lstOfOpportunityProducts)
              {
               if(oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c!=null)
               {
                if(mapOfParentToChildQli!=null && mapOfParentToChildQli.containskey(oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c))
                {
                  mapOfParentToChildQli.get(oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c).add(oli.SBQQ__QuoteLine__c);  
                }
                else
                {
                  mapOfParentToChildQli.put(oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c,new set<Id>{oli.SBQQ__QuoteLine__c});
                }
               }
               else
               {
                mapOfParentToChildQli.put('string', new set<Id>{}); 
                setOfIndependentOli.add(oli.Id); 
               }
              }
            }

            if(!mapOfParentToChildQli.IsEmpty())
            {
               for(OpportunityLineItem oli : lstOfOpportunityProducts)
               {
                 if(mapOfParentToChildQli.containskey(oli.SBQQ__QuoteLine__c))
                 {
                   if(oli.Product_Name__c!='Intapp Select Bundle' && oli.Product_Name__c!='Intapp Legacy Bundle')
                   {
                     setToPublishParent.add(oli.Id); 
                   }
                   else
                   {
                     lstOfQliChild.addall(mapOfParentToChildQli.get(oli.SBQQ__QuoteLine__c));
                   }                   
                 }
               }     
            }

            if(!lstOfQliChild.IsEmpty())
            {
             setOfOliIdsChild = quoteLinePublishIds(lstOfQliChild);
            }
 
            publishOppLineItemInsert(setOfIndependentOli,setToPublishParent,setOfOliIdsChild,null);
            
        }
        catch(Exception exceptn)
        {
          HandleCustomException.logException(exceptn);
        }
      } 
    }
    
    public Static void publishOppLineItemOnUpdate(list<OpportunityLineItem> oppprodNewList,Map<Id,OpportunityLineItem> oppprod) {
    if(!oppprodNewList.IsEmpty())
      {
            Map<string,string> mapOfChidlToParentQli = new Map<string,string>();
            Map<string,List<SBQQ__QuoteLine__c>> mapOfParentToChildQli = new Map<string,List<SBQQ__QuoteLine__c>>();
            List<SBQQ__QuoteLine__c> qliIdsToChild = new List<SBQQ__QuoteLine__c>();            
            set<id> setOfOliIds = new set<Id>();
            set<id> setOfOppIds = new set<Id>();
            set<id> setOfQliIdsNew = new set<Id>();
            set<id> setOfOliIdsParentNew = new set<id>();
            set<id> setOfQliIdsChildNew = new set<id>();
            set<id> setOfQliIdsIndependnt = new set<id>();
            for(OpportunityLineItem oli : oppprodNewList)
            {
             setOfOliIds.add(oli.Id);
             setOfOppIds.add(oli.OpportunityId);
            }
            List<OpportunityLineItem> lstOfOpportunityProducts  = getListOfOppProducts(setOfOliIds);            
              for(OpportunityLineItem oli : lstOfOpportunityProducts){
                if(oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c!=null)
                mapOfChidlToParentQli.put(oli.SBQQ__QuoteLine__c,oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c);
                else
                setOfQliIdsNew.add(oli.SBQQ__QuoteLine__c);   
              } 
              
              if(setOfQliIdsNew!=null)
              {
                List<SBQQ__QuoteLine__c>lstOfQuoteLines = [Select Id,SBQQ__RequiredBy__c FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c IN: setOfQliIdsNew];
                if(lstOfQuoteLines.size()>0){
                mapOfParentToChildQli = setOfMapOfQuotelines(lstOfQuoteLines);           
                }
                List<SBQQ__QuoteLine__c>lstOfQuoteLinesInpndnt = [Select Id,SBQQ__RequiredBy__c FROM SBQQ__QuoteLine__c WHERE Id IN: setOfQliIdsNew];
                if(lstOfQuoteLinesInpndnt.size()>0){
                  setOfQliIdsIndependnt = getSetOfIndependentOli(lstOfQuoteLinesInpndnt,mapOfParentToChildQli);
                }
              } 
              
              if(mapOfChidlToParentQli.keyset().size()>0){
                for(OpportunityLineItem oli : lstOfOpportunityProducts){
                  if(mapOfChidlToParentQli.containskey(oli.SBQQ__QuoteLine__c) && oli.Product_Name__c!='Intapp Select Bundle' && oli.Product_Name__c!='Intapp Legacy Bundle')
                   setOfOliIdsParentNew.add(mapOfChidlToParentQli.get(oli.SBQQ__QuoteLine__c)); 
                  else If(mapOfChidlToParentQli.containskey(oli.SBQQ__QuoteLine__c) && (oli.Product_Name__c=='Intapp Select Bundle' || oli.Product_Name__c=='Intapp Legacy Bundle'))
                   setOfQliIdsChildNew.add(oli.SBQQ__QuoteLine__c);                      
                  }
              }

              if(setOfQliIdsChildNew.size()>0)
              {               
              qliIdsToChild= [Select Id FROM SBQQ__QuoteLine__c WHERE ID IN: setOfQliIdsChildNew];
              }
              if(mapOfParentToChildQli.keyset().size()>0){
                for(OpportunityLineItem oli : lstOfOpportunityProducts){
                  if(mapOfParentToChildQli.containskey(oli.SBQQ__QuoteLine__c) && oli.Product_Name__c!='Intapp Select Bundle' && oli.Product_Name__c!='Intapp Legacy Bundle')
                   setOfOliIdsParentNew.add(oli.SBQQ__QuoteLine__c); 
                  else if(mapOfParentToChildQli.containskey(oli.SBQQ__QuoteLine__c) && (oli.Product_Name__c=='Intapp Select Bundle' || oli.Product_Name__c=='Intapp Legacy Bundle'))
                   qliIdsToChild.addall(mapOfParentToChildQli.get(oli.SBQQ__QuoteLine__c));                     
                  }
              }             
              set<id> setOfOliIdsParentChild = setOliIds(qliIdsToChild,setOfOliIdsParentNew,setOfQliIdsIndependnt,setOfOppIds);              
              publishOppLineItemInsert(setOfOliIdsParentChild,null,null,oppprod);  
      }  
   }
   
   public Static void publishOppLineItemInsert(set<Id> setOfIndependentOli,set<Id> setToPublishParent,set<Id> setOfOliIdsChild,Map<Id,OpportunityLineItem> oppprod) {
    set<id> setOfFinalIds = new set<id>();
    List<OpportunityLineItem> finalOliListToPublish = new List<OpportunityLineItem>();
    if(setOfIndependentOli!=null)
    {
      setOfFinalIds.addall(setOfIndependentOli);
    }
     if(setToPublishParent!=null)
    {
      setOfFinalIds.addall(setToPublishParent);
    }
     if(setOfOliIdsChild!=null)
    {
      setOfFinalIds.addall(setOfOliIdsChild);
    }
     if(setOfFinalIds!=null)
    {
      String strQuery = createQuery(setOfFinalIds);
      String strQueryUpd = strQuery.replace('setOfOli' , 'setOfFinalIds');
      finalOliListToPublish = Database.query(strQueryUpd);
    }
    if(!finalOliListToPublish.IsEmpty())
    {
        if(oppprod==null)
        IntegrationUtility.publishsObjectRecords(finalOliListToPublish,'OpportunityLineItem');  
        else
        IntegrationUtility.publishEligibleSobjectRecords(finalOliListToPublish,oppprod,'OpportunityLineItem');         
    }   
         
   }
   
    public static Set<id> quoteLinePublishIds(set<id> lstOfQliChild){
      set<id> setOfOliIdsChild = new set<id>();
      set<id> setOfChildQli = new set<id>();
      if(!lstOfQliChild.IsEmpty())
      {
        List<OpportunityLineItem> lstOfOppLineItemsChild = [Select Id,SBQQ__QuoteLine__c,Product_Name__c,SBQQ__QuoteLine__r.SBQQ__RequiredBy__c FROM OpportunityLineItem WHERE SBQQ__QuoteLine__c IN: lstOfQliChild AND Skip_OP4I_Sync__c = false];
        if(!lstOfOppLineItemsChild.IsEmpty())
        {
          for(OpportunityLineItem oliObj : lstOfOppLineItemsChild)
          {
            setOfOliIdsChild.add(oliObj.id);  
          }                    
        }
      } 
      return setOfOliIdsChild;    
    }
    
    public static Map<string,List<SBQQ__QuoteLine__c>> setOfMapOfQuotelines(List<SBQQ__QuoteLine__c> lstOfQuoteLines){
      Map<string,List<SBQQ__QuoteLine__c>> mapOfParentToChildQli = new Map<string,List<SBQQ__QuoteLine__c>>();
      if(!lstOfQuoteLines.IsEmpty())
      {
        for(SBQQ__QuoteLine__c qliObj : lstOfQuoteLines)
        {
          if(mapOfParentToChildQli!=null && mapOfParentToChildQli.containskey(qliObj.SBQQ__RequiredBy__c))
          {
            mapOfParentToChildQli.get(qliObj.SBQQ__RequiredBy__c).add(qliObj);  
          }
          else
          {
            mapOfParentToChildQli.put(qliObj.SBQQ__RequiredBy__c,new List<SBQQ__QuoteLine__c>{qliObj});
          }
        }
      } 
      return mapOfParentToChildQli;   
    }
    
    public static Set<id> setOliIds(List<SBQQ__QuoteLine__c> qliIdsToChild,set<id>setOfOliIdsParentNew,set<id>setOfQliIdsIndependnt,set<id>setOfOppIds){
      set<id> setOfQliIdsChildNew = new set<id>();
      set<id> setOfOliIdsParentChild = new set<id>();
      if(!qliIdsToChild.IsEmpty())
      {
        for(SBQQ__QuoteLine__c qli : qliIdsToChild)
        {
          setOfQliIdsChildNew.add(qli.id); 
        }
      }
      List<OpportunityLineItem> lstOfOppLineItemsChild = [Select Id,SBQQ__QuoteLine__c,Product_Name__c,SBQQ__QuoteLine__r.SBQQ__RequiredBy__c FROM OpportunityLineItem WHERE ((SBQQ__QuoteLine__c IN: setOfQliIdsChildNew AND Skip_OP4I_Sync__c = false) OR SBQQ__QuoteLine__c IN: setOfOliIdsParentNew OR SBQQ__QuoteLine__c IN: setOfQliIdsIndependnt) AND OpportunityId IN:setOfOppIds];
      if(!lstOfOppLineItemsChild.IsEmpty())
      {
        for(OpportunityLineItem oliObj : lstOfOppLineItemsChild)
        {
          setOfOliIdsParentChild.add(oliObj.id);  
        }                    
      }
      return setOfOliIdsParentChild;      
    }
    
    public static List<OpportunityLineItem> getListOfOppProducts(set<id> setOfOliIds){
       List<OpportunityLineItem> listOfOppProducts = new List<OpportunityLineItem>();
       listOfOppProducts = [Select Id,SBQQ__QuoteLine__c,SBQQ__QuoteLine__r.SBQQ__RequiredBy__c,
                           Product_Name__c FROM OpportunityLineItem WHERE ID IN: setOfOliIds]; 
       return listOfOppProducts;                                                                   
    }
    
    public static set<Id> setIndependentQLI(List<SBQQ__QuoteLine__c> lstOfQuoteLinesInpndnt,Map<string,List<SBQQ__QuoteLine__c>>  mapOfParentToChildQli){
      set<id> setOfQliIdsIndependnt = new set<id>();
      for(SBQQ__QuoteLine__c qliObj : lstOfQuoteLinesInpndnt)
      {
        if(!mapOfParentToChildQli.containskey(qliObj.id))
        setOfQliIdsIndependnt.add(qliObj.id);    
      } 
      return setOfQliIdsIndependnt;   
    }
    
     public static Set<Id> getSetOfIndependentOli(List<SBQQ__QuoteLine__c> lstOfQuoteLinesInpndnt,Map<string,List<SBQQ__QuoteLine__c>> mapOfParentToChildQli){
        set<id> setOfQliIdsIndependnt = new set<id>();
        for(SBQQ__QuoteLine__c qliobj : lstOfQuoteLinesInpndnt)
        { 
          if(!mapOfParentToChildQli.containskey(qliobj.id))
          {                                              
            setOfQliIdsIndependnt.add(qliobj.id); 
          }
        } 
        return setOfQliIdsIndependnt;       
    }
    
    public static Set<Id> getSetOfChildOli(List<SBQQ__QuoteLine__c> lstOfQuoteLinesInpndnt,Map<string,List<SBQQ__QuoteLine__c>> mapOfParentToChildQli){
        set<id> setOfQliIdsIndependnt = new set<id>();
        for(SBQQ__QuoteLine__c qliobj : lstOfQuoteLinesInpndnt)
        { 
          if(!mapOfParentToChildQli.containskey(qliobj.id))
          {                                              
            setOfQliIdsIndependnt.add(qliobj.id); 
          }
        } 
        return setOfQliIdsIndependnt;       
    }
    
    public static string createQuery(set<Id> setOfOli)
    {
      set<String> fieldNames = new set<String>();
      Schema.SObjectType targetObjType = Schema.getGlobalDescribe().get('OpportunityLineItem');
      Map<String, Schema.SObjectField> fieldMap = targetObjType.getDescribe().fields.getMap();
      fieldNames = fieldMap.keyset();
      List<String> fields = new List<String>(fieldNames);
      String query =  ' SELECT ' +
                              String.join( fields, ',' ) + ',PriceBookEntry.Product2Id' +
                              ',Opportunity.RecordTypeId ' +
                          ' FROM ' +
                              'OpportunityLineItem' +
                          ' WHERE ' +
                              ' Id IN: setOfOli';
                         
      String strQuery1 = query.remove('{');
      String strQuery2 = strQuery1.remove('}'); 
      return strQuery2;
    }       
}