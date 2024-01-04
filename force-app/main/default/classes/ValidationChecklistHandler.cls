/**
 * @description       : Handler class for ValidationChecklistTrigger
 * @author            : Dipali Pedgulwar
 * @last modified on  : 04-09-2023
 * @last modified by  : Dipali Pedgulwar
 * Modifications Log
 * Ver   Date         Author         Modification
 * 1.0   04-09-2023   Dipali Pedgulwar   Initial Version
**/
public class ValidationChecklistHandler {

    //method to count number of checked checkboxes newly created/updated Validation_Checklist__c records
    public static void countChecklist(List<Validation_Checklist__c> newList) {
        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get('Validation_Checklist__c').getDescribe();
		Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        List<String> fieldList = new List<String>();
        for(Schema.SObjectField field: fieldMap.values()) {
            if(field.getDescribe().getType() == Schema.DisplayType.BOOLEAN) {
                fieldList.add(field.getDescribe().getName());
            }    
        }
        Integer count;
        if(!fieldList.isEmpty() && !newList.isEmpty()) {
            for(Validation_Checklist__c checklist : newList) {
                count = 0;
                for(String field : fieldList) {
                    if((Boolean)checklist.get(field)){
                        count++;
                    }
                }
                checklist.Checklist_Count__c = count;
            }
        }
    }
}