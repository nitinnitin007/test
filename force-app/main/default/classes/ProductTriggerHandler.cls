public class ProductTriggerHandler {
    
    public Static void productAfterInsert(list<Product2> lstOfProduct){
        IntegrationUtility.publishEligibleSobjectRecords(lstOfProduct,null,'Product2');      
    }
    
    public Static void productAfterUpdate(list<Product2> lstOfProduct,Map<Id,Product2> oldMapProduct){
        List<Product2> lstOfProductUpd = new List<Product2>();
        if(!lstOfProduct.IsEmpty())
        {
            for(Product2 productNew : lstOfProduct)
            {
                if(String.isNotBlank(productNew.NetSuite_Internal_Id__c))
                {
                    lstOfProductUpd.add(productNew);
                }               
            }
        }
        if(lstOfProductUpd.size()>0)
        {           
            IntegrationUtility.publishEligibleSobjectRecords(lstOfProductUpd,oldMapProduct,'Product2');  
        }
    }
}