public class SubscriptionTriggerHandler {
    
     public Static void subscriptionAfterInsert(list<SBQQ__Subscription__c > subNewList) {
        IntegrationUtility.publishEligibleSobjectRecords(subNewList,null,'SBQQ__Subscription__c');
    }
    
    public Static void subscriptionAfterUpdate(list<SBQQ__Subscription__c > subNewList,Map<Id,SBQQ__Subscription__c > subOldMap) {
        IntegrationUtility.publishEligibleSobjectRecords(subNewList,subOldMap,'SBQQ__Subscription__c');
    }
 }