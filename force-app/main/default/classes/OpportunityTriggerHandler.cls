/********************************************************************************     
 *  Name             :  OpportunityTriggerHandler
 *  Author           :  Hiforte Technologies
 *  Description      :  1. Notifies users when an opportunity is deleted
 *                      2. Populates the fields-Value of Open opportunities,Value of Closed Won opportunities &
 *                         Value of Target Account opportunities in the Campaign object by calculating the summation of the 
  *                        recurring amount values of the associated opportunities.                             
 *  Change history   :
 *  Date                Author                          Description
 *  05/30/14        Vasu Pulipati                       Created
 * 03/29/2018       Anisha Dhekne                       Added populateValueofOpportunities method
 *  10/9/15         FUNCTIONALITY MOVED TO OPPORTUNITES CLASS. NO LONGER USED!
 ********************************************************************************/
public class OpportunityTriggerHandler {

    //public static void sendOpportunityDeletedNotification(List<Opportunity> opps) {
    //List<String> toAddresses = new List<String> ();
    //for (User u :[select email from User where Opportunity_Deletion_Notification__c = true and isActive = true]) {
    //toAddresses.add(u.email);
    //}
    //if (opps.size() > 0 && toAddresses.size() > 0) {
    //Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //mail.setToAddresses(toAddresses);
    //mail.setSubject('Opportunity deleted');
    //mail.setSaveAsActivity(false);
    //String textBody = UserInfo.getName() + ' (' + UserInfo.getUserEmail() + ') deleted the following opportunities: \n';
    //for (Opportunity opp : opps) {
    //textBody += '\n  ' + opp.Name;
    //}
    //mail.setPlainTextBody(textBody);
    //System.debug('#### OpportunityTriggerHandler- sending notifications to: ' + toAddresses);
    ////    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    //}
    //}

    // Method to calculate vaLue of opportunities
    public static void populateValueofOpportunities(List<Opportunity> newOpportunity)
    {
	/*
        List<Campaign> CampaignsToUpdate = new List<Campaign> ();
        List<Id> CampaignIds = new List<Id> ();
        if (Trigger.isInsert || Trigger.isUpdate)
        {
            for (Opportunity opp : newOpportunity) {
                CampaignIds.add(opp.CampaignId);
            }
            for (Campaign camp :[Select Id, Value_of_Target_Account_opportunities__c, Value_of_Open_opportunities__c, Value_of_Closed_Won_opportunities__c, (SELECT Maintenance_Amount__c, StageName, Simple_Stage__c FROM Opportunities) From Campaign where Id in :CampaignIds]) {
                camp.Value_of_Target_Account_opportunities__c = 0;
                camp.Value_of_Open_opportunities__c = 0;
                camp.Value_of_Closed_Won_opportunities__c = 0;


                for (Opportunity oppo : camp.Opportunities)
                { 
                    //Populate the field value of Target Account opportunities
                    if (oppo.Maintenance_Amount__c != null && oppo.StageName.equals('Target Account')) {

                        camp.Value_of_Target_Account_opportunities__c += oppo.Maintenance_Amount__c;
                   
                    }
                    else if(Trigger.isDelete) {camp.Value_of_Target_Account_opportunities__c -= oppo.Maintenance_Amount__c;}
                    //Populate the field value of Open opportunities
                    if (oppo.Maintenance_Amount__c != null && oppo.Simple_Stage__c.equals('Open') && oppo.StageName != 'Target Account') {
                        camp.Value_of_Open_opportunities__c += oppo.Maintenance_Amount__c;
                    }
                    //Populate the field value of Closed Won opportunities
                    if (oppo.Maintenance_Amount__c != null && oppo.StageName.equals('Closed Won')) {
                        camp.Value_of_Closed_Won_opportunities__c += oppo.Maintenance_Amount__c;
                    }
                }

                CampaignsToUpdate.add(camp);
            }
            
            if (CampaignsToUpdate.size() > 0) {
                update CampaignsToUpdate;
            }

        }
	*/
    }
}