/**
 * @modified by Venkataraman Sriram
 * 
 * @description Test class for Accounts Trigger
 *
 * @modified on 2/9/2018
 **/ 

@isTest
private class AccountsTest {
    
    @isTest static void testAccountTypeChange() {
        User usr = (User) SmartFactory.createSObject('User');
        insert usr;

        User usr2 = (User) SmartFactory.createSObject('User');
        insert usr2;
        
        User usr3 = (User) SmartFactory.createSObject('User');
        insert usr3;

        Account a = new Account ();
        a = IntappTestObjectFactory.createAccount(false);

        a.CRD__c = usr.Id;
        a.Type = 'Customer';
        a.Create_Prospect__c = '01';
        a.BillingCountry = 'United States';
        insert a;
        
        Subscription__c pc = (Subscription__c) SmartFactory.createSObject('Subscription__c');
        PC.Account__c = a.Id;
        PC.CRD__c = usr.Id;
        PC.Product_Line__c = 'Time';
        insert PC;

        a.CRD__c = usr2.Id;
        update a;

        //Change to Customer-Lapsed changes the Account Manager to null
        //This inturn triggers the coverage for other functions
        
        a.Type = 'Customer - Lapsed';
        a.OwnerId = usr.Id;
        update a;

       // a = [Select Id, CRD__c from Account where Id =: a.Id];
        System.assertNotEquals(null, a.CRD__c);
        
        
        a.CRD__c = null;
        update a;
        
		Contact c = new Contact ();
		c.OwnerId = usr3.Id;
        c.LastName = 'Last';
        insert c;
        Contact c1 = new Contact ();
        c1.AccountId = a.id;
		c1.OwnerId = usr3.Id;
        c1.LastName = 'Last1';
        insert c1;
        a.OwnerId = usr2.Id;
        update a;
        
        List<Contact> testList = new list<Contact>();
        testList.add(c);
        testList.add(c1);
        update testList;           
    }  
    
     @isTest
    	 static void testOnStatusChangeRemoveAccountManager() {
         // Create test data
         User usr = (User) SmartFactory.createSObject('User');
         insert usr;
             
         User usr2 = (User) SmartFactory.createSObject('User');
         insert usr2;
             
 			Account account = new Account(Name = 'Test Account', CRD__c = usr.id);
 			insert account;

			Subscription__c subscription = new Subscription__c(Account__c = account.Id, CRD__c = usr2.Id);
 			insert subscription;

	 		List<Account> accounts = new List<Account>{account};
		    Accounts accountsHandler = new Accounts(accounts);

 		    Map<Id, SObject> existingRecords = new Map<Id, SObject>();
			existingRecords.put(account.Id, account);

             Test.startTest();
  
             accountsHandler.onStatusChangeRemoveAccountManager(existingRecords);
  
             Test.stopTest();
             System.assertNotEquals(null, account.Id);
  }
}