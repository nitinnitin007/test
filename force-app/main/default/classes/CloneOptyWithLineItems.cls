/**
* @description       : BIZ-46116-This class is an Invocable class having NYMY functionality which is invoked from Opportunity : After Update flow.
* @author            : Pankaj Kumar
* @last modified on  : 09-21-2023
* @last modified by  : Pankaj Kumar
* Modifications Log
* Ver   Date         Author         Modification
* 1.0   07-07-2023   Pankaj Kumar   Initial Version
**/
public without Sharing class CloneOptyWithLineItems {
    
/**
* @description : This method will handle NYMY opty & line Item cloning. 
* @author Pankaj Kumar | 09-21-2023 
* @param List<Id> recordId 
**/ 
    @InvocableMethod(label='CloneOptyWithLineItems' description='Method to clone Opportunity And Opportunity LineItems')
    public static List<Id> cloneOpp(List<Id> recordId){
        cloneOppFuture(recordId);
        return null;
    }
    @future(callout=false)
    public static void cloneOppFuture(List<Id> recordId){
        try{
            Opportunity original = Database.query(allFields('Opportunity')+' Where Id =:recordId Limit 1');
            
            //Cloned Opty Record
            Opportunity clonedRec = original.Clone(false, true, false, false);
            if(clonedRec.Related_Opportunity__c!=null){
                clonedRec.Segment_Index__c = original.Segment_Index__c + 1;
            }else{
                clonedRec.Related_Opportunity__c = original.id;
                clonedRec.Segment_Index__c = 2;
            }
            clonedRec.Name = clonedRec.Name + '_NYMYYear' + clonedRec.Segment_Index__c;
            clonedRec.OP4I_Deal_Id__c = '';
            clonedRec.Deal_Type__c = 'NextYear_MultiYear';
            clonedRec.StageName = 'Pre-Funnel';
            clonedRec.OP4I_Deal_Status__c = '';
            if(clonedRec!=null){
                insert clonedRec;
            }
            System.debug('clonedRec : '+clonedRec.Id);
            
            //Cloned OptyLines
            List<OpportunityLineItem> originalOptyLines = Database.query(allFields('OpportunityLineItem')+' Where OpportunityId =:recordId');
            List<OpportunityLineItem> clonedOptyLines = new List<OpportunityLineItem>();
            for(OpportunityLineItem ql : originalOptyLines){
                if(ql!=null){
                    OpportunityLineItem clonedLineRec = ql.Clone(false, true, false, false);
                    clonedOptyLines.add(clonedLineRec);
                }
            }
            for(OpportunityLineItem ql : clonedOptyLines){
                if(ql!=null){
                    ql.OpportunityId = clonedRec.Id;
                    ql.unitprice=null;
                    ql.SBQQ__QuoteLine__c=null;
                    ql.OP4I_System_Id__c='';
                }
            }
            if(clonedOptyLines!=null){
                insert clonedOptyLines;
            }
        }
        catch(Exception e){
            System.debug('Exception : '+e);
        }
    }
    
  /**
* @description : This method will dynamic query on the sObject. 
* @author Pankaj Kumar | 09-21-2023 
* @param String ObjectName
**/    
    public static String allFields(String objectName) {
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().keySet());
        String query  = 'SELECT '+String.join(fields, ',')+' FROM '+ObjectName;
        return query;
    }
}