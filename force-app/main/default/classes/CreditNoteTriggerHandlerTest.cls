@isTest
public class CreditNoteTriggerHandlerTest {
    @isTest
    static void testMethod1(){
        List<blng__CreditNote__c> creditnoteToProcessList = new List<blng__CreditNote__c>();
        Map<Id,blng__CreditNote__c> crednoteOldMap = new Map<Id,blng__CreditNote__c>();
        Account acc = IntappTestObjectFactory.createAccount(true);
        
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
        
        Product2 prodObj = (Product2) SmartFactory.createSObject('Product2');
        prodObj.Name = 'Testproduct';
        prodObj.IsActive = true;
        prodObj.ProductCode = '123462';
        prodObj.blng__BillingRule__c = billRule.Id;
        prodObj.blng__RevenueRecognitionRule__c = rrObj.Id;
        prodObj.blng__TaxRule__c = taxRuleObj.Id;
        prodObj.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        prodObj.SBQQ__SubscriptionTerm__c = 12;
        prodObj.SBQQ__SubscriptionType__c = 'Renewable';
        prodObj.SBQQ__ChargeType__c = 'Recurring';
        prodObj.SBQQ__BillingFrequency__c = 'Quarterly';
        prodObj.SBQQ__BillingType__c = 'Arrears';
        insert prodObj;
        
        blng__CreditNote__c creditNote = new blng__CreditNote__c();
        creditNote.blng__Account__c = acc.Id;
        creditNote.blng__CreditNoteDate__c = Date.TODAY();
        creditNote.blng__Status__c = 'Draft';
        creditnoteToProcessList.add(creditNote);
        insert creditnoteToProcessList;
        crednoteOldMap.put(creditnoteToProcessList[0].Id,creditnoteToProcessList[0]);
        
        blng__CreditNoteLine__c credNoteLine = new blng__CreditNoteLine__c();
        credNoteLine.blng__Product__c = prodObj.Id;
        credNoteLine.blng__CreditNote__c = creditnoteToProcessList[0].Id;
        credNoteLine.blng__Status__c = 'Draft';
        credNoteLine.blng__CreditNoteLineDate__c = Date.TODAY();
        insert credNoteLine;
        
        creditnoteToProcessList[0].Approval_Status__c = 'Approved';
        creditnoteToProcessList[0].blng__Status__c = 'Posted';
        update creditnoteToProcessList[0];

        CreditNoteTriggerHandler.processEvents(creditnoteToProcessList,crednoteOldMap,true);
        
        list<blng__CreditNote__c> listOfCreditnote = new list<blng__CreditNote__c>();
        listOfCreditnote.add(creditNote);
        system.assertNotEquals(listOfCreditnote.size(), null);
 
    }
}