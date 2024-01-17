public class SubscriptionTriggerHandler {
    Private static Boolean firstcall = false;
    Public static Boolean firstcall(){
        return firstcall;
    }
    
    public Static void subscriptionAfterInsert(list<SBQQ__Subscription__c > subNewList) { 
        list<SBQQ__Subscription__c> subPublishList = new list<SBQQ__Subscription__c>();
        if(!firstcall){        
            if(!subNewList.isEmpty()){
                for(SBQQ__Subscription__c subObj : subNewList){
                    if(subObj.Contract_Status__c == 'In Force'){
                        subPublishList.add(subObj);
                    }
                }
                if(subPublishList.size()>0 && !subPublishList.isEmpty()){
                    IntegrationUtility.publishsObjectRecords(subPublishList,'SBQQ__Subscription__c');
                }
            }
        }
        
        firstcall = true;
    } 
    
    public Static void subscriptionAfterUpdate(list<SBQQ__Subscription__c > subNewList,Map<Id,SBQQ__Subscription__c > subOldMap){
        List<SBQQ__Subscription__c> subsEligibleList = new List<SBQQ__Subscription__c>();
        if(!firstcall){
            if(!subNewList.isEmpty()){
            for(SBQQ__Subscription__c subObj : subNewList)
            if(subObj.Sync_OP4i__c == true && subObj.Sync_OP4i__c!=subOldMap.get(subObj.id).Sync_OP4i__c){
                subsEligibleList.add(subObj);
            }
        }
            IntegrationUtility.publishsObjectRecords(subsEligibleList,'SBQQ__Subscription__c');
        }
        firstcall = true;
    }
}