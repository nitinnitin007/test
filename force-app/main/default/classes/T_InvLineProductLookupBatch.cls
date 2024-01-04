/**** @Name       : T_InvLineProductLookupBatch
***** @Created By : KPMG
***** @Created On : Nov 11th, 2023
***** @Description : Invoice lines lookup : Product , No Legacy "LEGACY. GE-01553"
******/
public class T_InvLineProductLookupBatch implements Database.Batchable<sObject>,Database.Stateful {
    //Database.executeBatch(new T_InvLineProductLookupBatch(),200);    
    public List<QtC_Mig_Invoice_Temp_Table__c> count = new List<QtC_Mig_Invoice_Temp_Table__c>();
    public Set<String> noInvForLines = new Set<String>();
    public Set<String> noInvForPay = new Set<String>(); 
    public Set<String> noInvForPayAlloc = new Set<String>(); 
    public database.querylocator start(Database.BatchableContext bc)
    { //Quering the inv lines records
        String queryInvLine = 'Select Id,T_Invoice__c,Item__c,T_ProductName__c,Internal_ID__c,T_Product__c,T_DupProdCode__c  from QtC_Mig_Invoice_Lines_Temp_Table__c ';
        //' where  T_Product__c = null';//T_MatchedWithPayCM__C = true 
        return Database.getQueryLocator(queryInvLine);
    }
    // Passing the QtC_Mig_Invoice_Lines_Temp_Table__c records
    public void execute(Database.BatchableContext bc,List<QtC_Mig_Invoice_Lines_Temp_Table__c> invsExl)
    {
        invLineProductLookup(invsExl);     
    } 
    public static void invLineProductLookup(List<QtC_Mig_Invoice_Lines_Temp_Table__c> invsExl){
        Map<String,List<QtC_Mig_Invoice_Lines_Temp_Table__c>> ilineProdCodeToInvoiceMap = new Map<String,List<QtC_Mig_Invoice_Lines_Temp_Table__c>>();
        //Iterating the inv lines records
        for(QtC_Mig_Invoice_Lines_Temp_Table__c i : invsExl)
        {//T_Invoice__c,Internal_ID__c 
            String codeWithoutSpecChars = i.Item__c.contains('LEGACY. ') ?  i.Item__c.replace('LEGACY. ','') : i.Item__c;//No Legacy "LEGACY. GE-01553" 
            if (ilineProdCodeToInvoiceMap.containsKey(codeWithoutSpecChars)) //i.Item__c
            {ilineProdCodeToInvoiceMap.get(codeWithoutSpecChars).add(i);}
            else {ilineProdCodeToInvoiceMap.put(codeWithoutSpecChars,new List<QtC_Mig_Invoice_Lines_Temp_Table__c>{i});}
        }
        //Get the Product details
        List<Product2> matchingProducts = [SELECT Id,Name,ProductCode,IsActive 
                                           FROM Product2 
                                           WHERE IsActive = true 
                                           AND ProductCode In :ilineProdCodeToInvoiceMap.keySet()];
        Map<String,List<Product2>> prodCodeToProdIdMap = new Map<String,List<Product2>>();
        //Get the products based on Product code in a map
        for (Product2 prod : matchingProducts) {
            if(prodCodeToProdIdMap.containsKey(prod.ProductCode))
            {prodCodeToProdIdMap.get(prod.ProductCode).add(prod);}
            else {prodCodeToProdIdMap.put(prod.ProductCode, new List<Product2>{prod});}
        }
        List<QtC_Mig_Invoice_Lines_Temp_Table__c> forUpdate = new List<QtC_Mig_Invoice_Lines_Temp_Table__c>();
        //Updating the product name and prodcut code
        for (String prodCode : ilineProdCodeToInvoiceMap.keySet()) {
            //Checking for special character and removing it
            String codeWithoutSpecChars = prodCode.contains('LEGACY. ') ?  prodCode.replace('LEGACY. ','') : prodCode;//No Legacy "LEGACY. GE-01553" 
            if (prodCodeToProdIdMap.containsKey(codeWithoutSpecChars)) {
                List<QtC_Mig_Invoice_Lines_Temp_Table__c> tempInvLines = ilineProdCodeToInvoiceMap.get(codeWithoutSpecChars);
                //Updating the Inv Lines Temp Table with Product name and Product id
                for(QtC_Mig_Invoice_Lines_Temp_Table__c tempInvLine : tempInvLines){
                    if(prodCodeToProdIdMap.get(codeWithoutSpecChars) != null){
                        tempInvLine.T_Product__c = prodCodeToProdIdMap.get(codeWithoutSpecChars)[0].Id;
                        tempInvLine.T_ProductName__c = prodCodeToProdIdMap.get(codeWithoutSpecChars)[0].Name;
                        //If more than one Product Code in org set the flag
                        if(prodCodeToProdIdMap.get(codeWithoutSpecChars).size() > 1){
                            tempInvLine.T_DupProdCode__c = true;
                        }
                        forUpdate.add(tempInvLine);         
                    }
                }
            }
        }
        //updating the inv line records with Product name and product code
        if(forUpdate.size() > 0)
        {Update forUpdate;}
    }    
    public void finish(Database.BatchableContext bc){
        //Batch Finish
    }
}