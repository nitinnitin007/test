public class QuoteLineTriggerHandler {
    
    public Static void quoteLineAfterInsert(list<SBQQ__QuoteLine__c> credNewList) {
        IntegrationUtility.publishEligibleSobjectRecords(credNewList,null,'SBQQ__QuoteLine__c');
    }
    
    public Static void quoteLineAfterUpdate(list<SBQQ__QuoteLine__c> credNewList,Map<Id,SBQQ__QuoteLine__c> credOldMap) {
        
        IntegrationUtility.publishEligibleSobjectRecords(credNewList,credOldMap,'SBQQ__QuoteLine__c');
    }
    
    public Static void quoteLineAfterDelete(Map<Id,SBQQ__QuoteLine__c> credOldMap){
        set<string> sbqqRequiredByLst = new set<string>();
    	set<string> sbqqQuoteLst = new set<string>(); 
    	set<string> sbqqRequiredByNameLst = new set<string>();
    	list<SBQQ__QuoteLine__c> quoteLineLst =  new list<SBQQ__QuoteLine__c>();
    	map<Id,SBQQ__Quote__c> mapOfQuote = new map<Id,SBQQ__Quote__c>();
        
        for(SBQQ__QuoteLine__c quoteLine : credOldMap.values()){
            if(quoteLine.SBQQ__RequiredBy__c != null && !quoteLine.Is_Bundle_Product__c){
               sbqqRequiredByLst.add(quoteLine.SBQQ__RequiredBy__c);
               sbqqQuoteLst.add(quoteLine.SBQQ__Quote__c);
            }
        }
        if(sbqqRequiredByLst.size()>0){ 
        mapOfQuote = new map<Id,SBQQ__Quote__c>([SELECT Id,Name,Extended_Initial_Term__c FROM SBQQ__Quote__c where Id IN: sbqqQuoteLst]);
        quoteLineLst = [SELECT SBQQ__CustomerTotal__c, Customer_Grand_Total__c, SBQQ__Discount__c, Bundle_Products__c, Bundle_Products_Extn2__c, Bundle_Products_Extn3__c, Is_Bundle_Product__c,Id,Monthly_Unit_Price__c,Monthly_Net_Price_Currency__c,Name,Product_Type__c,SBQQ__EndDate__c,SBQQ__ListPrice__c,SBQQ__Product__c, SBQQ__Product__r.ProductCode, SBQQ__Product__r.Name,Item_Master_Name__c,SBQQ__Quantity__c,SBQQ__Quote__c,SBQQ__Quote__r.Extended_Initial_Term__c,SBQQ__SegmentIndex__c,SegmentIndex_Year__c, SBQQ__StartDate__c, Quote_Segment__c, SBQQ__RequiredBy__c, Print_at_Quote__c, OSA_List_Price__c, SBQQ__ListTotal__c,Monthly_Unit_List_Price__c,Total_List_Price__c    FROM SBQQ__QuoteLine__c where SBQQ__RequiredBy__c IN:SBQQRequiredByLst OR ID IN:sbqqRequiredByLst];
    } 
    	if(quoteLineLst.size()>0){
        QuoteLineItemHandler.updateQuoteLine(quoteLineLst, mapOfQuote); 
    	}
    }
    public static void avoidReoccuranceUpdateMethod(list<SBQQ__QuoteLine__c> credNewList,Map<Id,SBQQ__QuoteLine__c> credOldMap){
        boolean processRecords = false;
        set<string> sbqqRequiredByLst = new set<string>();
    	set<string> sbqqRequiredByNameLst = new set<string>();
    	set<string> sbqqQuoteLst = new set<string>();
        list<SBQQ__QuoteLine__c> quoteLineRecList =  new list<SBQQ__QuoteLine__c>();
    	list<SBQQ__QuoteLine__c> quoteLineLst =  new list<SBQQ__QuoteLine__c>();
    	map<Id,SBQQ__Quote__c> mapOfQuote = new map<Id,SBQQ__Quote__c>();
        
        for(SBQQ__QuoteLine__c quoteLine : quoteLineRecList){
           if(!QuoteLineItemHandler.processedRecordSet.contains(quoteLine.Id)){
              QuoteLineItemHandler.processedRecordSet.add(quoteLine.Id);
              quoteLineRecList.add(quoteLine);
              processRecords = true;
           }else{
             processRecords = false;
           }
       }
       if(processRecords==true){
            for(SBQQ__QuoteLine__c quoteLine : quoteLineRecList){
            if(quoteLine.SBQQ__RequiredBy__c != null && ! quoteLine.Is_Bundle_Product__c &&
               !quoteLine.Parent_of_Bundle__c && !quoteLine.Skip_OP4I_Sync__c){
                sbqqRequiredByLst.add(quoteLine.SBQQ__RequiredBy__c);
                sbqqQuoteLst.add(quoteLine.SBQQ__Quote__c);
            }
         }   
       }
        if(sbqqRequiredByLst.size()>0){ 
        mapOfQuote = new map<Id,SBQQ__Quote__c>([SELECT Id,Name,Extended_Initial_Term__c FROM SBQQ__Quote__c where Id IN: sbqqQuoteLst]);
        quoteLineLst = [SELECT SBQQ__CustomerTotal__c, Customer_Grand_Total__c, SBQQ__Discount__c, Bundle_Products__c, Bundle_Products_Extn2__c, Bundle_Products_Extn3__c, Is_Bundle_Product__c,Id,Monthly_Unit_Price__c,Monthly_Net_Price_Currency__c,Name,Product_Type__c,SBQQ__EndDate__c,SBQQ__ListPrice__c,SBQQ__Product__c, SBQQ__Product__r.ProductCode, SBQQ__Product__r.Name,Item_Master_Name__c,SBQQ__Quantity__c,SBQQ__Quote__c,SBQQ__Quote__r.Extended_Initial_Term__c,SBQQ__SegmentIndex__c,SegmentIndex_Year__c, SBQQ__StartDate__c, Quote_Segment__c, SBQQ__RequiredBy__c, Print_at_Quote__c, OSA_List_Price__c, SBQQ__ListTotal__c,Monthly_Unit_List_Price__c,Total_List_Price__c    FROM SBQQ__QuoteLine__c where SBQQ__RequiredBy__c IN:SBQQRequiredByLst OR ID IN:sbqqRequiredByLst];
    } 
    	if(quoteLineLst.size()>0){
        QuoteLineItemHandler.updateQuoteLine(quoteLineLst, mapOfQuote); 
    	}
    }
    public static void avoidReoccuranceInsertMethod(list<SBQQ__QuoteLine__c> credNewList){
        list<decimal> segmentLst = new list<decimal>();
    	set<string> sbqqRequiredByLst = new set<string>();
    	set<string> sbqqRequiredByNameLst = new set<string>();
    	set<string> sbqqQuoteLst = new set<string>();
        list<SBQQ__QuoteLine__c> quoteLineRecList =  new list<SBQQ__QuoteLine__c>();
    	list<SBQQ__QuoteLine__c> quoteLineLst =  new list<SBQQ__QuoteLine__c>();
    	map<Id,SBQQ__Quote__c> mapOfQuote = new map<Id,SBQQ__Quote__c>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLineRecList){
        
            if(quoteLine.SBQQ__RequiredBy__c != null && ! quoteLine.Is_Bundle_Product__c 
              && !quoteLine.Parent_of_Bundle__c && !quoteLine.Skip_OP4I_Sync__c){
                sbqqRequiredByLst.add(quoteLine.SBQQ__RequiredBy__c);
                sbqqQuoteLst.add(quoteLine.SBQQ__Quote__c);
            }             
        }
        if(sbqqRequiredByLst.size()>0){ 
        mapOfQuote = new map<Id,SBQQ__Quote__c>([SELECT Id,Name,Extended_Initial_Term__c FROM SBQQ__Quote__c where Id IN: sbqqQuoteLst]);
        quoteLineLst = [SELECT SBQQ__CustomerTotal__c, Customer_Grand_Total__c, SBQQ__Discount__c, Bundle_Products__c, Bundle_Products_Extn2__c, Bundle_Products_Extn3__c, Is_Bundle_Product__c,Id,Monthly_Unit_Price__c,Monthly_Net_Price_Currency__c,Name,Product_Type__c,SBQQ__EndDate__c,SBQQ__ListPrice__c,SBQQ__Product__c, SBQQ__Product__r.ProductCode, SBQQ__Product__r.Name,Item_Master_Name__c,SBQQ__Quantity__c,SBQQ__Quote__c,SBQQ__Quote__r.Extended_Initial_Term__c,SBQQ__SegmentIndex__c,SegmentIndex_Year__c, SBQQ__StartDate__c, Quote_Segment__c, SBQQ__RequiredBy__c, Print_at_Quote__c, OSA_List_Price__c, SBQQ__ListTotal__c,Monthly_Unit_List_Price__c,Total_List_Price__c    FROM SBQQ__QuoteLine__c where SBQQ__RequiredBy__c IN:SBQQRequiredByLst OR ID IN:sbqqRequiredByLst];
    	} 
    	if(quoteLineLst.size()>0){
       QuoteLineItemHandler.updateQuoteLine(quoteLineLst, mapOfQuote); 
    	}
    }
}