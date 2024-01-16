public class ItemMasterProductTriggerHandler {
    public static void itemMasterProductAfterUpdate(List<Item_Master_Product__c> itemMasterList,Map<Id,Item_Master_Product__c> itemMasterOldMap){
        if(!itemMasterList.isEmpty() && itemMasterList.size()>0){
            IntegrationUtility.publishEligibleSobjectRecords(itemMasterList,itemMasterOldMap,'Item_Master_Product__c');
        }
    }
}