@IsTest
public class OpportunityProductTriggerHandlerTest {
    
    @isTest
    public static void testHandler(){
        Account acc = IntappTestObjectFactory.createAccount(true);
        Opportunity opp = IntappTestObjectFactory.createOpportunity();
        insert opp;
        Id pricebookId = Test.getStandardPricebookId();
        Item_Master_Product__c imp = new Item_Master_Product__c();
        insert imp;
        Product_Line__c pl = new Product_Line__c();
        insert pl;
        ACV_Allocation__c acv = new ACV_Allocation__c(
           Product_Line__c = pl.Id,
           Item_Master_Product__c = imp.Id,
           Percent_Allocation__c = 10
        );
        insert acv;
        Product2 prod = new Product2(
            Name = 'Intapp Select Bundle',
            ProductCode = 'Pro-X',
            isActive = true,
           Item_Master_Product__c = imp.Id
        );
        //prod.Income_Account__c = 'Sales : Direct Sales';
        //prod.Deferred_Revenue_Account__c = 'Deferred Revenue : Deferred Revenue - Clearing Account';
        //prod.Revenue_Recognition_Rule__c = 'Default One-Time Direct Posting';
        //prod.Rev_Rec_Forecast_Rule__c = 'Default One-Time Direct Posting';
        //prod.Create_Revenue_Plans_On__c = 'Billing';
        //prod.Item_Revenue_Category__c = 'Deal Cloud';
        insert prod;
        
        PricebookEntry pbEntry = new PricebookEntry(
       Pricebook2Id = pricebookId,
       Product2Id = prod.Id,
       UnitPrice = 100.00,    
       IsActive = true
       );
       insert pbEntry;
        
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
        
        SBQQ__QuoteLine__c testqli = new SBQQ__QuoteLine__c();
        testqli.SBQQ__Quote__c = newQuote.Id;
        testqli.SBQQ__Quantity__c = 10;        
        testqli.SBQQ__Product__c = prod.id;
        testqli.Print_at_Quote__c = true;
        testqli.SBQQ__CustomerPrice__c = 28;
        insert testqli;
               
        SBQQ__QuoteLine__c testqli1 = new SBQQ__QuoteLine__c();
        testqli1.SBQQ__Quote__c = newQuote.Id;
        testqli1.SBQQ__Quantity__c = 1;        
        testqli1.SBQQ__Product__c = prod.id;
        testqli1.Print_at_Quote__c = true;
        testqli1.SBQQ__CustomerPrice__c = 25;
        testqli1.SBQQ__RequiredBy__c = testqli.Id;
        insert testqli1; 
        
       OpportunityLineItem oli = new OpportunityLineItem(
           OpportunityId = opp.Id,
           Quantity = 10,
           PricebookEntryId = pbEntry.Id,
           UnitPrice = 100,
           Customer_List_Price__c = 110,
           CPI__c = 1.2,
           Recurring_Amount_Change__c = 50,
           Recurring_Adjustment__c = 10,
           Active__c = true
       );
        oli.SBQQ__QuoteLine__c = testqli1.Id;
        insert oli;
       
        List<Opportunity_Product_Component__c> components = [SELECT Id, Opportunity__c, Product_Line__c, List_Price_Recurring__c, Recurring_Amount_Change__c, Customer_List_Price__c
                                                           FROM Opportunity_Product_Component__c
                                                           WHERE Opportunity__c = :opp.Id];
       System.assertEquals(1, components.size());
       Opportunity_Product_Component__c component = components[0];
       System.assertEquals(opp.id, component.Opportunity__c);
        
       oli.Quantity = 20;
       oli.UnitPrice = 2000;
       oli.Customer_List_Price__c = 2500;
       oli.CPI__c = 3.1;
       oli.Recurring_Amount_Change__c = 1000;
       oli.Recurring_Adjustment__c = 20;
       
       update oli;

       List<OpportunityLineItem> lstOLI = new List<OpportunityLineItem>{ oli }; 
       OpportunityLineItem oppli = [SELECT Quantity,UnitPrice,Recurring_Amount_Change__c,Recurring_Adjustment__c from OpportunityLineItem where OpportunityId =: opp.Id];
       Update lstOLI;
       
       Delete lstOLI;
      
       List<Opportunity_Product_Component__c> components1 = [SELECT Id, Opportunity__c, Product_Line__c, List_Price_Recurring__c, Recurring_Amount_Change__c, Customer_List_Price__c
                                                           FROM Opportunity_Product_Component__c
                                                           WHERE Opportunity__c = :opp.Id];
       System.assertEquals(0, components1.size());
      OpportunityProductTriggerHandler.afterUnDelete(lstOLI);

    }
}