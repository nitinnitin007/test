public class CreditNoteTriggerHandler {
    public static set<Id> publishedCreditnoteIds = new set<Id>();
    public Static void creditNoteAfterUpdate(list<blng__CreditNote__c> crednoteNewList, Map<Id,blng__CreditNote__c> crednoteOldMap) {
        if(!crednoteNewList.IsEmpty())
        {
            list<blng__CreditNote__c> creditnoteToProcessList = new list<blng__CreditNote__c>();
            for(blng__CreditNote__c credNote : crednoteNewList)
            {
                if(crednoteOldMap!=null && crednoteOldMap.containsKey(credNote.Id) &&           
                   (credNote.blng__Status__c != crednoteOldMap.get(credNote.id).blng__Status__c || 
                    credNote.Approval_Status__c != crednoteOldMap.get(credNote.id).Approval_Status__c)){
                        if(credNote.blng__Status__c == 'Posted' && credNote.Approval_Status__c == 'Approved'){
                            creditnoteToProcessList.add(credNote);
                        }
                    }   
       
            }
            if(!creditnoteToProcessList.IsEmpty() && creditnoteToProcessList.size()>0)
            {
                processEvents(creditnoteToProcessList,crednoteOldMap,true);
            }           
        }
    } 
    
    public static void processEvents(list<blng__CreditNote__c> creditnoteToProcessList,Map<Id,blng__CreditNote__c> crednoteOldMap,Boolean sendLines) {
        List<blng__CreditNote__c> creditnoteEligibleList = new List<blng__CreditNote__c>();
        List<blng__CreditNoteLine__c> creditNotelineList = new List<blng__CreditNoteLine__c>();
        set<Id> setOfCreditnoteIds = new Set<Id>();     
        if(!creditnoteToProcessList.isEmpty()) {
            IntegrationUtility.publishsObjectRecords(creditnoteToProcessList,'blng__CreditNote__c');
            if (sendLines) {
                Schema.SObjectType targetObjType = Schema.getGlobalDescribe().get('blng__CreditNoteLine__c');
                Map<String, Schema.SObjectField> fieldMap = targetObjType.getDescribe().fields.getMap();
                List<String> fields = new List<String>(fieldMap.keyset());
                String query =
                    ' SELECT ' +
                    String.join( fields, ',' ) +
                    ' FROM ' +
                    'blng__CreditNoteLine__c' +
                    ' WHERE ' +
                    ' blng__CreditNote__c IN :creditnoteToProcessList';
                query = query.remove('{');
                query = query.remove('}');
                creditNotelineList = Database.query(query);        
                if(!creditNotelineList.IsEmpty()) {
                    IntegrationUtility.publishsObjectRecords(creditNotelineList,'blng__CreditNoteLine__c');
                }   
            }     
        }
    }
}