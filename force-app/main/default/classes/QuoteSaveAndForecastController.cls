/**
 * @description       : Controller class for QuoteSaveAndForecast LWC Component
 * @author            : Keerthan N
 * Jira story : BIZ-45100
**/
public without sharing class QuoteSaveAndForecastController {

    //Method to update Quote Stage. Created as part of BIZ-45100.
    @AuraEnabled
    public static String updateQuote(String recordId){
            try{
                String draft = System.Label.Draft;
                List<SBQQ__Quote__c> quoteList = [Select Id,SBQQ__LineItemCount__c,Quote_Stage__c,OP4I_Status__c From SBQQ__Quote__c Where Id =: recordId And Quote_Stage__c=:draft And  SBQQ__LineItemCount__c > 0 Limit 1];
                if(quoteList.size() > 0 &&  !quoteList[0].Quote_Stage__c.equalsIgnoreCase(System.Label.Configure_Products)){
                    SBQQ__Quote__c quoteRec = quoteList[0];
                    quoteRec.Quote_Stage__c = System.Label.Configure_Products;
                    quoteRec.OP4I_Status__c = 'Request Submitted';
                    update quoteRec;  
                    return 'success';
                }
                return 'no_update';
            }
            catch(Exception e){
                //System.debug('Exception :'+e);
                return 'error';
            }
    }
}