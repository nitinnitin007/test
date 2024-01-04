global class QuoteLinesMigrationBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id,Processing_Status__c FROM Contract WHERE Processing_Status__c = \'Quote Created\'';
        return Database.getQueryLocator(query);        
    }

    global void execute(Database.BatchableContext bc, List<Contract> lstOfContracts){
        List<OP4I_Entitlement_View__c> lstOfEntitlementRecords = new List<OP4I_Entitlement_View__c>();
        List<SBQQ__QuoteLine__c> lstOfQuoteLinesToInsert = new List<SBQQ__QuoteLine__c>();
        List<OP4I_Entitlement_View__c> lstOfEntitlementRecordsUpd = new List<OP4I_Entitlement_View__c>(); 
        Map<String,SBQQ__QuoteLine__c> mapOfContractToQuoteLineCreate = new Map<String,SBQQ__QuoteLine__c>();
        List<Contract> lstOfContractsToUpdate = new List<Contract>();
        Map<string,Id> productPricbookEntryMap = new Map<String,Id>();
        Set<id> productIds = new set<id>();
        set<id> priceBookIds = new set<id>(); 
        set<string> currencySet = new set<string>();
        if(!lstOfContracts.IsEmpty()){
            lstOfEntitlementRecords = [SELECT Id,DLIP_Id__c,Account__c,Quote__c,Quote__r.SBQQ__PriceBook__c,
                                    Quantity__c,Quote__r.CurrencyIsoCode,Start_Date__c,End_Date__c,Associated_OSA__c,
                                    Account__r.Name,Associated_OSA__r.ContractNumber,Opportunity__c,Processing_Status__c,
                                    DLI_Product__c,Sale_Price__c,Meter_Type__c,Segment_Index__c,Associated_OSA__r.Migration_Status__c,
                                    Associated_OSA__r.Processing_Status__c,DLI_Product__r.SBQQ__ChargeType__c,DLI_Product__r.SBQQ__BillingType__c 
                                    FROM OP4I_Entitlement_View__c WHERE Associated_OSA__c IN: lstOfContracts];
          if(!lstOfEntitlementRecords.IsEmpty()){                                   
            for(OP4I_Entitlement_View__c entitlement : lstOfEntitlementRecords){ 
                priceBookIds.add(entitlement.Quote__r.SBQQ__PriceBook__c);     
                currencySet.add(entitlement.Quote__r.CurrencyIsoCode);
                productIds.add(entitlement.DLI_Product__c); 
            }
          }         
        }

        for(PriceBookEntry priceEntry : [Select Id,Pricebook2Id,Product2Id,Pricebook2.Name,CurrencyIsoCode 
            FROM PriceBookEntry 
           WHERE Product2Id IN: productIds AND Pricebook2Id IN: priceBookIds
        ]){
            productPricbookEntryMap.put(priceEntry.Product2Id + '-' +priceEntry.Pricebook2Id + '-' +priceEntry.CurrencyIsoCode, priceEntry.Id);
        }

        system.debug('currencySet--->'+currencySet);
        system.debug('priceBookIds--->'+priceBookIds);
        system.debug('productIds--->'+productIds);
        Map<string,Id> dimentionMap = new Map<string,Id>();
        for (SBQQ__Dimension__c  dimention : [
            Select id,CurrencyIsoCode, SBQQ__PriceBook__c, SBQQ__Product__c from SBQQ__Dimension__c 
            WHERE CurrencyIsoCode IN :currencySet AND SBQQ__Product__c IN :productIds
        ]) {
            string key = dimention.CurrencyIsoCode + dimention.SBQQ__Product__c;
            system.debug('key--->'+key);
            dimentionMap.put(key, dimention.Id);
        }

        for(OP4I_Entitlement_View__c entitlement : lstOfEntitlementRecords){ 
            SBQQ__QuoteLine__c migrateQuoteLine = createQuoteLine(entitlement,
                productPricbookEntryMap,dimentionMap
            );
            mapOfContractToQuoteLineCreate.put(entitlement.Associated_OSA__c,migrateQuoteLine);         
            lstOfQuoteLinesToInsert.add(migrateQuoteLine);
            entitlement.Processing_Status__c = 'Quote Line Created';
            entitlement.Associated_OSA__r.Processing_Status__c = 'Quote Line Created';
            lstOfEntitlementRecordsUpd.add(entitlement);
            if(!lstOfContractsToUpdate.contains(entitlement.Associated_OSA__r))
            {
            lstOfContractsToUpdate.add(entitlement.Associated_OSA__r);
            }
        }

        if(!lstOfQuoteLinesToInsert.IsEmpty())
        { 
           insertQuoteLinesAndEntitlement(lstOfQuoteLinesToInsert,lstOfEntitlementRecordsUpd,mapOfContractToQuoteLineCreate);
        }
        
        if(!lstOfContractsToUpdate.IsEmpty())
        {
          update lstOfContractsToUpdate;
        }           
    }

    global void finish(Database.BatchableContext bc){
       
    }
    
    global static SBQQ__QuoteLine__c createQuoteLine(OP4I_Entitlement_View__c entitlement ,
                                                     map<string,Id> productPricbookEntryMap,Map<string,Id> dimentionMap)
    {
        SBQQ__QuoteLine__c quoteLineMigration = new SBQQ__QuoteLine__c();
        quoteLineMigration.SBQQ__Quote__c = entitlement.Quote__c;
        quoteLineMigration.SBQQ__Quantity__c = entitlement.Quantity__c;
        quoteLineMigration.SolutionQuantity__c = entitlement.Quantity__c;
        quoteLineMigration.SBQQ__ListPrice__c = entitlement.Sale_Price__c;
        quoteLineMigration.Meter_Type__c = entitlement.Meter_Type__c;
        quoteLineMigration.SBQQ__StartDate__c = entitlement.Start_Date__c;
        quoteLineMigration.SBQQ__EndDate__c = entitlement.End_Date__c;
        quoteLineMigration.SBQQ__Product__c = entitlement.DLI_Product__c;
        if(quoteLineMigration.SBQQ__ChargeType__c == null)
        {
          quoteLineMigration.SBQQ__ChargeType__c = entitlement.DLI_Product__r.SBQQ__ChargeType__c;  
        }
         if(quoteLineMigration.SBQQ__BillingType__c == null)
        {
          quoteLineMigration.SBQQ__BillingType__c = entitlement.DLI_Product__r.SBQQ__BillingType__c;    
        }
        quoteLineMigration.Price_Book__c = entitlement.Quote__r.SBQQ__PriceBook__c;
        quoteLineMigration.SBQQ__SegmentIndex__c = entitlement.Segment_Index__c;
        quoteLineMigration.SBQQ__SegmentLabel__c = 'Year ' + entitlement.Segment_Index__c;
        
        quoteLineMigration.CurrencyIsoCode = entitlement.Quote__r.CurrencyIsoCode;
        //quoteLineMigration.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        quoteLineMigration.SBQQ__PricebookEntryId__c = productPricbookEntryMap.get(quoteLineMigration.SBQQ__Product__c + '-' + quoteLineMigration.Price_Book__c + '-' + quoteLineMigration.CurrencyIsoCode);
        system.debug('quoteLineMigration.SBQQ__SegmentIndex__c--->'+quoteLineMigration.SBQQ__SegmentIndex__c);
        if (quoteLineMigration.SBQQ__SegmentIndex__c != null) {
            string key = quoteLineMigration.CurrencyIsoCode+quoteLineMigration.SBQQ__Product__c;
            system.debug('key 2--->'+key);
            system.debug('dimentionMap.get(key)--->'+dimentionMap.get(key));
            quoteLineMigration.SBQQ__Dimension__c = dimentionMap.get(key);
            quoteLineMigration.SBQQ__SegmentKey__c = quoteLineMigration.SBQQ__Dimension__c;
        }
        
        return quoteLineMigration;  
    }
    
    
    global static void insertQuoteLinesAndEntitlement(List<SBQQ__QuoteLine__c> lstOfQuoteLinesToInsert,List<OP4I_Entitlement_View__c> lstOfEntitlementRecordsUpd,Map<String,SBQQ__QuoteLine__c> mapOfContractToQuoteLineCreate)
    {
        Database.SaveResult[] quoteLinesToInsert = Database.insert(lstOfQuoteLinesToInsert, false); 
        HandleCustomException.logDatabaseErrorsForEntitlements(quoteLinesToInsert,mapOfContractToQuoteLineCreate);
        
        Database.SaveResult[] entitlementListOpp = Database.update(lstOfEntitlementRecordsUpd, false);
        HandleCustomException.logDatabaseErrors(entitlementListOpp);
    }
}