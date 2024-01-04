public class OP4IQuoteController {
    public string message {get;set;}
    
    public OP4IQuoteController() {
        message = 'Processing your request...';
    }
    

    public PageReference initialize() {
        String dealId  = ApexPages.currentPage().getParameters().get('dealId');
        String accId  = ApexPages.currentPage().getParameters().get('accid');
        String oppId  = ApexPages.currentPage().getParameters().get('oppid');

        system.debug('dealId--->'+dealId);
        
        PageReference opportunityPage;
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
            opportunityPage = new PageReference('/'+oppId);
        } else {

            if (string.isNotBlank(oppId)) {
                message = 'Not able to locate opportunity, please make sure oppid is valid...';
            } else {

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
                    opportunityPage = new PageReference('/'+quoteList[0].SBQQ__Opportunity2__c);
                } else {
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
                        Opportunity opportunity = createOpportunity(accountList[0]);
                        opportunityPage = new PageReference('/'+opportunity.Id);
                    } else {
                        message = 'Not able to locate account, please make sure accid is present and its valid...';
                    }
                }
            }
        }

        return opportunityPage;    
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

}