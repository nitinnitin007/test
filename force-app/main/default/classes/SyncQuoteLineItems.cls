global class SyncQuoteLineItems  {

    webService static String syncLineItems(Id quoteId){
        List<Id> List_QuoteIds = new List<Id>();
        List_QuoteIds.add(quoteId);
        return bulk_syncLineItems(List_QuoteIds);
    }

    /*
    public static String bulk_syncLineItems(List<Id> list_quoteId){
        Map<Id, SBQQ__QuoteLine__c> Map_QuoteLineItems = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, OpportunityLineItem> Map_OpptLineItems = new Map<Id, OpportunityLineItem>();
        Map<Id, Id> Map_OpptId_QuoteId = new Map<Id, Id>();

        List<SBQQ__QuoteLine__c> List_ItemsToDelete = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> List_ItemsToUpsert = new List<SBQQ__QuoteLine__c>();

        for(SBQQ__QuoteLine__c lineItem:[SELECT Id, Id__c, SBQQ__Quantity__c, 
                                                SBQQ__Product__c,
                                                SBQQ__ListPrice__c,
                                                OSA_Gross_Price__c,
                                                SBQQ__SpecialPrice__c,
                                                SBQQ__RegularPrice__c,
                                                SBQQ__ProratedListPrice__c,
                                                Total_Price__c,
                                                SBQQ__CustomerPrice__c,
                                                SBQQ__NetPrice__c,
                                                SBQQ__AdditionalDiscountAmount__c,
                                                SBQQ__AdditionalDiscount__c,
                                                SBQQ__TotalDiscountAmount__c, SBQQ__PricingMethod__c,
                                                SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Opportunity2__c,
                                                SBQQ__SubscriptionScope__c 
                                           FROM SBQQ__QuoteLine__c
                                          WHERE SBQQ__Quote__c in : list_quoteId]){
                
                //Oppt Product Id, Quote Line Item
                if( lineItem.Id__c == null){
                    List_ItemsToDelete.add(lineItem);
                    continue;
                }

                Map_QuoteLineItems.put(lineItem.Id__c, lineItem);
                Map_OpptId_QuoteId.put(lineItem.SBQQ__Quote__r.SBQQ__Opportunity2__c, lineItem.SBQQ__Quote__c);
        }

        for(OpportunityLineItem lineItem:[SELECT Id, Quantity, OpportunityId,
                                                 Product2Id,
                                                 UnitPrice,
                                                 TotalPrice,
                                                 OSA_Discount_Amount__c
                                            FROM OpportunityLineItem
                                           WHERE OpportunityId in : Map_OpptId_QuoteId.keySet()]){
            
                Map_OpptLineItems.put(lineItem.Id, lineItem);
        }

        for(Id OpptItem_Id: Map_QuoteLineItems.keySet()){
            if(!Map_OpptLineItems.containsKey(OpptItem_Id)){
                List_ItemsToDelete.add(Map_QuoteLineItems.get(OpptItem_Id));
                continue;
            }

            OpportunityLineItem oli = Map_OpptLineItems.get(OpptItem_Id);
            SBQQ__QuoteLine__c qli = Map_QuoteLineItems.get(OpptItem_Id);

            List_ItemsToUpsert.add(MapFields(oli, qli, Map_OpptId_QuoteId));
        }

        for(Id OpptItem_Id: Map_OpptLineItems.keySet()){
            if(Map_QuoteLineItems.containsKey(OpptItem_Id)){
                continue;
            }

            OpportunityLineItem oli = Map_OpptLineItems.get(OpptItem_Id);
            SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
            
            List_ItemsToUpsert.add(MapFields(oli, qli, Map_OpptId_QuoteId));
        }

        if(List_ItemsToDelete.size() > 0) delete List_ItemsToDelete;
        if(List_ItemsToUpsert.size() > 0) upsert List_ItemsToUpsert;

        RETURN 'Quote Line Items have been synced';
    }
    */

    public static String bulk_syncLineItems(List<Id> list_quoteId){
        
        List<SBQQ__QuoteLine__c> List_ItemsToDelete = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> List_ItemsToUpsert = new List<SBQQ__QuoteLine__c>();

        Map<Id, List<Id>> Map_OppId_ListQuoteId = new Map<Id, List<Id>>();
        
        Map<String, SBQQ__QuoteLine__c> Map_UniqueString_QuoteLine = new Map<String, SBQQ__QuoteLine__c>();
        Map<String, OpportunityLineItem> Map_UniqueString_OppLine = new Map<String, OpportunityLineItem>();

        for(SBQQ__Quote__c quoteRec: [SELECT Id, SBQQ__Opportunity2__c
                                        FROM SBQQ__Quote__c
                                       WHERE Id in : list_quoteId]){
                if(Map_OppId_ListQuoteId.containsKey(quoteRec.SBQQ__Opportunity2__c)){
                    Map_OppId_ListQuoteId.get(quoteRec.SBQQ__Opportunity2__c).add(quoteRec.Id);
                }
                else{
                    Map_OppId_ListQuoteId.put(quoteRec.SBQQ__Opportunity2__c, new List<Id> {quoteRec.Id});
                }
        }

        for(SBQQ__QuoteLine__c lineItem:[SELECT Id, Id__c, SBQQ__Quantity__c, 
                                                SBQQ__Product__c,
                                                SBQQ__ListPrice__c,
                                                OSA_Gross_Price__c,
                                                SBQQ__SpecialPrice__c,
                                                SBQQ__RegularPrice__c,
                                                SBQQ__ProratedListPrice__c,
                                                Total_Price__c,
                                                SBQQ__CustomerPrice__c,
                                                SBQQ__NetPrice__c,
                                                SBQQ__AdditionalDiscountAmount__c,
                                                SBQQ__AdditionalDiscount__c,
                                                SBQQ__TotalDiscountAmount__c, SBQQ__PricingMethod__c,
                                                SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Opportunity2__c,
                                                SBQQ__SubscriptionScope__c,
                                                CurrencyISOCode 
                                           FROM SBQQ__QuoteLine__c
                                          WHERE SBQQ__Quote__c in : list_quoteId]){
                
                //Oppt Product Id, Quote Line Item
                if( lineItem.Id__c == null){
                    List_ItemsToDelete.add(lineItem);
                    continue;
                }

                Map_UniqueString_QuoteLine.put(lineItem.SBQQ__Quote__c + ':' + lineItem.Id__c, lineItem);
        }


        for(OpportunityLineItem lineItem: [SELECT Id, Quantity, OpportunityId,
                                                 Product2Id,
                                                 UnitPrice,
                                                 TotalPrice,
                                                 OSA_Discount_Amount__c,
                                                 CurrencyISOCode 
                                            FROM OpportunityLineItem
                                           WHERE OpportunityId in : Map_OppId_ListQuoteId.keySet()]){
                
                for(Id QuoteId: Map_OppId_ListQuoteId.get(lineItem.OpportunityId)){
                    Map_UniqueString_OppLine.put(QuoteId + ':' + lineItem.Id, lineItem);
                }
        }

        //For Update and Delete
        for(String UniqueString: Map_UniqueString_QuoteLine.keySet()){
            //To delete surplus line item on the Quote
            if(!Map_UniqueString_OppLine.containsKey(UniqueString)){
                List_ItemsToDelete.add(Map_UniqueString_QuoteLine.get(UniqueString));
                continue;
            }

            //To update the matching QLI
            OpportunityLineItem oli = Map_UniqueString_OppLine.get(UniqueString);
            SBQQ__QuoteLine__c qli = Map_UniqueString_QuoteLine.get(UniqueString);

            List_ItemsToUpsert.add(MapFields(oli, qli, UniqueString.split(':')[0]));
        }

        //For Insert
        for(String UniqueString: Map_UniqueString_OppLine.keySet()){
            if(Map_UniqueString_QuoteLine.containsKey(UniqueString)){
                continue;
            }

            OpportunityLineItem oli = Map_UniqueString_OppLine.get(UniqueString);
            SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
            
            List_ItemsToUpsert.add(MapFields(oli, qli, UniqueString.split(':')[0]));
        }

        if(List_ItemsToDelete.size() > 0) delete List_ItemsToDelete;
        if(List_ItemsToUpsert.size() > 0) upsert List_ItemsToUpsert;

        RETURN 'Quote Line Items have been synced';
    }

    
    public static SBQQ__QuoteLine__c MapFields(OpportunityLineItem oli, SBQQ__QuoteLine__c qli, String QuoteId){
            if(qli.SBQQ__Quote__c == null){
                qli.SBQQ__Quote__c = (Id) QuoteId;
            }

            qli.SBQQ__Quantity__c =  oli.Quantity; 
            
            qli.SBQQ__Product__c =  oli.Product2Id;
            
            qli.SBQQ__ListPrice__c =  oli.UnitPrice;
            qli.OSA_Gross_Price__c =  oli.UnitPrice;
            qli.SBQQ__SpecialPrice__c =  oli.UnitPrice;
            qli.SBQQ__RegularPrice__c =  oli.UnitPrice;
            qli.SBQQ__ProratedListPrice__c =  oli.UnitPrice;
            
            qli.Total_Price__c =  oli.TotalPrice;
            qli.SBQQ__CustomerPrice__c =  oli.TotalPrice;
            qli.SBQQ__NetPrice__c =  oli.TotalPrice;
            
            qli.SBQQ__AdditionalDiscountAmount__c =  oli.OSA_Discount_Amount__c;
            
            qli.CurrencyISOCode = oli.CurrencyISOCode;
            
            qli.SBQQ__PricingMethod__c =  'List';
            qli.SBQQ__SubscriptionScope__c =  'Quote';
            qli.Id__c = oli.Id;

            return qli;
    }

}