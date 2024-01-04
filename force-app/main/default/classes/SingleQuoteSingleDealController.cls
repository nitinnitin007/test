/**
* @description       : Controller class for SingleQuoteSingleDeal LWC Component
* @author            : Keerthan N
* Jira story : BIZ-45100,BIZ-45932,BIZ-46504,BIZ-46899,BIZ-49349
**/
public with sharing class SingleQuoteSingleDealController {
    
    //class to create quote and opportunity on click of manage quote from OP4I.
    @AuraEnabled
    public static String checkAndCreateQuote(String dealId, String accId, String dealType, String currencyIso,String existingClient){
        Savepoint sp = Database.setSavepoint();
        try{
            List<SBQQ__Quote__c> quoteList = [Select Id,Deal_Type__c From SBQQ__Quote__c Where OP4IDealID__c =: dealId Limit 1];
            SBQQ__Quote__c quoteRec;
            List<Account> getAcc = [Select Id,Name,CurrencyIsoCode,Industry__c From Account Where Id =: accId Limit 1];
                if(quoteList.size() > 0 && getAcc.size() > 0){ // Added as part of BIZ-46504
                    quoteRec = quoteList[0]; 
                    if(quoteRec.Deal_Type__c != dealType){
                        quoteRec.Deal_Type__c = dealType;
                        Update quoteRec;
                    }
                }
                else{
                    if(getAcc.size() > 0){
                        String currencyCode='USD';
                        if(currencyIso != ''){
                            currencyCode = currencyIso;
                        }
                        else{
                            currencyCode = getAcc[0].CurrencyIsoCode;
                        }
                        Integer numberOfDays = Date.daysInMonth(System.Today().year(), System.Today().month());
                        Date lastDayOfMonth = Date.newInstance(System.Today().year(), System.Today().month(), numberOfDays);
                        Opportunity opp = new Opportunity();
                        opp.AccountId = getAcc[0].Id;
                        opp.Name = getAcc[0].Name;
                        opp.CloseDate = lastDayOfMonth;
                        opp.StageName = 'Qualify';
                        opp.OwnerId = UserInfo.getUserId();
                        opp.OP4I_Deal_Id__c = dealId;//BIZ-45932
                        opp.CurrencyIsoCode = currencyCode;
                        Insert opp;
                        SBQQ__Quote__c quot = new SBQQ__Quote__c();
                        Id devRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('Draft_Quote').getRecordTypeId();
                        quot.SBQQ__Opportunity2__c = opp.Id;
                        quot.OwnerId = UserInfo.getUserId();
                        quot.SBQQ__Primary__c = True;
                        quot.OP4IDealID__c = dealId;
                        quot.OP4I_Deal_Name__c = dealId;
                        quot.SBQQ__Account__c = accId;
                        quot.recordTypeId = devRecordTypeId;
                        quot.Deal_Type__c = dealType;
                        quot.CurrencyIsoCode = currencyCode;
                        quot.Quote_Stage__c = System.Label.Configure_Products;
                        quot.Existing_Client__c = existingClient == 'Y' ? True : False;
                        Insert quot;
                        quoteRec = quot; 
                    }
                    else{
                        return 'Error;'+System.Label.Manage_Quote_Error;//Created as part of BIZ-46899
                    }
                }
                return 'Success;SBQQ__Quote__c;'+quoteRec.Id; 
        }
        catch(Exception e){
            Database.rollback(sp);
            return 'Error;'+e.getMessage();
            
        }
    }
}