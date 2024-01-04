/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest
private class Test_TB_Renewal_Summary_ctrl {
     
    static testMethod void myUnitTest() {
        Account testAccount = IntappTestObjectFactory.createAccount(true);
        
        Contract testContract = new Contract(Name='test contract',AccountId=testAccount.Id,Status='Specialist Approval Needed',StartDate=Date.TODAY(),EndDate=Date.Today().addDays(5),OSA_Type__c='Other');
        insert testContract;
        
        Opportunity testOpp = new Opportunity(Name='test opp',AccountId=testAccount.Id,stageName='Target Account',CloseDate=Date.Today().addDays(30));
        testOpp.Associated_Contract_OSA__c=testContract.Id;
        testOpp.QS_TB_Billing_Model__c='Perpetual';
        testOpp.QS_TB_Enterprise_Lawyer_Band__c = 100;
        testOpp.QS_TB_End_User_Recurring_Amount__c = 200;
        testOpp.QS_TB_Licensed_Users__c = 100;
        testOpp.QS_TB_Additional_User_Price__c = '100';
        testOpp.QS_Total_Enabled_Users_12_Months__c = 10;
        testOpp.QS_Total_Enabled_Users_3_Months__c = 11;
        testOpp.QS_Unique_Timekeeper_Users_last_3_months__c = 12;
        testOpp.Unique_Timekeeper_Users_last_12_months__c = 13;
        insert testOpp;
        system.assertNotEquals(testOpp, null, 'Oppo Present');
        
       
        Test.startTest();
        ApexPages.StandardController stdCon = new ApexPages.StandardController(testOpp);
        Test.setCurrentPage(Page.TB_Renewal_Summary);
        ApexPages.currentPage().getParameters().put('Id',testOpp.Id);
        TB_Renewal_Summary_Controller controller = new TB_Renewal_Summary_Controller(stdCon);
        
		Test.stopTest();
        System.assertNotEquals(testaccount.Id, null);
    }
}