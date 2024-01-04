@isTest
public class OP4IQuoteControllerV2Test {
    @isTest
    private static void accountIdTest() {
        Account account = new Account();
        account.Name = 'Test Account';
        insert account;
        ApexPages.currentPage().getParameters().put('accid',account.Id);
        ApexPages.currentPage().getParameters().put('dealId','1234');
        Test.startTest();
        OP4IQuoteControllerV2 controller = new OP4IQuoteControllerV2();
        Pagereference page = controller.initialize();
        
        Opportunity opportunity = [Select id from Opportunity];
        ApexPages.currentPage().getParameters().put('oppid',opportunity.Id);
        page = controller.initialize();
        Test.stopTest();
        system.assertEquals(true, opportunity.Id != null);
	}
    
    @isTest
    private static void oppidTest() {
        Account account = new Account();
        account.Name = 'Test Account';
        insert account;
        Opportunity opportunity = new Opportunity();
        opportunity.accountId = account.Id;
        opportunity.name = account.Name;
        opportunity.closeDate = date.today().toStartOfMonth().addMonths(1).addDays(-1);
        opportunity.stageName = 'Qualify';
        insert opportunity;
        ApexPages.currentPage().getParameters().put('dealId','1234');
        ApexPages.currentPage().getParameters().put('oppid',opportunity.Id);
        Test.startTest();
        OP4IQuoteControllerV2 controller = new OP4IQuoteControllerV2();
        Pagereference page = controller.initialize();
        Test.stopTest();
        SBQQ__Quote__c[] quoteList = [
            SELECT Id
                , OP4IDealID__c
                , SBQQ__Opportunity2__c
            FROM SBQQ__Quote__c
        ];
        system.assertEquals(1,quoteList.size());

    }
    
    @isTest
    private static void invalidDealidTest() {
        Account account = new Account();
        account.Name = 'Test Account';
        insert account;
        ApexPages.currentPage().getParameters().put('dealId','1234');
        Test.startTest();
        OP4IQuoteControllerV2 controller = new OP4IQuoteControllerV2();
        Pagereference page = controller.initialize();
        Test.stopTest();
        system.assertEquals('Not able to locate account, please make sure accid is present and its valid...',controller.message);

    }
}