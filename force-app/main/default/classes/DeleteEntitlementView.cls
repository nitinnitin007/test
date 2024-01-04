global class DeleteEntitlementView implements Database.Batchable<sObject> {
    global set<string> entitlementIds = new set<string>();
    global deleteEntitlementView(set<string> entitlementsToProcess){
       entitlementIds = entitlementsToProcess; 
    }
    global deleteEntitlementView(){
            
    }
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query;
        if(entitlementIds.size()>0)
        {
         query = 'SELECT Id,Opportunity__c,Quote__c,Order__c,Associated_OSA__c,Associated_OSA__r.Processing_Status__c'
                 +',Associated_OSA__r.Migration_Status__c FROM OP4I_Entitlement_View__c '
                 +'Where ID IN: entitlementIds'; 
        }
        else
        {
         query = 'SELECT Id,Opportunity__c,Quote__c,Order__c,Associated_OSA__c,Associated_OSA__r.Processing_Status__c'
                 +',Associated_OSA__r.Migration_Status__c FROM OP4I_Entitlement_View__c';
        }
        return Database.getQueryLocator(query);        
    }
    
    global void execute(Database.BatchableContext bc, List<OP4I_Entitlement_View__c> lstOfEntitlementRecords){
      List<Opportunity> lstOfOpportunity = new List<Opportunity>();
      List<SBQQ__Quote__c> lstOfQuotes = new List<SBQQ__Quote__c>();
      set<id> setOfOpportunityIds = new set<id>();
      set<id> setOfQuoteIds = new set<id>();
      set<id> setOfOrderIds = new set<id>();
      List<SBQQ__QuoteLine__c> lstOfQuoteLines = new List<SBQQ__QuoteLine__c>();
      List<Contract> lstOfContractsToUpdate = new List<Contract>();
      if(!lstOfEntitlementRecords.IsEmpty())
      {
        for(OP4I_Entitlement_View__c entitlement : lstOfEntitlementRecords)
        {
         if(entitlement.Associated_OSA__c!=null)
         {
         entitlement.Associated_OSA__r.Processing_Status__c = '';
         entitlement.Associated_OSA__r.Migration_Status__c = '';
         if(!lstOfContractsToUpdate.contains(entitlement.Associated_OSA__r))
         lstOfContractsToUpdate.add(entitlement.Associated_OSA__r);
         }
         if(entitlement.Quote__c!=null)
         setOfQuoteIds.add(entitlement.Quote__c);
         if(entitlement.Opportunity__c!=null) 
         setOfOpportunityIds.add(entitlement.Opportunity__c);
         if(entitlement.Order__c!=null)  
         setOfOrderIds.add(entitlement.Order__c); 
         entitlement.Processing_Status__c = '';
         entitlement.Migration_Status__c = '';           
        }
        Database.SaveResult[] entitlementListQuote = Database.update(lstOfEntitlementRecords, false);
        Database.SaveResult[] contractsToUpdate = Database.update(lstOfContractsToUpdate, false);
        if(setOfQuoteIds.size()>0)
        {
          lstOfQuoteLines = [Select Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN: setOfQuoteIds];
          lstOfQuotes = [Select Id FROM SBQQ__Quote__c WHERE Id IN: setOfQuoteIds];
        }
        
        if(setOfOpportunityIds.size()>0)
        lstOfOpportunity = [Select Id FROM Opportunity WHERE Id IN: setOfOpportunityIds];
    
        if(setOfOrderIds.size()>0)
        {      
          deleteRecords(setOfOrderIds);  
        }
        
          if(!lstOfQuoteLines.IsEmpty())
          Database.DeleteResult[] quoteLinesDeleteList = Database.delete(lstOfQuoteLines, false);
          
          if(!lstOfQuotes.IsEmpty())
          Database.DeleteResult[] quoteDeleteList = Database.delete(lstOfQuotes, false);
      
          if(!lstOfOpportunity.IsEmpty())
          Database.DeleteResult[] opportunityDeleteList = Database.delete(lstOfOpportunity, false);         
      }
    }

   global void finish(Database.BatchableContext bc){
       
   } 

   global static void deleteRecords( set<id> setOfOrderIds)
   {
      List<Order> lstOfOrderToUpdate = new List<Order>();
      for(Order orderObj : [Select Id FROM ORDER WHERE ID IN: setOfOrderIds])
      {
        orderObj.SBQQ__Quote__c = null;
        orderObj.Status = 'Draft';
        lstOfOrderToUpdate.add(orderObj);
      }
      if(!lstOfOrderToUpdate.IsEmpty())
      {
        Database.SaveResult[] orderUpdateList = Database.update(lstOfOrderToUpdate, false);
      }
      
      List<OrderItem> lstOfOrderLineItems = [Select Id FROM OrderItem WHERE OrderId IN: setOfOrderIds];
      List<Order> lstOfOrdersToUpd = [Select Id FROM Order WHERE Id IN: setOfOrderIds];
      List<Contract> lstOfContracts = [Select Id FROM Contract WHERE SBQQ__Order__c IN: setOfOrderIds];
      
      if(!lstOfContracts.IsEmpty())
      {
      List<SBQQ__Subscription__c> lstOfSubscriptions = [Select Id FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c IN: lstOfContracts];
      if(!lstOfSubscriptions.IsEmpty())
      Database.DeleteResult[] subscriptionDeleteList = Database.delete(lstOfSubscriptions, false); 
  
      Database.DeleteResult[] contractDeleteList = Database.delete(lstOfContracts, false);
      }
      
      if(!lstOfOrderLineItems.IsEmpty())
      Database.DeleteResult[] orderLineItemDeleteList = Database.delete(lstOfOrderLineItems, false);
  
      if(!lstOfOrdersToUpd.IsEmpty())
      Database.DeleteResult[] orderDeleteList = Database.delete(lstOfOrdersToUpd, false);
   }       
}