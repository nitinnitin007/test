public class PaymentTriggerHandler {
    
    public Static void paymentAfterInsert(list<blng__Payment__c> credNewList) {
        IntegrationUtility.publishEligibleSobjectRecords(credNewList,null,'blng__Payment__c');
    }   
    public Static void paymentAfterUpdate(list<blng__Payment__c> credNewList,Map<Id,blng__Payment__c> credOldMap) {
        IntegrationUtility.publishEligibleSobjectRecords(credNewList,credOldMap,'blng__Payment__c');
    }
}