/********************************************************************************     
 *  Name             :  OpportunityTrigger
 *  Author           :  Anisha Dhekne
 *  Description      :  Calls the OpportunityTriggerHandler Class
 *                                  
 *  Change history   :
 *  Date                Author                          Description
 *  05/30/14        Vasu Pulipati                         Created
 * 03/29/2018       Anisha Dhekne                       Added populateValueofOpportunities
 ********************************************************************************/
trigger OpportunityTrigger on Opportunity (before delete, after insert, after update) {
    //if(trigger.isAfter && trigger.isDelete){
        //System.debug('#### Opportunity trigger- opps deleted: '+ trigger.old.size());
        //OpportunityTriggerHandler.sendOpportunityDeletedNotification(trigger.old);
    //}
     
    OpportunityTriggerHandler.populateValueofOpportunities(trigger.new);
}