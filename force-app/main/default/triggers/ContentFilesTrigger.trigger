trigger ContentFilesTrigger on ContentDocumentLink (after insert) {
    //Update Blng Invoice fields
    if(Trigger.isInsert && Trigger.isAfter)
     ContentFilesTriggerHandler.afterInsert(Trigger.NewMap);

}