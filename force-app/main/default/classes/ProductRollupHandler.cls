public class ProductRollupHandler {
    
    public Static void productrollupAfterInsert(list<Product_Rollup__c> lstOfProductRollups){
        IntegrationUtility.publishEligibleSobjectRecords(lstOfProductRollups,null,'Product_Rollup__c');      
    }
    
    public Static void productrollupAfterUpdate(list<Product_Rollup__c> lstOfProductRollups,Map<Id,Product_Rollup__c> oldMapProductRollup){
        List<Product_Rollup__c> lstOfProductRollupsUpd = new List<Product_Rollup__c>();
        if(!lstOfProductRollups.IsEmpty())
        {
            for(Product_Rollup__c productrollupNew : lstOfProductRollups)
            {
                if(String.isNotBlank(productrollupNew.Intapp_ID__c))
                {
                    lstOfProductRollupsUpd.add(productrollupNew);
                }				
            }
        }
        if(lstOfProductRollupsUpd.size()>0)
        {			
            IntegrationUtility.publishEligibleSobjectRecords(lstOfProductRollupsUpd,oldMapProductRollup,'Product_Rollup__c');  
        }
    }
}