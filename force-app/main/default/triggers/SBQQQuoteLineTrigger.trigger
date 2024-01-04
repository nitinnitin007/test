trigger SBQQQuoteLineTrigger on SBQQ__QuoteLine__c (after insert, after update, after delete) {
    System.debug('*******SBQQQuoteLineTrigger');
   if(Trigger.isAfter) 
    {
        if(Trigger.isDelete)
        {
            AddStaticBundleHandler.afterDelete(Trigger.oldMap); 
        }
    } 
       
   // Avoid reoccorance
        if(trigger.isUpdate ){
            QuoteLineTriggerHandler.avoidReoccuranceUpdateMethod(trigger.new,trigger.oldmap);
        }
    
    if(trigger.isInsert){
        QuoteLineTriggerHandler.avoidReoccuranceInsertMethod(trigger.new);
     }
     
    if(trigger.isDelete){
        QuoteLineTriggerHandler.quoteLineAfterDelete(trigger.oldmap);
    }
    if (trigger.isAfter)
        {
            if(Trigger.isUpdate){
                //QuoteLineItemHandler.setnumberOfQLI(trigger.new,trigger.OldMap);
                //AddStaticBundleHandler.afterUpdate(Trigger.New);
            }
        }
    if(Trigger.isInsert && Trigger.isAfter){
        System.debug('*****After Insert');
        QuoteLineTriggerHandler.quoteLineAfterInsert(trigger.new);
        AddStaticBundleHandler.afterInsert(Trigger.New); // Added by Dhiraj as per  Created as part of BIZ-47580
    }
    
    if(Trigger.isUpdate && Trigger.isAfter){
        QuoteLineTriggerHandler.quoteLineAfterUpdate(Trigger.new, Trigger.oldMap); 
    }   
    
}