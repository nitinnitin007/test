/********************************************************************************     
 *  Name             :  OpportunityQuoteMigrationBatch
 *  Author           :  Snehal Choudhary
 *  Description      :  Test Class for OpportunityQuoteMigrationBatch
 *                   
 *  Change history   :
 *  Date               Author             Description
 *  02/11/2023    Snehal Choudhary          Created
 ********************************************************************************/

@isTest
private class OpportunityQuoteMigrationBatchTest {    
    @testSetup static void setup() {
    Account acc = IntappTestObjectFactory.createaccount(true);
    Account billingAccount = IntappTestObjectFactory.createaccount(true);
        
    blng__BillingRule__c billRule = new blng__BillingRule__c();
    billRule.Name = 'Bill Rule1';
    billRule.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
    billRule.blng__PartialPeriodTreatment__c = 'Separate';
    billRule.blng__PeriodTreatmentForBTDO__c = 'Exclude Billing Day of Month';
    billRule.blng__GenerateInvoices__c = 'No';
    billRule.blng__Active__c = true;
    insert billRule;
    
    blng__RevenueRecognitionRule__c rrObj = new blng__RevenueRecognitionRule__c();
    rrObj.blng__Active__c = true;
    rrObj.blng__CreateRevenueSchedule__c = 'No';
    insert rrObj;
    
    blng__TaxRule__c taxRuleObj = new blng__TaxRule__c();
    taxRuleObj.blng__Active__c = true;
    taxRuleObj.blng__TaxableYesNo__c = 'No';
    insert taxRuleObj;
    
    Product2 prodObj = IntappTestObjectFactory.createProduct(true);
    prodObj.Name = 'TestProd';
    update prodObj;
    
    Contract con = IntappTestObjectFactory.createcontract(acc.Id);
    con.Billing_Account__c = billingAccount.Id;
    insert con;
    
    SBQQ__Quote__c quoteObj = IntappTestObjectFactory.createSBQQQuote();
    insert quoteObj;
    
    OP4I_Entitlement_View__c entitlement = new OP4I_Entitlement_View__c();
    entitlement.Associated_OSA__c = con.id;
    entitlement.Start_Date__c = Date.newInstance(2021, 4, 1);
    entitlement.End_Date__c = Date.newInstance(2022, 3, 31);
    entitlement.Sale_Price__c = 20.22;
    entitlement.Product_Type__c = 'Software';
    entitlement.DLI_Product__c = prodObj.id;
    entitlement.DLIP_Product__c = prodObj.id;
    entitlement.Billing_Frequency__c = 'Annual';
    insert entitlement;
    }  
  
  @isTest 
  private static void testMethod1() {
    test.startTest();
    product2 prodTest = [Select Id FROM Product2 WHERE Name = 'TestProd' LIMIT 1] ;
    blng__BillingRule__c billRule = [Select Id FROM blng__BillingRule__c WHERE Name = 'Bill Rule1' LIMIT 1] ;
    blng__RevenueRecognitionRule__c revRule = [Select Id FROM blng__RevenueRecognitionRule__c LIMIT 1] ;
    blng__TaxRule__c taxRule = [Select Id FROM blng__TaxRule__c LIMIT 1] ;
    prodTest.IsActive = true;
    prodTest.blng__BillingRule__c = billRule.Id;
    prodTest.blng__RevenueRecognitionRule__c = revRule.Id;
    prodTest.blng__TaxRule__c = taxRule.Id;
    prodTest.SBQQ__SubscriptionPricing__c = 'Fixed Price';
    prodTest.SBQQ__SubscriptionTerm__c = 12;
    prodTest.SBQQ__SubscriptionType__c = 'Renewable';
    prodTest.SBQQ__ChargeType__c = 'Recurring';
    prodTest.SBQQ__BillingFrequency__c = 'Annual';
    prodTest.SBQQ__BillingType__c = 'Arrears';
    update prodTest;

    Contract contr = [Select Id,Processing_Status__c FROM Contract LIMIT 1];
    contr.Status = 'Activated';
    update contr;
    contr.Status = 'In Force';
    contr.Subsidiary__c = '05:400 TFG - US';
    contr.Subsidiary__c = '05:400 TFG - US';
    contr.Migration_Status__c = 'Ready';
    update contr; 

        
    OpportunityQuoteMigrationBatch oppQuoteObj = new OpportunityQuoteMigrationBatch();
    database.executebatch(oppQuoteObj,1);
    test.stopTest();  
    Contract contrUpd = [Select Id,Processing_Status__c FROM Contract WHERE Id =: contr.Id LIMIT 1];
    System.assertEquals('Quote Created',contrUpd.Processing_Status__c);
  }
  
  @isTest 
  private static void testMethod2() {
    test.startTest();
    product2 prodTest = [Select Id FROM Product2 WHERE Name = 'TestProd' LIMIT 1] ;
    blng__BillingRule__c billRule = [Select Id FROM blng__BillingRule__c WHERE Name = 'Bill Rule1' LIMIT 1] ;
    blng__RevenueRecognitionRule__c revRule = [Select Id FROM blng__RevenueRecognitionRule__c LIMIT 1] ;
    blng__TaxRule__c taxRule = [Select Id FROM blng__TaxRule__c LIMIT 1] ;
    prodTest.IsActive = true;
    prodTest.blng__BillingRule__c = billRule.Id;
    prodTest.blng__RevenueRecognitionRule__c = revRule.Id;
    prodTest.blng__TaxRule__c = taxRule.Id;
    prodTest.SBQQ__SubscriptionPricing__c = 'Fixed Price';
    prodTest.SBQQ__SubscriptionTerm__c = 12;
    prodTest.SBQQ__SubscriptionType__c = 'Renewable';
    prodTest.SBQQ__ChargeType__c = 'Recurring';
    prodTest.SBQQ__BillingFrequency__c = 'Annual';
    prodTest.SBQQ__BillingType__c = 'Arrears';
    update prodTest;

    Contract contr = [Select Id,Processing_Status__c FROM Contract LIMIT 1];
    contr.Status = 'Activated';
    update contr;
    contr.Status = 'In Force';
    contr.Subsidiary__c = '05:400 TFG - US';
    contr.Subsidiary__c = '05:400 TFG - US';
    contr.Migration_Status__c = 'Ready';
    update contr;

    SBQQ__Quote__c quoteObj = [Select Id FROM SBQQ__Quote__c LIMIT 1];
    quoteObj.Migration_Contract__c = contr.id;
    update quoteObj;
    
    Opportunity oppObj = IntappTestObjectFactory.createOpportunity();   
    oppObj.Migration_Contract__c = contr.id;
    insert oppObj;
        
    OpportunityQuoteMigrationBatch oppQuoteObj = new OpportunityQuoteMigrationBatch();
    database.executebatch(oppQuoteObj,1); 
    test.stopTest();
    Contract contrUpd = [Select Id,Processing_Status__c FROM Contract WHERE Id = :contr.Id LIMIT 1];
    System.assertEquals('Quote Created',contrUpd.Processing_Status__c);  
  }
}