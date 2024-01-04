@isTest
public class SubscriptionTriggerHandlerTest {
	@isTest
    public static void testMethod1(){
        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Quantity__c = 12;
        insert subscription;
        
        list<SBQQ__Subscription__c> listOfSubscription = new list<SBQQ__Subscription__c>();
        listOfSubscription.add(subscription);
        system.assertNotEquals(listOfSubscription.size(), null);
    }
}