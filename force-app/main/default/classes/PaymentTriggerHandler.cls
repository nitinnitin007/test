public class PaymentTriggerHandler {
    
    public Static void paymentAfterInsert(list<blng__Payment__c> payNewList) {
        list<blng__Payment__c> lstOfpaymentToSend = new List<blng__Payment__c>();
        if(!payNewList.IsEmpty())
        {
            for(blng__Payment__c payment : payNewList)
            {
                if(payment.blng__Status__c == 'Posted'){
                    lstOfpaymentToSend.add(payment);              
                }
            }        
        }
        
        if(!lstOfpaymentToSend.IsEmpty() && lstOfpaymentToSend.size()>0)
            IntegrationUtility.publishEligibleSobjectRecords(payNewList,null,'blng__Payment__c');
    }   
    public Static void paymentAfterUpdate(list<blng__Payment__c> payNewList,Map<Id,blng__Payment__c> payOldMap) {
        list<blng__Payment__c> updatePaymentList = new List<blng__Payment__c>();
        if(!payNewList.isEmpty())
        {
            for(blng__Payment__c paymentobj : payNewList)
            {
                if(paymentobj.blng__Status__c!=payOldMap.get(paymentobj.id).blng__Status__c && paymentobj.blng__Status__c == 'Posted')
                {
                    updatePaymentList.add(paymentobj);
                }
                if(paymentobj.Sync_NetSuite__c == true && paymentobj.Sync_NetSuite__c!=payOldMap.get(paymentobj.id).Sync_NetSuite__c){
                    updatePaymentList.add(paymentobj);  
                }
            }    
        } 
        IntegrationUtility.publishsObjectRecords(updatePaymentList,'blng__Payment__c');
    }
}