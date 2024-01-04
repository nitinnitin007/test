/**
* @File Name     : ContentFilesTriggerHandler
* @Created BY    : Seena
* @Date          : 31 August ,2023
* @Description	 : Update Billing Invoice fields when new file added .
**/
public class ContentFilesTriggerHandler {
    public static FINAL String BILLING_INVOICE_OBJECT_NAME = 'blng__Invoice__c';
    public static void afterInsert(Map<Id,ContentDocumentLink> newCDLinksMap)
    {
        //For Update
        List<blng__Invoice__c> blngInvToUpdate = new List<blng__Invoice__c>();
        //Filter the Blng Invocie records
        Map<Id,Id> cdLinkToblngInvIds = new Map<Id,Id>();
        try{
        for(Id cDLinkId : newCDLinksMap.keySet()){
             if(BILLING_INVOICE_OBJECT_NAME == String.valueOf(newCDLinksMap.get(cDLinkId).LinkedEntityId.getsobjecttype()))
             { 
                 //Get the Content Document Link Id and Invoice Id
                 if(! cdLinkToblngInvIds.containsKey(cDLinkId))
                 cdLinkToblngInvIds.put(cDLinkId,newCDLinksMap.get(cDLinkId).LinkedEntityId); 
             }
        }
        //Get the Invoice and update the latest date and id fields
        List<blng__Invoice__c> blngInvs = [SELECT Id,Document_Generated_On__c,Latest_Document_Id__c FROM blng__Invoice__c
                                        WHERE Id in :cdLinkToblngInvIds.Values()];
        Map<Id,blng__Invoice__c> blngInvsMap = new Map<Id,blng__Invoice__c>(blngInvs);
        if(blngInvs.size() > 0) {
            //Get the Invoice file and update the fields
        for(Id linkId : cdLinkToblngInvIds.keySet()){
            if(blngInvsMap.containsKey(cdLinkToblngInvIds.get(linkId))){
             blng__Invoice__c blngInv = blngInvsMap.get(cdLinkToblngInvIds.get(linkId));
                blngInv.Document_Generated_On__c = newCDLinksMap.get(linkId).SystemModstamp;
                blngInv.Latest_Document_Id__c = newCDLinksMap.get(linkId).ContentDocumentId;
                blngInvToUpdate.add(blngInv);
            }
        }
        
            //Update Invoices
            if(blngInvToUpdate.size() > 0)
                Database.update(blngInvToUpdate);
        }
        }
        Catch(Exception e)
        { System.debug('ContentFilesTriggerHandler:afterInsert::'+e.getMessage());}
        
    }

}