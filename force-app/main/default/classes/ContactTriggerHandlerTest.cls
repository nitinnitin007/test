/********************************************************************************     
 *  Name             :  ContactTriggerHandler
 *  Description      :  1. Notifies admins when an contact is deleted
 *                                  
 *  Change history   :
 *  Date                Author                          Description
 *  11/29/16            Anisha Dhekne                   Created test class for Contact Trigger
 * 
 ***************************************************************************************************/
@isTest
class ContactTriggerHandlerTest {
	//Test method to verify sendContactDeletedNotification
	@isTest
	static void testsendContactDeletedNotification() {
		List<User> list_User = new List<User> ();
		List<Contact> list_contacts = new List<Contact> ();

		Account acc1 = new Account();
		acc1 = IntappTestObjectFactory.createAccount(false);

		acc1.Name = 'test';
		insert acc1;

		User usr1 = (User) SmartFactory.createSObject('User');
		//usr1.ContactId = [Select Id from Contact LIMIT 1].Id;
		usr1.Contact_Deletion_Notification__c = true;
		usr1.isActive = true;
		usr1.Email = 'anisha.dhekne@intapp.com';
		list_User.add(usr1);
		insert list_User;

		Contact con1 = (Contact) SmartFactory.createSObject('Contact');
		//	con1.Id = [Select Id from Contact LIMIT 1].Id;
		con1.AccountId = acc1.Id;
		con1.FirstName = 'testfirstname';
		con1.LastName = 'testlastname';
		con1.CurrencyIsoCode = 'USD';
		list_contacts.add(con1);

		insert list_contacts;


		System.runAs(usr1)
		{

			delete list_contacts;
		}

	}
}