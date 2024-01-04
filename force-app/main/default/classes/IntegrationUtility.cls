/**
 * @description       : Integration Utility class for SingleQuoteSingleDealController
 * @author            : Snehalkumar Choudhary 
**/
public with sharing class IntegrationUtility {
    public static void publishEligibleSobjectRecords(List<sObject>sObjectList,Map<Id,sObject>sObjectOldMap, String sObjectName) {
        List<Field_Tracking__mdt> fieldTrackingList = [
            SELECT Field_Api_Name__c
                 , Object_Name__c   
              FROM Field_Tracking__mdt
             WHERE Object_Name__c = :sObjectName
        ];
        
        Schema.SObjectType sObjectType  = Schema.getGlobalDescribe().get(sObjectName);
        List<sObject> sObjectEligibleList = new List<sObject>();
        for (sObject recordNew : sObjectList) {
            String recordId = (string)recordNew.get('Id');
            sObject recordOld = sObjectOldMap != null && sObjectOldMap.containsKey(recordId)? sObjectOldMap.get(recordId) : sObjectType.newSObject();
            if (isChanged(recordNew,recordOld,fieldTrackingList)) {
                sObjectEligibleList.add(recordNew);
            }
        }
        
        //check if any record matches the criteria
        if (sObjectEligibleList.size() > 0) {
            publishsObjectRecords(sObjectEligibleList,sObjectName);
        }
    }
     
    public static void publishsObjectRecords(List<sObject> lstOfsObjects, String sObjectName){  
        publishsObjectRecords(lstOfsObjects, sObjectName,null);
    }
    
    public static void publishsObjectRecords(List<sObject> lstOfsObjects, String sObjectName,String eventName){             
        List<List<sObject>> lstOfsObjectPayLoad = new List<List<sObject>>();
        List<sObject> sObjectUpdateList = new List<sObject>();
        Generic_Key_Value_Setting__mdt configurableMetadata = Generic_Key_Value_Setting__mdt.getInstance('Payload_Max_Size'); 
        Integer payLoadsize = Integer.valueOf(configurableMetadata.Value__c);
        
        for(sObject sObj : lstOfsObjects) {
            if((JSON.serialize(sObjectUpdateList)).length() < payLoadsize){
                system.debug('sObjectUpdateList size check' +(JSON.serialize(sObjectUpdateList)).length());                            
                sObjectUpdateList.add(sObj); 
            } else {
                system.debug('sObjectUpdateList add in List of List'); 
                lstOfsObjectPayLoad.add(sObjectUpdateList);
                sObjectUpdateList = new List<sObject>();
                sObjectUpdateList.add(sObj);
            }    
        }
        
        if(!sObjectUpdateList.isEmpty()) {
            lstOfsObjectPayLoad.add(sObjectUpdateList);
        }
        
        system.debug('lstOfsObjectPayLoad size' + lstOfsObjectPayLoad.size());
        system.debug('instance lstOfsObjectPayLoad' + lstOfsObjectPayLoad);
        
        if(!lstOfsObjectPayLoad.isEmpty()){
            List<DealEvent__e> lstOfDealEvents = new List<DealEvent__e>();
            Map<string, object> payLoad = new Map<string, object>();
            
            for(List<sObject> lstOfsObjectsUpd : lstOfsObjectPayLoad){ 
                payLoad.put('objectName', sObjectName);
                payLoad.put('body', lstOfsObjectsUpd);
                if (string.isNotblank(eventName)) {
                    payLoad.put('event', eventName);
                }
                DealEvent__e dealEvent = new DealEvent__e();
                dealEvent.Object_Name__c = sObjectName;
                dealEvent.Payload__c = JSON.serialize(payLoad);
                system.debug('dealEvent.Payload__c--->' + dealEvent.Payload__c);
                lstOfDealEvents.add(dealEvent);
            }
            List<Database.SaveResult> results = EventBus.publish(lstOfDealEvents);
        }
        
    }

    public static void publishsObjectRecord(sObject objRecord, String sObjectName){
        List<sObject> lstOfsObjects = new List<sObject>();
        lstOfsObjects.add(objRecord);
        publishsObjectRecords(lstOfsObjects, sObjectName);
    }
    
    public static boolean isChanged(Sobject recordNew, Sobject recordOld, List<Field_Tracking__mdt> fieldTrackingList) {
        for (Field_Tracking__mdt fieldTracking : fieldTrackingList) {
            if (recordNew.get(fieldTracking.Field_Api_Name__c) != recordOld.get(fieldTracking.Field_Api_Name__c)){
                return true;
            }
        }
        
        return false;
    }
}