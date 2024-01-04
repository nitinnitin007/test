/**
 * @description       : This test class will cover QuoteTermValidator class.
 * @author            : Shikha Verma
 * @last modified on  : 11-29-2023
 * @last modified by  : Shikha Verma
 * Modifications Log
 * Ver   Date         Author         Modification
 * 1.0   11-29-2023   Shikha Verma   Initial Version
**/
@isTest
public class QuoteTermValidatorTest {
    /**
    * ***********************************************************
    * This method is test SetUp method 
    * ***********************************************************
    */
    @testSetup
    public static void setup(){     
        List<Account> accList = TestDataFactory.createAccount(1,True);              
        List<Opportunity> opportunityList = TestDataFactory.createOppty(1, accList[0].Id, true);
        List<SBQQ__Quote__c> quoteList = TestDataFactory.createQuote(1, opportunityList[0].Id, true);
        SBQQ__QuoteTerm__c quoteTerm = new SBQQ__QuoteTerm__c(SBQQ__Body__c='Subsidiary__c',SBQQ__PrintOrder__c=26,SBQQ__Active__c=true);
        insert quoteTerm;        
        Term_Quote__c termQuote = new Term_Quote__c(Quote__c=quoteList[0].Id,Term__c=quoteTerm.Id,Body__c='Test',Print_Order__c=300);
        insert termQuote;
    }
    
    /**
    * ***********************************************************
    * This method is test method for generateQuoteTerms
    * ***********************************************************
    */
    @isTest
    public static void testgenerateQuoteTerms(){        
        Test.startTest();
            List<SBQQ__Quote__c> quoteList = [SELECT Id, Name FROM SBQQ__Quote__c LIMIT 1];
            SBQQ__QuoteTerm__c quoteTerm = [SELECT Id, Name FROM SBQQ__QuoteTerm__c LIMIT 1];
            SBQQ__TermCondition__c termCondition1 = new SBQQ__TermCondition__c(SBQQ__QuoteTerm__c=quoteTerm.Id,SBQQ__TestedField__c='SBQQ__ProductCode__c',SBQQ__Operator__c='contains',SBQQ__Value__c='DealCloud',SBQQ__Index__c=1);
            SBQQ__TermCondition__c termCondition2 = new SBQQ__TermCondition__c(SBQQ__QuoteTerm__c=quoteTerm.Id,SBQQ__TestedField__c='SBQQ__ProductCode__c',SBQQ__Operator__c='does not contain',SBQQ__Value__c='Test',SBQQ__Index__c=2);
            SBQQ__TermCondition__c termCondition3 = new SBQQ__TermCondition__c(SBQQ__QuoteTerm__c=quoteTerm.Id,SBQQ__TestedField__c='Contract_Master_Terms__c',SBQQ__Operator__c='not equals',SBQQ__Value__c='Existing Intapp MSSA Terms',SBQQ__Index__c=3);
            SBQQ__TermCondition__c termCondition4 = new SBQQ__TermCondition__c(SBQQ__QuoteTerm__c=quoteTerm.Id,SBQQ__TestedField__c='Contract_Master_Terms__c',SBQQ__Operator__c='equals',SBQQ__Value__c='Existing Intapp MSSA Plus Cloud',SBQQ__Index__c=4);
            List<SBQQ__TermCondition__c> termCondList = new List<SBQQ__TermCondition__c>();
            termCondList.add(termCondition1);
            termCondList.add(termCondition2);
            termCondList.add(termCondition3);
            termCondList.add(termCondition4);
            insert termCondList;
            quoteTerm.SBQQ__ConditionsMet__c='Any';
            update quoteTerm;
            QuoteTermValidator.generateQuoteTerms(quoteList[0].Id);
            System.assertEquals(1,quoteList.size());
        Test.stopTest();
    }
    /**
    * ***********************************************************
    * This method is test method for generateQuoteTerms
    * ***********************************************************
    */
    @isTest
    public static void testgenerateQuoteTerms1(){  
        List<SBQQ__Quote__c> quoteList = [SELECT Id, Name FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteTerm__c quoteTerm = [SELECT Id, Name FROM SBQQ__QuoteTerm__c LIMIT 1];
        SBQQ__TermCondition__c termCondition1 = new SBQQ__TermCondition__c(SBQQ__QuoteTerm__c=quoteTerm.Id,SBQQ__TestedField__c='Subsidiary__c',SBQQ__Operator__c='contains',SBQQ__Value__c='DealCloud',SBQQ__Index__c=1);
        SBQQ__TermCondition__c termCondition2 = new SBQQ__TermCondition__c(SBQQ__QuoteTerm__c=quoteTerm.Id,SBQQ__TestedField__c='Subsidiary__c',SBQQ__Operator__c='does not contain',SBQQ__Value__c='Test',SBQQ__Index__c=2);
        SBQQ__TermCondition__c termCondition3 = new SBQQ__TermCondition__c(SBQQ__QuoteTerm__c=quoteTerm.Id,SBQQ__TestedField__c='Contract_Master_Terms__c',SBQQ__Operator__c='not equals',SBQQ__Value__c='Existing Intapp MSSA Terms',SBQQ__Index__c=3);
        SBQQ__TermCondition__c termCondition4 = new SBQQ__TermCondition__c(SBQQ__QuoteTerm__c=quoteTerm.Id,SBQQ__TestedField__c='Contract_Master_Terms__c',SBQQ__Operator__c='equals',SBQQ__Value__c='Existing Intapp MSSA Plus Cloud',SBQQ__Index__c=4);
        List<SBQQ__TermCondition__c> termCondList = new List<SBQQ__TermCondition__c>();
        termCondList.add(termCondition1);
        termCondList.add(termCondition2);
        termCondList.add(termCondition3);
        termCondList.add(termCondition4);
        insert termCondList;
        quoteTerm.SBQQ__ConditionsMet__c='Custom';
        quoteTerm.SBQQ__AdvancedCondition__c='1 AND 2 AND ( 3 OR 4 )';
        update quoteTerm;
        Test.startTest();           
            QuoteTermValidator.generateQuoteTerms(quoteList[0].Id);
            System.assertEquals(1,quoteList.size());
        Test.stopTest();
    }
    
    /**
    * ***********************************************************
    * This method is test method for generateQuoteTerms
    * ***********************************************************
    */
    @isTest
    public static void testgenerateQuoteTerms2(){  
        List<SBQQ__Quote__c> quoteList = [SELECT Id, Name FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteTerm__c quoteTerm = [SELECT Id, Name FROM SBQQ__QuoteTerm__c LIMIT 1];
        SBQQ__TermCondition__c termCondition1 = new SBQQ__TermCondition__c(SBQQ__QuoteTerm__c=quoteTerm.Id,SBQQ__TestedField__c='Contract_Term_Version__c',SBQQ__Operator__c='greater or equals',SBQQ__Value__c='10.7',SBQQ__Index__c=1);
        SBQQ__TermCondition__c termCondition2 = new SBQQ__TermCondition__c(SBQQ__QuoteTerm__c=quoteTerm.Id,SBQQ__TestedField__c='Contract_Term_Version__c',SBQQ__Operator__c='less than',SBQQ__Value__c='10.9',SBQQ__Index__c=2);
        SBQQ__TermCondition__c termCondition3 = new SBQQ__TermCondition__c(SBQQ__QuoteTerm__c=quoteTerm.Id,SBQQ__TestedField__c='Contract_Term_Version__c',SBQQ__Operator__c='greater than',SBQQ__Value__c='10.6',SBQQ__Index__c=3);
        SBQQ__TermCondition__c termCondition4 = new SBQQ__TermCondition__c(SBQQ__QuoteTerm__c=quoteTerm.Id,SBQQ__TestedField__c='Contract_Term_Version__c',SBQQ__Operator__c='less or equals',SBQQ__Value__c='10.8',SBQQ__Index__c=4);
        List<SBQQ__TermCondition__c> termCondList = new List<SBQQ__TermCondition__c>();
        termCondList.add(termCondition1);
        termCondList.add(termCondition2);
        termCondList.add(termCondition3);
        termCondList.add(termCondition4);
        insert termCondList;
        quoteTerm.SBQQ__ConditionsMet__c='All';
        update quoteTerm;
        Test.startTest();           
            QuoteTermValidator.generateQuoteTerms(quoteList[0].Id);
            System.assertEquals(1,quoteList.size());
        Test.stopTest();
    }
    
}