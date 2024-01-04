@isTest
public class OP4IQuoteControllerTest {
    @isTest
    private static void accountIdTest() {
        Account account = new Account();
        account.Name = 'Test Account';
        insert account;
        ApexPages.currentPage().getParameters().put('accid',account.Id);
        ApexPages.currentPage().getParameters().put('dealId','1234');
        Test.startTest();
        OP4IQuoteController controller = new OP4IQuoteController();
        Pagereference page = controller.initialize();
        
        Opportunity opportunity = [Select id from Opportunity];
        ApexPages.currentPage().getParameters().put('oppid',opportunity.Id);
        page = controller.initialize();
        Test.stopTest();
        system.assertEquals(true, opportunity.Id != null);
	}
    
    @isTest
    private static void invalidOppidTest() {
        Account account = new Account();
        account.Name = 'Test Account';
        insert account;
        ApexPages.currentPage().getParameters().put('dealId','1234');
        ApexPages.currentPage().getParameters().put('oppid',account.Id);
        Test.startTest();
        OP4IQuoteController controller = new OP4IQuoteController();
        Pagereference page = controller.initialize();
        Test.stopTest();
        system.assertEquals('Not able to locate opportunity, please make sure oppid is valid...',controller.message);

    }
    
    @isTest
    private static void invalidDealidTest() {
        Account account = new Account();
        account.Name = 'Test Account';
        insert account;
        ApexPages.currentPage().getParameters().put('dealId','1234');
        Test.startTest();
        OP4IQuoteController controller = new OP4IQuoteController();
        Pagereference page = controller.initialize();
        Test.stopTest();
        system.assertEquals('Not able to locate account, please make sure accid is present and its valid...',controller.message);

    }
}