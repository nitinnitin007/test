// QuoteTermValidator
public without sharing class QuoteTermValidator {
    @AuraEnabled
    public static String generateQuoteTerms(Id quoteId){
        String message='';
        try {
        if(quoteId != null) {
        Map<Id, SBQQ__QuoteTerm__c> quoteTermMap = getAllQuoteTerms();
        List<String> quoteFields = getQuoteFields(quoteTermMap.values());
        SBQQ__Quote__c quoteDetails = getQuoteDetails(quoteId, quoteFields);
        List<Term_Quote__c> termsToCreate = evaluateTermConditions(quoteTermMap, quoteDetails); 
        System.debug('final termsToCreate'+ termsToCreate);    
        List<Term_Quote__c> existingTermsOnQuote = getExistingTerms(quoteId);
        QuoteTermCreator.consolidateOldAndNew(termsToCreate, existingTermsOnQuote);
        System.debug('termsToCreate><><>'+termsToCreate);
        /*if(!termsToCreate.isEmpty()) {
            insert termsToCreate;
        }*/
            message = 'Quote Terms are generated.';
        }
        } catch(Exception ex) {
            System.debug('Error Occurred: '+ex.getMessage());
        }
        return message;
    }
    
    private static Map<Id, SBQQ__QuoteTerm__c> getAllQuoteTerms() {
        Map<Id, SBQQ__QuoteTerm__c> quoteTermMap = new Map<Id, SBQQ__QuoteTerm__c>([SELECT Id, SBQQ__Body__c, SBQQ__PrintOrder__c, SBQQ__ConditionsMet__c, SBQQ__AdvancedCondition__c,(SELECT Id, SBQQ__Index__c, SBQQ__Operator__c, SBQQ__TestedField__c, SBQQ__TestedVariable__c, SBQQ__Value__c FROM SBQQ__UseConditions__r) FROM SBQQ__QuoteTerm__c WHERE SBQQ__Quote__c = null AND SBQQ__Active__c = true]);
        return quoteTermMap;
    }
    
    private static SBQQ__Quote__c getQuoteDetails(Id quoteId, List<String> quoteFields) {
    	String query = 'SELECT '+String.join(quoteFields, ',')+', (Select Id, SBQQ__ProductCode__c FROM SBQQ__LineItems__r) FROM SBQQ__Quote__c WHERE Id=: quoteId';
        System.debug('query>>>'+query);
        List<SBQQ__Quote__c> quoteList = Database.query(query);
        
        return quoteList[0];
    }
	
    private static List<String> getQuoteFields(List<SBQQ__QuoteTerm__c> terms) {
        List<String> fieldSet = new List<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get('SBQQ__Quote__c');
		Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
        for (Schema.SObjectField field : fieldMap.values()) {
             fieldSet.add(field.getDescribe().getName());
         }
        /*for(SBQQ__QuoteTerm__c term : terms) {
            for(SBQQ__TermCondition__c condition: term.SBQQ__UseConditions__r) {
                if(!condition.SBQQ__TestedField__c.equalsIgnoreCase('SBQQ__ProductCode__c')) {
                    fieldSet.add(condition.SBQQ__TestedField__c);
                }
            }
        }*/
        return fieldSet;
    }
    
    private static List<Term_Quote__c> evaluateTermConditions(Map<Id, SBQQ__QuoteTerm__c> quoteTermMap, SBQQ__Quote__c quoteDetails) {
        List<Term_Quote__c> termsToCreate = new List<Term_Quote__c>();
        Set<String> productCodes = new Set<String>();
        if(quoteDetails!= null && !quoteDetails.SBQQ__LineItems__r.isEmpty()) {
            System.debug('quoteDetails'+quoteDetails);
            for(SBQQ__QuoteLine__c quoteLine :quoteDetails.SBQQ__LineItems__r) {
                System.debug('quoteLine'+quoteLine);
                productCodes.add(quoteLine.SBQQ__ProductCode__c);
            }
        }
        for(SBQQ__QuoteTerm__c term : quoteTermMap.values()) {
                System.debug('QuoteTermValidator-term'+term);
                System.debug('quoteDetails'+quoteDetails);
                System.debug('productCodes'+productCodes);
                ConditionEvaluator evaluateConditions = new ConditionEvaluator(term, quoteDetails, productCodes);  
                //System.debug('term'+term);
            	Term_Quote__c termquote = evaluateConditions.evaluateConditionsAndInstantiateQuoteTerm();
                System.debug('termquote'+termquote);
            if(termquote!= null) {
                termsToCreate.add(termquote);
                System.debug('if not null termsToCreate->'+termquote);
            }
        }        
        System.debug('termsToCreate--->'+termsToCreate);
        return termsToCreate;
        
    }
    
    private static List<Term_Quote__c> getExistingTerms(Id quoteId) {
        return [SELECT Id, Term__c, Quote__c, Body__c, Print_Order__c,Validator_Modified__c, Modified__c FROM Term_Quote__c WHERE Quote__c =: quoteId];
    }
    
}