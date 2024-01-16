public class CreditNoteAllocationTriggerHandler {
    public static void creditNoteAllocationAfterInsert(list<blng__CreditNoteAllocation__c> credNewList) {
        IntegrationUtility.publishEligibleSobjectRecords(credNewList,null,'blng__CreditNoteAllocation__c');
    }
    
    public static void creditNoteAllocationAfterUpdate(list<blng__CreditNoteAllocation__c> credNewList,Map<Id,blng__CreditNoteAllocation__c> credOldMap) {
        
        if(!credNewList.IsEmpty())
        {
            set<id> creditnoteLineIds = new set<id>();
            for(blng__CreditNoteAllocation__c credNoteAllocation : credNewList)
            {
                creditnoteLineIds.add(credNoteAllocation.blng__CreditNoteLine__c);                  
            }
            if(creditnoteLineIds!=null && creditnoteLineIds.size()>0)
            {
                processEvents(creditnoteLineIds,true);
            } 
            for(blng__CreditNoteAllocation__c credNoteAllocation : credNewList){
                if(credNoteAllocation.Sync_NetSuite__c == true && credNoteAllocation.Sync_NetSuite__c!=credOldMap.get(credNoteAllocation.id).Sync_NetSuite__c){
                    creditnoteLineIds.add(credNoteAllocation.blng__CreditNoteLine__c);
                }
                if(creditnoteLineIds!=null && creditnoteLineIds.size()>0)
                {
                    processEvents(creditnoteLineIds,true);
                } 
            }
        }
    } 
    
    public static void processEvents(set<id> creditnoteLineIds,Boolean sendLines) {
        List<blng__CreditNoteAllocation__c> creditNoteAllocList = new List<blng__CreditNoteAllocation__c>();
        set<Id> setOfCreditnoteIds = new Set<Id>();     
        if(creditnoteLineIds!=null) {
            if (sendLines) {
                Schema.SObjectType targetObjType = Schema.getGlobalDescribe().get('blng__CreditNoteAllocation__c');
                Map<String, Schema.SObjectField> fieldMap = targetObjType.getDescribe().fields.getMap();
                List<String> fields = new List<String>(fieldMap.keyset());
                String query =
                    ' SELECT ' +
                    String.join( fields, ',' ) +
                    ' FROM ' +
                    'blng__CreditNoteAllocation__c' +
                    ' WHERE ' +
                    ' blng__CreditNoteLine__c IN :creditnoteLineIds';
                query = query.remove('{');
                query = query.remove('}');
                creditNoteAllocList = Database.query(query);        
                if(!creditNoteAllocList.IsEmpty()) {
                    IntegrationUtility.publishsObjectRecords(creditNoteAllocList,'blng__CreditNoteAllocation__c');
                }   
            }     
        }
    }
}