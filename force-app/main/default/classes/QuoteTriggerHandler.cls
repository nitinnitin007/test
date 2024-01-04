public class QuoteTriggerHandler {
    
   public static void processRecordsBeforeInsert(List<SBQQ__Quote__c> quotes){

            Set<String> salesSegments = new Set<String>();
        for(SBQQ__Quote__c quote : quotes){
            salesSegments.add(quote.OP4I_Sales_Segment__c);    
        }
        
        Map<String, ApproverUsers> approverUsersMap = ApproverMatrixService.getApproverUsers(salesSegments) ;
        
        for(SBQQ__Quote__c quote : quotes){
        
        /** Changes BIZ-723 : Start **/             
             // Added to Set "First Segment Term End Date" -sun
             /*MDQIssueCommenting
             if (quote.First_Segment_Months__c != null && quote.SBQQ__StartDate__c != null){
                 quote.SBQQ__FirstSegmentTermEndDate__c = quote.SBQQ__StartDate__c.addMonths(Integer.valueOf(quote.First_Segment_Months__c))-1 ;
             } */   
       /**Changes BIZ-723 : End **/
            
            if(approverUsersMap.Containskey(quote.OP4I_Sales_Segment__c)){                
            
            ApproverUsers approverUsers = approverUsersMap.get(quote.OP4I_Sales_Segment__c);
            quote.COO__c = approverUsers.COO;
            quote.SVP_Services__c = approverUsers.SVP_Services;
            quote.Segment_Lead__c = approverUsers.Segment_Lead;
            quote.Industry_Sales_Lead__c = approverUsers.Industry_Sales_Lead;
            quote.SVP_Sales__c = approverUsers.SVP_Sales;
            quote.Industry_President__c = approverUsers.Industry_President;
            quote.Services_Segment_Lead__c = approverUsers.Services_Segment_Lead;
            }
        }
        
 }

    public static void processRecordsBeforeUpdate(Map<Id, SBQQ__Quote__c> oldQuotesMap, Map<Id, SBQQ__Quote__c> newQuotesMap){
        
        /** Changes BIZ-723 : Start **/
        /*MDQIssueCommenting     
        for(SBQQ__Quote__c quote : newQuotesMap.values()){
             // Added to Set "First Segment Term End Date" -sun
            SBQQ__Quote__c quoteOld = oldQuotesMap.get(quote.Id);
             if (quote.First_Segment_Months__c != null && quote.SBQQ__StartDate__c != null && 
                 (quote.First_Segment_Months__c != quoteOld.First_Segment_Months__c  || quote.SBQQ__StartDate__c  != quoteOld.SBQQ__StartDate__c)
             ){
                     quote.SBQQ__FirstSegmentTermEndDate__c = quote.SBQQ__StartDate__c.addMonths(Integer.valueOf(quote.First_Segment_Months__c))-1 ;
             }           
            
        }*/    
        /** Changes BIZ-723 : End **/   
        // Set of all the sales segments which got changed.
        Set<String> salesSegments = new Set<String>();
        
        // Re-assign approvers only to only quotes where sales segment changed.
        List<Id> quoteIdsToBeProcessed = new List<Id>();

        Generic_Key_Value_Setting__mdt approvalErrorMaxRetrySetting = Generic_Key_Value_Setting__mdt.getInstance('Approval_Error_Max_Retry');
        Integer approvalErrorMaxRetry = Integer.valueOf(approvalErrorMaxRetrySetting.Value__c);
                    
        
        // Loop through all the new quotes and get the set of sales segment and 
        // the quotes to be processed 
        for(Id quoteId : newQuotesMap.keySet()){
            System.debug ('Logging status ' + oldQuotesMap.get(quoteId).ApprovalStatus__c + ' Newstatus ' + newQuotesMap.get(quoteId).ApprovalStatus__c + ' counter '+newQuotesMap.get(quoteId).Counter__c );

            if(oldQuotesMap.get(quoteId).ApprovalStatus__c == 'Error'
                && newQuotesMap.get(quoteId).ApprovalStatus__c == 'Pending'
                && newQuotesMap.get(quoteId).Counter__c >= approvalErrorMaxRetry){
                    SBQQ__Quote__c quote = newQuotesMap.get(quoteId);
                    quote.Counter__c = 0;
                }

            if(oldQuotesMap.get(quoteId).OP4I_Sales_Segment__c 
                != newQuotesMap.get(quoteId).OP4I_Sales_Segment__c){
                    salesSegments.add(newQuotesMap.get(quoteId).OP4I_Sales_Segment__c);
                    quoteIdsToBeProcessed.add(quoteId);
                }
        }
        
        // get the map of sales segment and the related approvers
        Map<String, ApproverUsers> approverUsersMap = ApproverMatrixService.getApproverUsers(salesSegments) ;
        
        // Loop through all the quotes to be processed.
        // Get the new quote from the map.
        // Assign the value from the 'sales segment to approvers map'.
        for(Id quoteId : quoteIdsToBeProcessed){
            SBQQ__Quote__c quote = newQuotesMap.get(quoteId);
            ApproverUsers approverUsers = approverUsersMap.get(quote.OP4I_Sales_Segment__c);
            
            if(approverUsers != null) {
            quote.COO__c = approverUsers.COO;
            quote.SVP_Services__c = approverUsers.SVP_Services;
            quote.Segment_Lead__c = approverUsers.Segment_Lead;
            quote.Industry_Sales_Lead__c = approverUsers.Industry_Sales_Lead;
            quote.SVP_Sales__c = approverUsers.SVP_Sales;
            quote.Industry_President__c = approverUsers.Industry_President;
            quote.Services_Segment_Lead__c = approverUsers.Services_Segment_Lead;  
            }
        }
    } 

    public Static void quoteAfterInsert(list<SBQQ__Quote__c> quoteNewList) {
        IntegrationUtility.publishEligibleSobjectRecords(quoteNewList,null,'SBQQ__Quote__c');
    }
    
    public Static void quoteAfterUpdate(list<SBQQ__Quote__c> quoteNewList,Map<Id,SBQQ__Quote__c> quoteOldMap) {
        IntegrationUtility.publishEligibleSobjectRecords(quoteNewList,quoteOldMap,'SBQQ__Quote__c');
    }
    
    
    
}