/**
* @description       : This class is a utility class for AddStaticBundleHandler.
* @author            : Dhiraj Kumar
* @last modified on  : 09-22-2023
* @last modified by  : Dhiraj Kumar
* Modifications Log
* Ver   Date         Author         Modification
* 1.0   09-22-2023   Dhiraj Kumar   Initial Version
**/
public class CloneQuoteLines {
    
    /**
* @description : Return list of Child Products to be Inserted into the database
* @author Dhiraj Kumar | 09-22-2023 
* @param List<Id> ListOfParentQLI
* Map<Id,List<SBQQ__LookupData__c>> mapOfLookUpDataByQuoteLineId
**/
    public static List<SBQQ__QuoteLine__c> createQuoteLines(List<Id> listOfParentQLIs, Map<Id,List<SBQQ__LookupData__c>> mapOfLookUpDataByQuoteLineId)
    {
        System.debug('CloneQuoteLines Method STARTS --->');
        List<SBQQ__QuoteLine__c> clonedQuoteLines = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> originalQuoteLines = Database.query(allFields('SBQQ__QuoteLine__c')+' Where ID IN : ListOfParentQLIs');
        
        for(SBQQ__QuoteLine__c parentQLI : originalQuoteLines)
        {
            //System.debug('parentQLI : '+ parentQLI.Id);
            If(parentQLI.SBQQ__Quantity__c > 0){
                List<SBQQ__LookupData__c> lookupDataList = new List<SBQQ__LookupData__c>();
                
                if(mapOfLookUpDataByQuoteLineId.containskey(parentQLI.SBQQ__Product__c))
                {
                    lookupDataList=  mapOfLookUpDataByQuoteLineId.get(parentQLI.SBQQ__Product__c);
                }
                
                for(Integer i = 0; i<lookupDataList.size();i++)
                {  
                    SBQQ__QuoteLine__c clonedLineRec = parentQLI.Clone(false, true, false, false);
                    if(clonedLineRec.CurrencyIsoCode == lookupDataList[i].CurrencyIsoCode)
                    {
                        clonedLineRec.SBQQ__Product__c = lookupDataList[i].Child_Product__c;
                        clonedLineRec.SBQQ__RequiredBy__c = parentQLI.Id;
                        clonedLineRec.SBQQ__Dimension__c = lookupDataList[i].Dimension_Id__c;
                        clonedLineRec.SBQQ__PricebookEntryId__c = lookupDataList[i].PriceBookEntry_Id__c;
                        clonedLineRec.SBQQ__CustomerPrice__c =  parentQLI.SBQQ__CustomerPrice__c * (lookupDataList[i].Product_Allocation__c/100);
                        clonedLineRec.SBQQ__SegmentKey__c = lookupDataList[i].SBQQ__Value__c;
                        clonedLineRec.SBQQ__ListPrice__c = parentQLI.SBQQ__ListPrice__c * (lookupDataList[i].Product_Allocation__c/100);
                        clonedLineRec.SBQQ__NetPrice__c = (parentQLI.SBQQ__NetTotal__c * (lookupDataList[i].Product_Allocation__c/100))/parentQLI.SBQQ__Quantity__c;
                        clonedLineRec.Bypass_PriceRule__c = true;
                        clonedLineRec.Lookup_Data_Id__c = lookupDataList[i].Id;
                        clonedLineRec.Product_Allocation_for_Static_Bundle__c = lookupDataList[i].Product_Allocation__c;
                        clonedLineRec.SBQQ__Bundle__c = false;
                        clonedLineRec.Skip_OP4I_Sync__c = true;
                        clonedLineRec.Parent_of_Bundle__c = false;
                        
                        clonedQuoteLines.add(clonedLineRec); 
                    }
                    
                }
            }
        }
        System.debug('CloneQuoteLines Method ENDS --->'+clonedQuoteLines.size());
        return clonedQuoteLines;
    }
    
    public static String allFields(String objectName) {
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap().keySet());
        String query  = 'SELECT '+String.join(fields, ',')+' FROM '+ObjectName;
        return query;
    }
    
}