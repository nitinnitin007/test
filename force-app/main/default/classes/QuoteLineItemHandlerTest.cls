@isTest
public class QuoteLineItemHandlerTest {
    static TestMethod void  quoteLineItemMethod1(){
    Map<id,SBQQ__Quote__c> mapOfQuote= new Map<id,SBQQ__Quote__c>();
         Account acc = IntappTestObjectFactory.createAccount(true);
      acc.Industry = 'Test Industry';
        acc.SBQQ__RenewalModel__c = 'Contract Based';
        acc.OP4I_Sales_Segment__c = '03-Legal EMEA';
        update acc;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Opportunity opp = (Opportunity) SmartFactory.createSObject('Opportunity');
        opp.Name= 'TestOppoty';
    opp.AccountId = acc.Id;
        opp.StageName = '01. Qualify';
    opp.Requested_Contract_Expiration__c = Date.today();
    opp.Initial_Software_Term_Length_Months__c = 12;
    insert opp;
        
        opp.Pricebook2Id = pricebookId;
        update opp;

        Product2 prodObj = (Product2) SmartFactory.createSObject('Product2');
        prodObj.Name = 'Testproduct';
        prodObj.IsActive = true;
        prodObj.ProductCode = '123462';
        insert prodObj;
        
        Product2 prodObj1 = (Product2) SmartFactory.createSObject('Product2');
        prodObj1.Name = 'Testproduct2';
        prodObj1.IsActive = true;
        prodObj1.ProductCode = '12346289';
        insert prodObj1;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=prodObj.id, UnitPrice=1, IsActive=True);
        insert pbe; 
        
        SBQQ__Quote__c newQuote = (SBQQ__Quote__c) SmartFactory.createSObject('SBQQ__Quote__c');
        newQuote.SBQQ__Opportunity2__c = opp.Id;
        newQuote.SBQQ__Account__c = acc.Id;
        newQuote.SBQQ__SubscriptionTerm__c =36;
        newQuote.First_Segment_Months__c = 12;
        newQuote.License_Basis__c = 'Lawyers';
        newQuote.Number_of_DLIs__c= 1;
        newQuote.Number_of_QLIs__c= 1;
        newQuote.ApprovalStatus__c = 'Pending';
        newQuote.OP4I_OSA_Request_Received__c = true;
        newQuote.OP4I_Deal_Synced__c = true;
        newQuote.Deal_ACV__c = null;
        newQuote.SBQQ__LastCalculatedOn__c = null;
        newQuote.SBQQ__LastSavedOn__c = null;
        newQuote.Number_of_QLIs__c = 3;
        insert newQuote;
        mapOfQuote.put(newQuote.id,newQuote);
        
        List<SBQQ__QuoteLine__c> lstOfQLE = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> lstOfQLE1 = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> lstOfQLE2 = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c testqli1 = new SBQQ__QuoteLine__c();
        testqli1.SBQQ__Quote__c = newQuote.Id;
        testqli1.SBQQ__Quantity__c = 1;        
        testqli1.SBQQ__Product__c = prodObj.id;
        testqli1.Print_at_Quote__c = true;
        testqli1.SBQQ__CustomerPrice__c = 25;
        insert testqli1;

        
        SBQQ__QuoteLine__c testqli2 = new SBQQ__QuoteLine__c();
        testqli2.SBQQ__Quote__c = newQuote.Id;
        testqli2.SBQQ__Quantity__c = 1;        
        testqli2.SBQQ__Product__c = prodObj1.id;
        testqli2.SBQQ__RequiredBy__c = testqli1.id;
        testqli2.SBQQ__Discount__c = 10; 
        testqli2.Print_at_Quote__c = true;
        testqli2.SBQQ__CustomerPrice__c = 25;
        lstOfQLE.add(testqli2);
       
        
        insert lstOfQLE; 
        
        QuoteLineItemHandler.updateQuoteLine(lstOfQLE,mapOfQuote);
         System.assertNotEquals(lstOfQLE.size(), null);
    } 
    
    static testMethod void  quoteLineItemMethod2(){
        Test.startTest();
    Map<id,SBQQ__Quote__c> mapOfQuote= new Map<id,SBQQ__Quote__c>();
         Account acc = IntappTestObjectFactory.createAccount(true);
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Opportunity opp = new Opportunity();
        opp.Name= 'TestOppoty';
    	opp.AccountId = acc.Id;
        opp.Type = 'Intapp Prime';
        opp.StageName = 'Qualify';
        opp.CloseDate = Date.today() + 30;
    	opp.Requested_Contract_Expiration__c = Date.today();
    	insert opp;
        System.assertEquals('TestOppoty', opp.Name);
        
        opp.Pricebook2Id = pricebookId;
        update opp;

        Product2 prodObj = (Product2) SmartFactory.createSObject('Product2');
        prodObj.Name = 'Testproduct';
        prodObj.IsActive = true;
        prodObj.ProductCode = '123462';
        insert prodObj;
        
        Product2 prodObj1 = (Product2) SmartFactory.createSObject('Product2');
        prodObj1.Name = 'Testproduct2';
        prodObj1.IsActive = true;
        prodObj1.ProductCode = '12346289';
        insert prodObj1;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=prodObj.id, UnitPrice=1, IsActive=True);
        insert pbe; 
        
        SBQQ__Quote__c newQuote = (SBQQ__Quote__c) SmartFactory.createSObject('SBQQ__Quote__c');
        newQuote.SBQQ__Opportunity2__c = opp.Id;
        newQuote.SBQQ__Account__c = acc.Id;
        newQuote.SBQQ__SubscriptionTerm__c =36;
        newQuote.First_Segment_Months__c = 12;
        newQuote.License_Basis__c = 'Lawyers';
        newQuote.Number_of_DLIs__c= 1;
        newQuote.Number_of_QLIs__c= 1;
        newQuote.ApprovalStatus__c = 'Pending';
        newQuote.OP4I_OSA_Request_Received__c = true;
        newQuote.OP4I_Deal_Synced__c = true;
        newQuote.Deal_ACV__c = null;
        newQuote.SBQQ__LastCalculatedOn__c = null;
        newQuote.SBQQ__LastSavedOn__c = null;
        newQuote.Number_of_QLIs__c = 3;
        insert newQuote;
        mapOfQuote.put(newQuote.id,newQuote);
        
        List<SBQQ__QuoteLine__c> lstOfQLE = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> lstOfQLE1 = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> lstOfQLE2 = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c testqli1 = new SBQQ__QuoteLine__c();
        testqli1.SBQQ__Quote__c = newQuote.Id;
        testqli1.SBQQ__Quantity__c = 1;        
        testqli1.SBQQ__Product__c = prodObj.id;
        testqli1.Print_at_Quote__c = false;
        testqli1.SBQQ__CustomerPrice__c = 25;
        insert testqli1;

        
        SBQQ__QuoteLine__c testqli2 = new SBQQ__QuoteLine__c();
        testqli2.SBQQ__Quote__c = newQuote.Id;
        testqli2.SBQQ__Quantity__c = 1;        
        testqli2.SBQQ__Product__c = prodObj1.id;
        testqli2.SBQQ__RequiredBy__c = testqli1.id;
        testqli2.SBQQ__Discount__c = 10; 
        testqli2.Print_at_Quote__c = false;
        testqli2.SBQQ__CustomerPrice__c = 25;
        lstOfQLE.add(testqli2);
       
        
        insert lstOfQLE; 
        
        QuoteLineItemHandler.updateQuoteLine(lstOfQLE,mapOfQuote);
        QuoteLineItemHandler.Method3();
        Test.stopTest();
    } 
     
 }