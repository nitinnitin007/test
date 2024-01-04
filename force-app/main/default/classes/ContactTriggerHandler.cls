/********************************************************************************     
 *  Name             :  ContactTriggerHandler
 *  Description      :  1. Notifies admins when an contact is deleted
 *                                  
 *  Change history   :
 *  Date                Author                          Description
 *  11/29/16            Mitali Machra                   Created
 *  Need to add custom setting to add new users
 ********************************************************************************/
public class ContactTriggerHandler {

    public static void sendContactDeletedNotification(List <Contact> contacts){
        List<String> toAddresses = new List<String>();
        for(User u: [select email from User where Contact_Deletion_Notification__c = true and isActive = true]){
            toAddresses.add(u.email);
        }
        if(contacts.size()>0 && toAddresses.size()>0){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSubject('Contact deleted');
            mail.setSaveAsActivity(false);
            String textBody = UserInfo.getName() +' ('+ UserInfo.getUserEmail() +') deleted the following contacts: \n';
            for(contact contact1: contacts)
            {
                //textBody += '\n  Contact ID: '+ contact1.Id;
                textBody += '\n ' + contact1.FirstName + ' ' + contact1.LastName;
            }
            mail.setPlainTextBody(textBody);
            System.debug('#### ContactTriggerHandler- sending notifications to: '+ toAddresses);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        }
    }
    
    
    public static void disablePortalUserCheck(List<Contact> contacts) {
        /*
        List<User> usersToUpsert = new List<User>();
        
        for (Contact c: contacts) {
            if (c.PortalAccountNew__c == 'AccountDeprovisioned') {
                User u = [SELECT Id from User where ContactID = :c.Id LIMIT 1];
                u.IsActive = false;
                //u.Title = 'aaab';
                usersToUpsert.add(u);
                //DebugLogger__c d = new DebugLogger__c();
                //d.LogText__c = u.Id;
                //insert d;
            }
        }
        //DebugLogger__c d = new DebugLogger__c();
        //d.LogText__c = 'test3';
        //insert d;
        //update usersToUpsert;   
        */     
    }
    
    public Static void contactAfterInsert(list<contact> contactNewList) {
      IntegrationUtility.publishEligibleSobjectRecords(contactNewList,null,'Contact');
    }
    
    public Static void contactAfterUpdate(list<contact> contactNewList, Map<Id,contact> contactOldMap) {
      IntegrationUtility.publishEligibleSobjectRecords(contactNewList,contactOldMap,'Contact');
    }
}