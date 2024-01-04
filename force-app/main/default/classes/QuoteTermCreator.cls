public without sharing class QuoteTermCreator {
	/**
     * The consolidateOldAndNew method runs DML operations to ensure that net new Case Actions
     * are inserted while obsolete ones are deleted. It does this by thinking by modelling 
     * new and old Case Actions as circles in a Venn diagram. The intersection of new and old
     * are the Case Actions which already exist and are still relevant and so we don't need
     * to do anything. One one side of the intersection are the new new Case Actions that need
     * to be deleted while on the other side are the Case Actions that currently exist but are no
     * longer relevant and therefore, need to be deleted.
     */
    public static void consolidateOldAndNew(List<Term_Quote__c> newTerms, List<Term_Quote__c> existingTerms) {
        System.debug('consolidateOldAndNew-newTerms'+newTerms);
        System.debug('consolidateOldAndNew-existingTerms'+existingTerms);
        Map<Id, Term_Quote__c> newTermsByIds = getTermsById(newTerms);
        Map<Id, Term_Quote__c> existingTermsByIds = getTermsById(existingTerms);

        //List<Term_Quote__c> netNewTerms = (List<Term_Quote__c>)inLeftMapOnly((Map<Id, sObject>)newTermsByIds, (Map<Id, sObject>)existingTermsByIds);
        //List<Term_Quote__c> outdatedTerms = (List<Term_Quote__c>)inLeftMapOnly((Map<Id, sObject>)existingTermsByIds, (Map<Id, sObject>)newTermsByIds);

        List<Term_Quote__c> termsForUpsert = getTermsForUpsert(newTermsByIds, existingTermsByIds);
        List<Term_Quote__c> obsoleteTerms = getTermsForDelete(newTermsByIds, existingTermsByIds);

        persistTerms(termsForUpsert);
        deleteterms(obsoleteTerms);
    }

    /** 
     * Private methods
     */

    private static Map<Id, Term_Quote__c> getTermsById(List<Term_Quote__c> quoteTerms) {
        Map<Id, Term_Quote__c> termIdMap = new Map<Id, Term_Quote__c>();
        for (Term_Quote__c term : quoteTerms) {
            termIdMap.put(term.Term__c, term);
            System.debug('termIdMap='+termIdMap);
        }

        return termIdMap;
    }

    /** 
     * The getTermsForUpsert method inserts the net new Case Actions. However, there is one
     * complexity - some Case Actions are related to Rule Actions that are part of a Rule Action
     * Group in this situation there may be existing Case Actions that are obsolete but instead of
     * being deleted they need to be modified (Description and Rule Action changed)
    */
    private static List<Term_Quote__c> getTermsForUpsert(Map<Id,Term_Quote__c> newTermsMap, Map<Id,Term_Quote__c> existingTermsMap) {
        List<Term_Quote__c> termsList = new List<Term_Quote__c>();
        List<Term_Quote__c> termsForUpsert = new List<Term_Quote__c>();
		for(Id termId :newTermsMap.keySet()) {
            if(!existingTermsMap.containsKey(termId)) {
                //new term to be inserted
                System.debug('newTermsMap--'+newTermsMap.get(termId) );
                termsList.add(newTermsMap.get(termId));
            } else {
                // existing term to be upserted if body or print order modified
                Term_Quote__c termQuote = existingTermsMap.get(termId);
                termQuote.Body__c = newTermsMap.get(termId).Body__c;
                termQuote.Print_Order__c = newTermsMap.get(termId).Print_Order__c;
                if(termQuote.Validator_Modified__c ==true){
                    termQuote.Validator_Modified__c =false;
                }else
                    termQuote.Validator_Modified__c =true;
                
                if(!termQuote.Modified__c){
                   termsList.add(termQuote); 
                }
                
            }
        }
        System.debug('termsList--'+termsList);      
        return termsList;
    }

    private static List<Term_Quote__c> getTermsForDelete(Map<Id,Term_Quote__c> newTermsMap, Map<Id,Term_Quote__c> existingTermsMap) {
       List<Term_Quote__c> termsToDelete = new List<Term_Quote__c>();
       
        for(Id termId:existingTermsMap.keySet()) {
            System.debug('existingMap term Id --'+termId);
            if(!newTermsMap.containsKey(termId)) {
                System.debug('newMap doesnt have term Id --'+termId);
                termsToDelete.add(existingTermsMap.get(termId));
                System.debug('termsToDelete --'+termsToDelete);
            }
        }
        return termsToDelete;
    }

    private static void persistTerms(List<Term_Quote__c> termsToPersist) {        
        Database.UpsertResult[] srList = Database.upsert(termsToPersist);

        for (Database.UpsertResult sr : srList) {
            if (sr.isSuccess()) {
                System.debug('Successfully upserted Term Quotes. Term Quote ID: ' + sr.getId());
            }
            else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Term Quote fields that affected this error: ' + err.getFields());
                }
            }
        }
    }

    private static void deleteTerms(List<Term_Quote__c> termsToDelete) {
        Database.DeleteResult[] srList = Database.delete(termsToDelete);

        for (Database.DeleteResult sr : srList) {
            if (sr.isSuccess()) {
                System.debug('Successfully deleted Term Quote. Term Quote ID: ' + sr.getId());
            }
            else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Term Quote fields that affected this error: ' + err.getFields());
                }
            }
        }
    }

}