public with sharing class OP4IQuoteControllerV2 {
    public string message {get;set;}
    
    public OP4IQuoteControllerV2() {
        message = 'Processing your request...';
    }
    

    public PageReference initialize() {
        String dealId  = ApexPages.currentPage().getParameters().get('dealId');
        String accId  = ApexPages.currentPage().getParameters().get('accid');
        String oppId  = ApexPages.currentPage().getParameters().get('oppid');

        system.debug('dealId--->'+dealId);
        
        PageReference quotePage;
        List<SBQQ__Quote__c> quoteList;
        if (string.isNotBlank(dealId)) {
            quoteList = [
                SELECT Id
                    , OP4IDealID__c
                    , SBQQ__Opportunity2__c
                FROM SBQQ__Quote__c
                WHERE OP4IDealID__c = :dealId
            ];
        }
        
        if (quoteList != null && quoteList.size() > 0){
            quotePage = new PageReference('/'+quoteList[0].Id);
        } else {
            //check if opportunity present
            List<Opportunity> opportunityList;
            if (string.isNotBlank(oppId)) {
                opportunityList = [
                    SELECT Id
                            , AccountId
                            , Pricebook2Id
                        FROM Opportunity
                    WHERE Id = :oppId
                ];
            }

            if (opportunityList != null && opportunityList.size() > 0) {
                //create quote;
                string quoteId = createQuote(opportunityList[0],dealId);
                quotePage = new PageReference('/'+quoteId);
            } else {
                //check for account
                List<Account> accountList;
                if (string.isNotBlank(accId)) {
                    accountList = [
                        SELECT Id
                             , Name
                          FROM Account
                         WHERE Id = :accId
                    ];
                }

                if (accountList != null && accountList.size() > 0) {
                    //create opportunity
                    Opportunity opportunity = createOpportunity(accountList[0]);

                    //create quote
                    string quoteId = createQuote(opportunity,dealId);
                    quotePage = new PageReference('/'+quoteId);
                } else {
                    message = 'Not able to locate account, please make sure accid is present and its valid...';
                }

            }
        }

        return quotePage;    
    }

    public static Opportunity createOpportunity(Account account) {
        Opportunity opportunity = new Opportunity();
        opportunity.accountId = account.Id;
        opportunity.name = account.Name;
        opportunity.closeDate = date.today().toStartOfMonth().addMonths(1).addDays(-1);
        opportunity.stageName = 'Qualify';
        insert opportunity;
        return opportunity;
    }

    public static Id createQuote(
        Opportunity opportunity,
        string dealId
    ) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = opportunity.Id;
        quote.SBQQ__PriceBook__c = opportunity.Pricebook2Id;
        quote.SBQQ__Account__c = opportunity.AccountId;
        quote.OP4IDealID__c = dealId;
        //quote.SBQQ__SubscriptionTerm__c = string.isNotBlank(term)? Integer.valueOf(term) : 12;
        //quote.First_Segment_Months__c = string.isNotBlank(firstTerm)? Integer.valueOf(firstTerm) : 12;
        //quote.Payment_Term_Software__c = paymentTerm;
        insert quote;
        return quote.Id;
    }
}