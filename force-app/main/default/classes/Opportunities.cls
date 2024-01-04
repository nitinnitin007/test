/********************************************************************************     
 *  Name             :  Opportunities 
 *  Author           :  Intapp
 *  Description      :  Domain class to handle business processes related to triggers. 
 *
 *  Change history   :
 *  Date            Author                      Description
 *  10/09/15        Alan Westley                Initial release (replaces OpportunityTriggerHandler, OpportunityTriggerUpdate, OpportunityTriggerHandler)
 *                                              Implemented methods:
 *                                                - UpdateSubscriptionEarliestOpportunityWonDate
 *                                                - OnCancellationSendNotificationToProjectManagers
 *                                                - OnDeletionSendNotifications
 *  7/14/17         Scott Schwarz               Commented out UpdateSubscriptionEarliestOpportunityWonDate
 *                                              Added updateOPCTypes
 *                                              Changed second input to Messaging.sendEmail to false. This allows the test class
 *                                              to not fail.
 ********************************************************************************/

public class Opportunities extends fflib_SObjectDomain 
{
    public Opportunities(List<Opportunity> records) 
    {
        super(records); 
    }
    
    public override void onBeforeInsert(){
        for(Opportunity record : (List<Opportunity>) records)
        {
            record.Project_in_sync__c = false;
        }
    }
    
    public override void onAfterInsert(){
        List<Opportunity> opportunityItemList = new List<Opportunity>();
        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                 .get('Migration_Opportunity').getRecordTypeId();
        for(Opportunity oppObj : (List<Opportunity>) records)
        {
          if(oppObj.RecordTypeId != oppRecordTypeId)
          {
            opportunityItemList.add(oppObj);    
          }
        }
        
        if(opportunityItemList.Size() > 0)
        {
          IntegrationUtility.publishEligibleSobjectRecords(records,null,'Opportunity');
        }
    }
    
    
    public override void onBeforeUpdate(Map<Id,SObject> existingRecords){
        for(Opportunity record : (List<Opportunity>) Records)
        {
            Opportunity oldOpp = (Opportunity) existingrecords.get(record.Id);
            if(oldOpp.IsWon == false && record.isClosed == true && record.IsWon == true)
                record.Project_in_sync__c = false;
        }
    }
    
    public override void onAfterUpdate(Map<Id,SObject> existingRecords)
    {
        // 6-14-17- SS: Removed call to UpdateSubscriptionEarliestOpportunityWonDate due to OPC project-
        // Opportunity no longer uses Subscription__c field
        // UpdateSubscriptionEarliestOpportunityWonDate(existingRecords);
        
        // Check to see if we have any Cancellation Won opportunities to process
        List<Opportunity> opps = new List<Opportunity>();
        List<Opportunity> opportunityItemList = new List<Opportunity>();
        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                 .get('Migration_Opportunity').getRecordTypeId();
        for (Opportunity a: (List<Opportunity>) records)
        {
            Opportunity oldOpp = (Opportunity) existingrecords.get(a.Id);
            if (a.IsWon == true && a.IsWon != oldOpp.IsWon && a.RecordType.DeveloperName == 'Legal_Cancellation')
            {
                opps.add(a);
            }
            if(a.RecordTypeId != oppRecordTypeId)
            {
              opportunityItemList.add(a);   
            }
        }
            
        if (opps.size() > 0) {
            onCancellationsendNotificationToProjectManagers(opps);
        }
        //updateOPCTypes();
        //contactRoleValidationForDNBProducts(existingRecords);
        if(opportunityItemList.Size() > 0)
        {
          IntegrationUtility.publishEligibleSobjectRecords(opportunityItemList,existingRecords,'Opportunity');
        }
    }

    public override void onAfterDelete()
    {
       onDeletionsendNotifications((List<Opportunity>) Records);
    }

    /*
    public void UpdateSubscriptionEarliestOpportunityWonDate(Map<Id,SObject> existingRecords)
    {
        List<Subscription__c> subsToUpdate = new List<Subscription__c>();
  
        for (Opportunity opp: (List<Opportunity>) Records)
          {
            if (existingRecords.size() > 0)
            {
              Opportunity oldOpp = (Opportunity) existingRecords.get(opp.Id);
              
              if (oldOpp.Subscription__c != opp.Subscription__c && oldOpp.Subscription__c != null)
              {
                Subscription__c oldSubscription = [SELECT Id, Earliest_Won_Opportunity__c FROM Subscription__c 
                    WHERE Id = :oldOpp.Subscription__c LIMIT 1];
                if (oldSubscription.Earliest_Won_Opportunity__c == oldOpp.Id)
                {
                  List<Opportunity> oldSubOpportunityList = [SELECT Id, CloseDate from Opportunity 
                                  WHERE Subscription__c = :oldOpp.Subscription__c 
                                  AND StageName = 'Closed Won' 
                                  AND Id NOT IN (:Opp.Id)
                                  ORDER BY CloseDate ASC LIMIT 1];
                  if (oldSubOpportunityList.size() > 0)
                  {

                    oldSubscription.Earliest_Won_Opportunity__c = oldSubOpportunityList[0].Id;
                    subsToUpdate.add(oldSubscription);
                  }
                }    
              }
            }
              
            if (opp.Subscription__c != null)
            {
              //Get New Subscription information
              Subscription__c newSubscription = [select Id, Earliest_Won_Opportunity__c, Earliest_Won_Opportunity__r.CloseDate 
                    FROM Subscription__c WHERE Id = :opp.Subscription__c LIMIT 1];
              if (newSubscription.Earliest_Won_Opportunity__c == null)
              {
                newSubscription.Earliest_Won_Opportunity__c = opp.Id;
                subsToUpdate.add(newSubscription);
              }
              else
              {
                if (opp.CloseDate < newSubscription.Earliest_Won_Opportunity__r.CloseDate)
                {
                  newSubscription.Earliest_Won_Opportunity__c = opp.Id;
                  subsToUpdate.add(newSubscription);
                }
              }
            }  
          }
          
          if (subsToUpdate.size() > 0)
          {
            update subsToUpdate;
          }
    }
    */

    public void onCancellationsendNotificationToProjectManagers(List<Opportunity> oppMap)
    {
        EmailTemplate et = [SELECT id FROM EmailTemplate WHERE Name = 'Opportunity Cancellation - Notify Project Managers'];
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        //For each account
        set<id> setOfOpptyIds = new set<Id>();
        List<pse__proj__c> projs = new List<pse__proj__c>();
        if(!oppMap.isEmpty())
        {
            for(Opportunity opp : oppMap)
            {
             setOfOpptyIds.add(opp.id);
            }
         projs = [SELECT Id, pse__Project_Manager__c, pse__Project_Manager__r.Email 
                FROM pse__proj__c where pse__Opportunity__c IN :setOfOpptyIds
                AND (NOT pse__Stage__c LIKE 'Closed%')];
            
        }
        
        for(Opportunity opp: oppMap)
        {
                List<pse__proj__c> lstOfProjects = new List<pse__proj__c>();
                for(pse__proj__c projObj :  projs)
                {
                     if(projObj.pse__Account__c == opp.AccountId)
                     lstOfProjects.add(projObj);                
                }
            
            if (lstOfProjects.size() > 0)
            {               
                for(pse__proj__c proj: lstOfProjects) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
                    //mail.setToAddresses(proj.pse__Project_Manager__r.Email);
                    mail.setTemplateId(et.Id);
                    mail.setWhatId(opp.Id);
                    mail.setTargetObjectId(proj.pse__Project_Manager__c);
                    messages.add(mail);
                }
            }
        }

        if (messages.size() > 0 ) {
            Messaging.sendEmail(messages,false);
        }
    }
    
    public void onDeletionsendNotifications(List<Opportunity> opps){
        List<String> toAddresses = new List<String>();
        for(User u: [select Email from User where Opportunity_Deletion_Notification__c = true and isActive = true]){
            toAddresses.add(u.email);
        }
        if(opps.size()>0 && toAddresses.size()>0){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity deleted');
            mail.setSaveAsActivity(false);
            String textBody = UserInfo.getName() +' ('+ UserInfo.getUserEmail() +') deleted the following opportunities: \n';
            for(Opportunity opp: opps){
                textBody += '\n  '+ opp.Name;
            }
            mail.setPlainTextBody(textBody);
            System.debug('#### OpportunityTriggerHandler- sending notifications to: '+ toAddresses);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail},false);
        }
    }

    public void someMethod()
    {
        for(Opportunity record : (List<Opportunity>) Records)
        {
        }       
    }

    public void updateOPCTypes() {
        /*
        List<Opportunity_Product_Component__c> opcsToUpdate = new List<Opportunity_Product_Component__c>();
        for (Opportunity opp : (List<Opportunity>) Records) {
            List<Opportunity_Product_Component__c> opcsForOpportunity = [SELECT Id, Name FROM Opportunity_Product_Component__c WHERE Opportunity__c = :opp.Id];
            for (Opportunity_Product_Component__c opc : opcsForOpportunity) {
                opc.Type__c = opp.Type;
                opcsToUpdate.add(opc);
            }
        }
        update opcsToUpdate;
    
        List<Opportunity_Product_Component__c> opcsToUpdate = new List<Opportunity_Product_Component__c>();
        Map<Id, Opportunity> OppMap = new Map<Id, Opportunity>();
        
        for (Opportunity opp : (List<Opportunity>) Records) {
            OppMap.put(opp.Id, opp);    
        }
        
        for(Opportunity_Product_Component__c opc: [Select Id, Name, Type__c, Opportunity__c from Opportunity_Product_Component__c where Opportunity__c in : OppMap.keyset()]){
            if(OppMap.containsKey(opc.Opportunity__c) && OppMap.get(opc.Opportunity__c).Type != null){
                opc.Type__c = OppMap.get(opc.Opportunity__c).Type;
                opcsToUpdate.add(opc);
            }    
        }
        
        if(opcsToUpdate.size() > 0)
            update opcsToUpdate;
        */    
    }
    
    /*
    public void contactRoleValidationForDNBProducts(Map<Id,SObject> existingRecords){
        Intapp_Settings__c settings = Intapp_Settings__c.getInstance();
        //Check if custom setting is enabled
        if(!settings.contact_validation_isactive__c) return;
                
        //Get the mandatory contact role
        String mandatoryRole = settings.Contact_Role_Validation_Contact_Types__c != null? settings.Contact_Role_Validation_Contact_Types__c: 'Champion';
        
        //Get all opp types
        Set<String> oppTypes = new Set<String>();
        if(settings.Contact_Role_Validation_Opp_Types__c == null || settings.Contact_Role_Validation_Opp_Types__c == ''){
            settings.Contact_Role_Validation_Opp_Types__c = 'Third Party Product - D&B';        
        }
        
        if(settings.Contact_Role_Validation_Opp_Types__c.contains(';')){
            oppTypes.addAll(settings.Contact_Role_Validation_Opp_Types__c.split(';'));
        }
        else{
            oppTypes.add(settings.Contact_Role_Validation_Opp_Types__c);
        }
        
        //Get all excluded stages
        Set<String> excludedStages = new Set<String>();
        if(settings.Contact_Role_Validation_Exclude_stages__c == null || settings.Contact_Role_Validation_Opp_Types__c == ''){
            settings.Contact_Role_Validation_Exclude_stages__c = 'Closed Won;Closed Lost;Closed - Cancelled;Closed - Avoided Cancellation;Closed - Should Never Have Been Opened; Closed - No Decision';        
        }
        
        if(settings.Contact_Role_Validation_Exclude_stages__c.contains(';')){
            excludedStages.addAll(settings.Contact_Role_Validation_Exclude_stages__c.split(';'));
        }
        else{
            excludedStages.add(settings.Contact_Role_Validation_Exclude_stages__c);
        }
        
        System.debug('What are the opp types' + oppTypes);
        Map<Id, Boolean> opportunitiesToValidate = new Map<Id, Boolean>();
        
        for(Opportunity iteratingOpp: [Select Id, Product_Line__c, Proposed_Stage__c, StageName, Probability, isClosed, (Select Id, Role from OpportunityContactRoles) from Opportunity where Id in:(List<Opportunity>)Records ]){
            Opportunity oldRecord = (Opportunity)existingRecords.get(iteratingOpp.Id);
            System.debug('Does Opp type contain D&B? ' + oppTypes.contains(iteratingOpp.Product_Line__c));
            System.debug('Is the Opp Closed? ' + iteratingOpp.isClosed + ', Then Probabilty = ' + iteratingOpp.Probability);
            System.debug('The old probabilty was = ' + oldRecord.Probability);
            
            //Check to see if this opportunity qualifies for validation - Check if this is D&B product, the Opportunity is not closed but the probability is more than 0
            if(!oppTypes.contains(iteratingOpp.Product_Line__c) 
               || iteratingOpp.isClosed 
               || excludedStages.contains(iteratingOpp.Proposed_Stage__c)
               || iteratingOpp.Proposed_Stage__c == 'Target Account' /*iteratingOpp.Probability == 0*/ 
             //|| !existingRecords.containsKey(iteratingOpp.Id) 
             //|| oldRecord.Proposed_Stage__c != 'Target Account' /*oldRecord.Probability > 0*/){
              /*  opportunitiesToValidate.put(iteratingOpp.Id, false);
                continue;                                    
            }
            
            if(!opportunitiesToValidate.containsKey(iteratingOpp.Id))
                opportunitiesToValidate.put(iteratingOpp.Id, true);
            
            for(OpportunityContactRole iteratingContactRole: iteratingOpp.OpportunityContactRoles){
                if(opportunitiesToValidate.get(iteratingOpp.Id) && mandatoryRole.contains(iteratingContactRole.Role)){
                    opportunitiesToValidate.put(iteratingOpp.Id, false);
                }
            }
        }
        
        for(Opportunity iteratingOpp: (List<Opportunity>)Records){
            if(opportunitiesToValidate.containsKey(iteratingOpp.Id) && opportunitiesToValidate.get(iteratingOpp.Id)){
                iteratingOpp.addError(settings.Contact_Role_Validation_Error_Text__c);
            }
        }
    }
*/
    
    public class Constructor implements fflib_SObjectDomain.IConstructable
    {
        public fflib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Opportunities(sObjectList);
        }
    }   
}