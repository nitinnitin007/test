global class OrderAndOliMigrationBatch implements Database.Batchable<sObject> {
    List<string> lstOfContractAssignment;
    global OrderAndOliMigrationBatch(List<string> lstOfContractNumbers){
      lstOfContractAssignment = lstOfContractNumbers ;
    }
    global OrderAndOliMigrationBatch() {}

    global Database.QueryLocator start(Database.BatchableContext bc){
        string endCondition;
        if (lstOfContractAssignment != null && !lstOfContractAssignment.isempty()) {
            for (string endDigit : lstOfContractAssignment) {
                endCondition = endCondition != null? (endCondition +  ' OR ContractNumber like \'%' + endDigit + '\'') :' ContractNumber like \'%' + endDigit + '\'';
            }
        } 
        String query = 'SELECT Id,Processing_Status__c FROM Contract WHERE ( Processing_Status__c = \'Child Quote Line Created\''  
                        +' OR Processing_Status__c = \'Parent Quote Line Created\')';            
        query = endCondition != null? query + ' AND (' + endCondition + ')' : query;
        system.debug('Start Query' +query);     
        return Database.getQueryLocator(query);        
    }

    global void execute(Database.BatchableContext bc, List<Contract> lstOfContracts){
        set<id> setOfQuoteIds = new set<id>();
        List<SBQQ__Quote__c> lstOfQuotesToUpdate = new List<SBQQ__Quote__c>();
        List<OP4I_Entitlement_View__c> lstOfEntitlementRecords = new List<OP4I_Entitlement_View__c>();
        List<Contract> lstOfContractsToUpdate = new List<Contract>();
        set<id> setOfQuoteIdsUpd = new set<id>();
        List<OP4I_Entitlement_View__c> lstOfEntitlementRecordsUpd = new List<OP4I_Entitlement_View__c>();
        List<OP4I_Entitlement_View__c> lstOfEntitlementRecordsOrderUpd = new List<OP4I_Entitlement_View__c>();
        Map<String,SBQQ__Quote__c> mapOfContractToQuote = new Map<String,SBQQ__Quote__c>();
        Map<String,String> mapOfQuoteToOrder = new Map<String,String>();  
        if(!lstOfContracts.IsEmpty()) {
            lstOfEntitlementRecords = [SELECT Id,DLIP_Id__c,Account__c,Quote__c,Quote__r.SBQQ__Ordered__c,Quantity__c,
                                        Start_Date__c,End_Date__c,Associated_OSA__c,Account__r.Name,Associated_OSA__r.ContractNumber,
                                        Opportunity__c,Processing_Status__c,Associated_OSA__r.Migration_Status__c,
                                        Associated_OSA__r.Processing_Status__c FROM OP4I_Entitlement_View__c 
                                        WHERE Associated_OSA__c IN: lstOfContracts];
            if(!lstOfEntitlementRecords.IsEmpty()){                                  
                for(OP4I_Entitlement_View__c entitlement : lstOfEntitlementRecords){ 
                    setOfQuoteIds.add(entitlement.Quote__c); 
                }
            }
            List<SBQQ__Quote__c> existingQuotes = [Select Id,Migration_Contract__c,SBQQ__Ordered__c FROM SBQQ__Quote__c WHERE Id IN: setOfQuoteIds];
            
            if(!existingQuotes.IsEmpty())
            {
                for(SBQQ__Quote__c quoteObj : existingQuotes)
                {
                    mapOfContractToQuote.put(quoteObj.Migration_Contract__c , quoteObj);
                }
            }
            
            for(OP4I_Entitlement_View__c entitlement : lstOfEntitlementRecords)
            {             
                if(mapOfContractToQuote.containskey(entitlement.Associated_OSA__c))
                {
                    if(mapOfContractToQuote.get(entitlement.Associated_OSA__c).SBQQ__Ordered__c == false)
                    {
                        mapOfContractToQuote.get(entitlement.Associated_OSA__c).SBQQ__Ordered__c = true; 
                        lstOfQuotesToUpdate.add(mapOfContractToQuote.get(entitlement.Associated_OSA__c));
                        setOfQuoteIdsUpd.add(mapOfContractToQuote.get(entitlement.Associated_OSA__c).id);
                        entitlement.Processing_Status__c = 'Order and OLI created';
                        entitlement.Associated_OSA__r.Processing_Status__c = 'Order and OLI created';
                        lstOfEntitlementRecordsUpd.add(entitlement);
                        if(!lstOfContractsToUpdate.contains(entitlement.Associated_OSA__r))
                        {
                            lstOfContractsToUpdate.add(entitlement.Associated_OSA__r);
                        }
                    }
                    
                    else
                    {
                        entitlement.Processing_Status__c = 'Order and OLI created';
                        entitlement.Associated_OSA__r.Processing_Status__c = 'Order and OLI created';
                        setOfQuoteIdsUpd.add(mapOfContractToQuote.get(entitlement.Associated_OSA__c).id);
                        lstOfEntitlementRecordsUpd.add(entitlement);
                        if(!lstOfContractsToUpdate.contains(entitlement.Associated_OSA__r))
                        {               
                            lstOfContractsToUpdate.add(entitlement.Associated_OSA__r); 
                        }           
                    }  
                }          
            }
            
            if(!lstOfQuotesToUpdate.IsEmpty())
            {
                createOrder(mapOfContractToQuote,lstOfEntitlementRecordsUpd);
            }
        
            List<Order> lstOfOrders = [Select Id,SBQQ__Quote__c FROM ORDER WHERE SBQQ__Quote__c IN: setOfQuoteIdsUpd];
            set<id> setOfOrderIds = new set<id>();
            List<orderItem> lstOfOrderItems = new List<orderItem>();
            if(!lstOfOrders.IsEmpty()) {
                for(order orderObj : lstOfOrders){
                    mapOfQuoteToOrder.put(orderObj.SBQQ__Quote__c , orderObj.Id); 
                }
                
                for(OP4I_Entitlement_View__c entitlmnt : lstOfEntitlementRecordsUpd){
                    if(mapOfQuoteToOrder.containskey(entitlmnt.Quote__c)){
                        entitlmnt.Order__c = mapOfQuoteToOrder.get(entitlmnt.Quote__c);
                        lstOfEntitlementRecordsOrderUpd.add(entitlmnt);
                        setOfOrderIds.add(entitlmnt.Order__c);
                    }               
                }
                lstOfOrderItems = [Select Id,SBQQ__DefaultSubscriptionTerm__c,Product2.SBQQ__SubscriptionTerm__c
                                                FROM OrderItem WHERE OrderId IN: setOfOrderIds];
            }  
            
            if(!lstOfEntitlementRecordsUpd.IsEmpty()){           
                updateEntitlementView(lstOfEntitlementRecordsUpd,lstOfContractsToUpdate,lstOfOrderItems);
            }
                  
        }
    }
  
    global void finish(Database.BatchableContext bc){
        
    }
  
    global static void createOrder( Map<String,SBQQ__Quote__c> mapOfContractToQuote,List<OP4I_Entitlement_View__c> lstOfEntitlementRecordsUpd){
        List<SBQQ__Quote__c> quoteUpdateList = mapOfContractToQuote.values();
        Database.SaveResult[] quoteUpdateResultList = Database.update(quoteUpdateList, false); 
        //HandleCustomException.logDatabaseErrorsForEntitlements(quoteList,mapOfContractToQuote);
        map<string,string> resultMap = HandleCustomException.logMigrationDatabaseError(
            quoteUpdateResultList,
            mapOfContractToQuote,
            'Migration_Contract__c',
            quoteUpdateList
        );

        string keyFields = 'Associated_OSA__c';
        for(OP4I_Entitlement_View__c entitlement : lstOfEntitlementRecordsUpd) {          
                string key = HandleCustomException.getKey(keyFields, entitlement);
                system.debug('key--->'+key);
                if (resultMap.containsKey(key)) {
                    entitlement.Processing_Status__c = 'Order Creation Failed';
                    entitlement.Error_Log__c = resultMap.get(key);
                    entitlement.Associated_OSA__r.Processing_Status__c = 'Order Creation Failed';
                }
        }
    }
  
    global static void updateEntitlementView(List<OP4I_Entitlement_View__c> lstOfEntitlementRecordsOrderUpd,List<Contract> lstOfContractsToUpdate,List<orderItem> lstOfOrderItems){
        Database.SaveResult[] entitlementListQuoteOrder = Database.update(lstOfEntitlementRecordsOrderUpd, false);
        HandleCustomException.logDatabaseErrors(entitlementListQuoteOrder); 
        if(lstOfOrderItems.size()>0) {
            for(orderitem ordritem : lstOfOrderItems){
                if(ordritem.Product2.SBQQ__SubscriptionTerm__c!=null)
                ordritem.SBQQ__DefaultSubscriptionTerm__c = ordritem.Product2.SBQQ__SubscriptionTerm__c;
            }           
            Database.SaveResult[] orderItemUpdateLst = Database.update(lstOfOrderItems, false);
            HandleCustomException.logDatabaseErrors(orderItemUpdateLst);  
        }   
        Database.SaveResult[] contrUpdateLst = Database.update(lstOfContractsToUpdate, false);
        HandleCustomException.logDatabaseErrors(contrUpdateLst);    
    }
}