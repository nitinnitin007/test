/**
 * @description       : This class is will return the State & Country picklist API & label based on StateCode & CountryCode.
 * @author            : Pankaj Kumar
 * @last modified on  : 13-07-2023
 * @last modified by  : Pankaj Kumar
 * Modifications Log
 * Ver   Date         Author         Modification
 * 1.0   13-07-2023   Pankaj Kumar   Initial Version
**/
public without Sharing class StateCountryMapping {  
    
    public static Map<String, String> countryMapAPI(){
        Schema.DescribeFieldResult fieldResult = Address__c.Address__CountryCode__s.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        Map<String, String> labelAPIMapCountry = new Map<String, String>();
        
        for(Schema.PicklistEntry v : values) {
             labelAPIMapCountry.put(v.getValue(),v.getLabel());
        }
        return labelAPIMapCountry;
    }
    
    public static Map<String, String> stateMapAPI(){
        Schema.DescribeFieldResult fieldResult = Address__c.Address__StateCode__s.getDescribe();
        List<Schema.PicklistEntry> valuesState = fieldResult.getPicklistValues();
        Map<String, String> labelAPIMapState = new Map<String, String>();
        for(Schema.PicklistEntry v : valuesState) {
             labelAPIMapState.put(v.getValue(),v.getLabel());
        }
        return labelAPIMapState;
    }
}