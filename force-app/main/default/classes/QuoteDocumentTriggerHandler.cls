public class QuoteDocumentTriggerHandler {
     public Static void quotedocumentAfterInsert(list<SBQQ__QuoteDocument__c > quotedocNewList) {
        IntegrationUtility.publishEligibleSobjectRecords(quotedocNewList,null,'SBQQ__QuoteDocument__c');
    }
    
    public Static void quotedocumentAfterUpdate(list<SBQQ__QuoteDocument__c > quotedocNewList,Map<Id,SBQQ__QuoteDocument__c > quotedocOldMap) {
        IntegrationUtility.publishEligibleSobjectRecords(quotedocNewList,quotedocOldMap,'SBQQ__QuoteDocument__c');
    }
 }