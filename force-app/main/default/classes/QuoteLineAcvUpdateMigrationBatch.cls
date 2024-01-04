global class QuoteLineAcvUpdateMigrationBatch implements Database.Batchable<sObject>,Database.Stateful{
   global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id,Processing_Status__c FROM Contract WHERE Processing_Status__c = \'Child Quote Line Created\''  
                        +' OR Processing_Status__c = \'Parent Quote Line Created\'';  
        return Database.getQueryLocator(query);        
    }
    
    global void execute(Database.BatchableContext bc, List<Contract> lstOfContracts){      
       List<OP4I_Entitlement_View__c> lstOfEntitlements = [Select Id,Associated_OSA__c,Quote__c FROM OP4I_Entitlement_View__c WHERE Associated_OSA__c IN: lstOfContracts];
       set<id> setOfQuoteIds = new set<id>();
       if(!lstOfEntitlements.IsEmpty())
       {
         for(OP4I_Entitlement_View__c entitlemnt : lstOfEntitlements)
         {
           if(entitlemnt.Quote__c != null){
           setOfQuoteIds.add(entitlemnt.Quote__c); 
           }
         }
        if(!setOfQuoteIds.IsEmpty()){
        List<SBQQ__QuoteLine__c> lstOfQuoteLines = [Select Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN: setOfQuoteIds];
        if(!lstOfQuoteLines.IsEmpty()){
        Database.SaveResult[] quoteLineToUpdate = Database.update(lstOfQuoteLines, false);
          for(contract contr : lstOfContracts)
          {
            contr.Processing_Status__c = 'ACV Calculated';
          }
          Database.SaveResult[] contractsToUpdate = Database.update(lstOfContracts, false);           
        }
       }
      }    
    }

    global void finish(Database.BatchableContext bc){
        
    }       
    
}