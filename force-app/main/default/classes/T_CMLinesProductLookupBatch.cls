/**** @name        : T_CMLinesProductLookupBatch
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Update the Product and Product Name in the QtC_Mig_CreditMemoLines_Temp_Table__c
                   : Credit Memo lines, remove Legacy data "LEGACY. GE-01553"
******/ 
public class T_CMLinesProductLookupBatch implements Database.Batchable<sObject>,Database.Stateful {
//Database.executeBatch(new T_CMLinesProductLookupBatch(),200);    
       
public database.querylocator start(Database.BatchableContext bc)
	{
      //Get the CM Lines temp records for Product lookup update
      String queryInvLine = 'Select Id,Item__c,T_ProductName__c,Internal_ID__c,T_Product__c,T_DupProdCode__c  from QtC_Mig_CreditMemoLines_Temp_Table__c ';
      return Database.getQueryLocator(queryInvLine);
    }
    public void execute(Database.BatchableContext bc,List<QtC_Mig_CreditMemoLines_Temp_Table__c> invsExl)
    {
        Map<String,List<QtC_Mig_CreditMemoLines_Temp_Table__c>> ilineProdCodeToInvoiceMap = new Map<String,List<QtC_Mig_CreditMemoLines_Temp_Table__c>>();
        for(QtC_Mig_CreditMemoLines_Temp_Table__c cmLineTemp : invsExl)
        {
            //Remove Legay from the Item field for mapping.
            String codeWithoutSpecChars = cmLineTemp.Item__c.contains('LEGACY. ') ?  cmLineTemp.Item__c.replace('LEGACY. ','') : cmLineTemp.Item__c;//No Legacy "LEGACY. GE-01553" 
            //Get the C Lines based on the Product code.
            if (ilineProdCodeToInvoiceMap.containsKey(codeWithoutSpecChars)) 
            {ilineProdCodeToInvoiceMap.get(codeWithoutSpecChars).add(cmLineTemp);}
            else {ilineProdCodeToInvoiceMap.put(codeWithoutSpecChars,new List<QtC_Mig_CreditMemoLines_Temp_Table__c>{cmLineTemp});}
        }
        //Get the Product details based on the CM Temp's Item which is the product code.
        List<Product2> matchingProducts = [SELECT Id,Name,ProductCode from Product2 
                                           WHERE IsActive = true 
                                           AND ProductCode in :ilineProdCodeToInvoiceMap.keySet()];
        Map<String,List<Product2>> prodCodeToProdIdMap = new Map<String,List<Product2>>();
        if(matchingProducts.size()>0){
                //Get the Products based on the Product Code
        for (Product2 prod : matchingProducts) {
            { if(prodCodeToProdIdMap.containsKey(prod.ProductCode))
            {prodCodeToProdIdMap.get(prod.ProductCode).add(prod);}
             else {prodCodeToProdIdMap.put(prod.ProductCode, new List<Product2>{prod});}
            }
        }    
        }
        //Update Temp CM Lines records based on the Product codes. 
        List<QtC_Mig_CreditMemoLines_Temp_Table__c> forUpdate = new List<QtC_Mig_CreditMemoLines_Temp_Table__c>();
         for (String prodCode : ilineProdCodeToInvoiceMap.keySet()) {
             String codeWithoutSpecChars = prodCode.contains('LEGACY. ') ?  prodCode.replace('LEGACY. ','') : prodCode;//No Legacy "LEGACY. GE-01553" 
             if (prodCodeToProdIdMap.containsKey(codeWithoutSpecChars)) {
                List<QtC_Mig_CreditMemoLines_Temp_Table__c> temp = ilineProdCodeToInvoiceMap.get(codeWithoutSpecChars);
                 if(temp != null){
                for(QtC_Mig_CreditMemoLines_Temp_Table__c cmLine : temp){
                    if(prodCodeToProdIdMap.get(codeWithoutSpecChars) != null){
                    cmLine.T_Product__c = prodCodeToProdIdMap.get(codeWithoutSpecChars)[0].Id;
                    cmLine.T_ProductName__c = prodCodeToProdIdMap.get(codeWithoutSpecChars)[0].Name;
                    //If more than one Product Code in org
                    if(prodCodeToProdIdMap.get(codeWithoutSpecChars).size() > 1)
                        cmLine.T_DupProdCode__c = true;
                         forUpdate.add(cmLine);
                    }
                }
                }
            }
        }
        if(forUpdate.size() > 0 ){
            Update forUpdate;}
    }   
  
public void finish(Database.BatchableContext bc){

    
}
}