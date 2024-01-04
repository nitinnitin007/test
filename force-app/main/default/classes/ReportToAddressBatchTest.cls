@isTest
public class ReportToAddressBatchTest {
    
    @isTest
    static void testMethod1() {
        // Create accounts
        List<Account> testAccts = new List<Account>();
        Account testAccts01 = new Account();
        testAccts01.Name = 'Test Address Account 001';
        testAccts01.BillingCity = 'Arlington';
        testAccts01.ShippingCity = 'Chicago';
        testAccts01.BillingCountry = 'USA';
        testAccts01.ShippingCountry = 'USA';
        testAccts01.BillingStreet = '4148 Coulter Lane';
        testAccts01.ShippingStreet = '4028 Jewell Road';
        testAccts01.BillingState = 'Alaska';
        testAccts01.ShippingState = 'Alabama';
        testAccts01.BillingPostalCode =  '23005';
        testAccts01.ShippingPostalCode = '55404';
        testAccts.add(testAccts01);
        
        Account testAccts02 = new Account();
        testAccts02.Name = 'Test Address Account 002';
        testAccts02.BillingCity = 'Arlington';
        testAccts02.ShippingCity = 'Arlington';
        testAccts02.BillingCountry = 'United States';
        testAccts02.ShippingCountry = 'United States';
        testAccts02.BillingStreet = '4148 Coulter Lane';
        testAccts02.ShippingStreet = '4148 Coulter Lane';
        testAccts02.BillingState = 'Alabama';
        testAccts02.ShippingState = 'Alabama';
        testAccts02.BillingPostalCode =  '23005';
        testAccts02.ShippingPostalCode = '23005';
        testAccts.add(testAccts02);


        Account testAccts03 = new Account();
        testAccts03.Name = 'Test Address Account 002';
        testAccts03.BillingCity = 'Arlington';
        testAccts03.ShippingCity = 'Arlington';
        testAccts03.BillingCountry = 'United States';
        testAccts03.ShippingCountry = 'United States';
        testAccts03.BillingStreet = '5012 Coulter Lane';
        testAccts03.ShippingStreet = '5012 Coulter Lane';
        testAccts03.BillingState = 'Alabama';
        testAccts03.ShippingState = 'Alabama';
        testAccts03.BillingPostalCode =  '23005';
        testAccts03.ShippingPostalCode = '23005';
        testAccts.add(testAccts03);

        insert testAccts;

        Address__c address = new Address__c();
        address.Address__Street__s = '5012 Coulter Lane';
        address.Address__City__s = 'Arlington';
        address.Address__StateCode__s = 'AL';
        address.Address__CountryCode__s = 'US';
        address.Address__PostalCode__s = '23005';
        address.Type__c = 'Billing';
        address.Account__c = testAccts03.Id;
        insert address;
        
        // Create Opportunity
        List<Opportunity> opportunityList = new List<Opportunity>();
        for(Integer i=0;i<3;i++) {
            Opportunity opportunity = new Opportunity(
                Name = 'TestOpportunity'+i
                , CurrencyIsoCode = 'USD'
                , Type = 'Legal - Acquired New Product'
                , CloseDate = System.today()
                , StageName = 'Closed Won'
            );
            opportunity.AccountId = testAccts[i].Id;
            opportunityList.add(opportunity);
        }
        
        insert opportunityList;
        
        Test.startTest();
        ReportToAddressBatch reportToAddressBatchObj = new ReportToAddressBatch(null);
        Database.executeBatch(reportToAddressBatchObj);
        Test.stopTest();
        System.assertEquals(4,[Select id from Address__c].size());
    }
}