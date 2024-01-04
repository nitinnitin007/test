public class IntappPricingHandler
{
    public Static void intappPriceAfterInsert(list<Intapp_Pricing__c> lstOfIntappPrices){
        IntegrationUtility.publishEligibleSobjectRecords(lstOfIntappPrices,null,'Intapp_Pricing__c');      
    }
    
    public Static void intappPriceAfterUpdate(list<Intapp_Pricing__c> lstOfIntappPrices,Map<Id,Intapp_Pricing__c> oldMapIntappPrice){
       List<Intapp_Pricing__c> lstOfIntappPricesUpd = new List<Intapp_Pricing__c>();
        if(!lstOfIntappPrices.IsEmpty())
        {
            for(Intapp_Pricing__c intAppPriceNew : lstOfIntappPrices)
            {
                if(String.isNotBlank(intAppPriceNew.Intapp_ID__c) ||String.isNotBlank(intAppPriceNew.Premium_Intapp_ID__c))
                {
                    lstOfIntappPricesUpd.add(intAppPriceNew);
                }				
            }
        }
        if(lstOfIntappPricesUpd.size()>0)
        {			
            IntegrationUtility.publishEligibleSobjectRecords(lstOfIntappPricesUpd,oldMapIntappPrice,'Intapp_Pricing__c');  
        }
    }
}