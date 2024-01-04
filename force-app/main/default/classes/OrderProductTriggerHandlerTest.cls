@isTest
public with sharing class OrderProductTriggerHandlerTest {
   
    @isTest
    private static void doTest(){
        System.debug('Running Test....');
        List<Account> accList = TestDataFactory.createAccount(1,True);
        
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Test';
        taxRule.blng__Active__c = True;
        taxRule.blng__TaxableYesNo__c ='No';
        insert taxRule;
        
         blng__RevenueRecognitionRule__c revRecogRule = new blng__RevenueRecognitionRule__c();
        revRecogRule.blng__Active__c = true;
        revRecogRule.blng__CreateRevenueSchedule__c = 'No';
        insert revRecogRule;
        
        blng__BillingRule__c blngRule = new blng__BillingRule__c();
        blngRule.Name = 'Test';
        blngRule.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
        blngRule.blng__PartialPeriodTreatment__c = 'Separate';
        blngRule.blng__PeriodTreatmentForBTDO__c = 'Separate';
        blngRule.blng__GenerateInvoices__c = 'Yes';
        blngRule.blng__Active__c = True;
        insert blngRule;
       
        
        List<Product2> prodList = TestDataFactory.createProduct(1,True);
        prodList[0].blng__BillingRule__c = blngRule.Id;
        prodList[0].blng__TaxRule__c = taxRule.Id;
        prodList[0].blng__RevenueRecognitionRule__c = revRecogRule.Id;
        prodList[0].SBQQ__BillingFrequency__c = 'Annual';
        prodList[0].SBQQ__BillingType__c = 'Advance';
        prodList[0].SBQQ__ChargeType__c = 'Recurring';
        update prodList[0];
        
        PricebookEntry pbEntry = TestDataFactory.createPricebookEntry(prodList[0].Id,true);
        
        Order ord = new Order();
        ord.AccountId = accList[0].Id;
        ord.EffectiveDate = system.today();
        ord.Pricebook2Id = pbEntry.Pricebook2Id;
        ord.Status = 'Draft';
        ord.blng__BillingDayOfMonth__c = '1';
        insert ord;
        
        OrderItem ordItem = new OrderItem();
        ordItem.Product2Id = prodList[0].Id;
        ordItem.OrderId = ord.Id;
        ordItem.Quantity = 1; 
        ordItem.ServiceDate = system.today();
        ordItem.EndDate = system.today()+10;
        ordItem.PricebookEntryId = pbEntry.Id;
        ordItem.UnitPrice = 100;
        ordItem.blng__TaxPercentageApplied__c = 10;
        insert ordItem;
        ordItem.blng__TaxPercentageApplied__c = 20;
        update ordItem;
        system.assertEquals(20,ordItem.blng__TaxPercentageApplied__c,'Tax Percentage should be updated to 20%' );
    }
}