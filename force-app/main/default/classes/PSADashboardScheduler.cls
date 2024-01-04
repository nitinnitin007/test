global class PSADashboardScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        sendemail();
    }
    
    public void sendemail() {
	List<String> addresses = new List<String> {'anisha.dhekne@intapp.com'};
        EmailTemplate et = [SELECT id FROM EmailTemplate WHERE Name = 'PSA Dashboard'];
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        List<Contact> contacts = [SELECT Id, Name from CONTACT where Send_PSA_Dashboard__c = true];
        for(Contact contact: contacts)
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); // new mail object
             
            mail.setSenderDisplayName('Don Coleman');//Sender would be owner of Profile
         //  mail.setToAddresses(addresses);
		    //mail.setReplyTo('anisha.dhekne@intapp.com');
             
            //Notice : How I retrieve profile by passing value of current user id (using UserInfo Method)
            mail.setTargetObjectId(contact.id); //target to receipient
            mail.setTemplateId(et.id);           // pull the email template through id
            messages.add(mail);
        }
        
        Messaging.sendEmail(messages);  //send emails
    }
}