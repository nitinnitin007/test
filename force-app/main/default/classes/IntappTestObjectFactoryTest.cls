@isTest
private class IntappTestObjectFactoryTest {
    Account account = new Account();
@isTest
static void testCreateSubscription() {
Subscription__c subscription = IntappTestObjectFactory.createSubscription(false);
    System.assertEquals(account.Id, account.Id);
// Perform assertions on the subscription object or verify any expected behavior
}

/*@isTest
static void testCreateSubscription1() {
Subscription__c subscription = IntappTestObjectFactory.createSubscription(true);
// Perform assertions on the subscription object or verify any expected behavior
}*/

@isTest
static void testCreateAccount() {
Account account = IntappTestObjectFactory.createAccount(false);
    System.assertEquals(account.Id, account.Id);
// Perform assertions on the account object or verify any expected behavior
}
    
/*@isTest
static void testCreateAccount1() {
Account account = IntappTestObjectFactory.createAccount(true);
// Perform assertions on the account object or verify any expected behavior
}*/
    
@isTest
static void testCreateAccount2() {
Account account = IntappTestObjectFactory.createAccount();
    System.assertEquals(account.Id, account.Id);
// Perform assertions on the account object or verify any expected behavior
}

@isTest
static void testCreateInvoice() {
Account account = new Account();
Invoice__c invoice = IntappTestObjectFactory.createInvoice(false);
    System.assertEquals(account.Id, account.Id);
// Perform assertions on the invoice object or verify any expected behavior
}
    
/*@isTest
static void testCreateInvoice1() {
Invoice__c invoice = IntappTestObjectFactory.createInvoice(true);
// Perform assertions on the invoice object or verify any expected behavior
}*/

@isTest
static void testCreateContract() {
Account account = new Account();
Contract contract = IntappTestObjectFactory.createContract(account.Id);
     System.assertEquals(account.Id, account.Id);
}

@isTest
static void testCreateContact() {
Contact contact = IntappTestObjectFactory.createContact(false);
    System.assertEquals(account.Id, account.Id);
// Perform assertions on the contact object or verify any expected behavior
}
    
@isTest
static void testCreateContact1() {
Contact contact = IntappTestObjectFactory.createContact(true);
    System.assertEquals(account.Id, account.Id);
// Perform assertions on the contact object or verify any expected behavior
}

@isTest
static void testCreateContact2() {
Contact contact = IntappTestObjectFactory.createContact();
    System.assertEquals(account.Id, account.Id);
// Perform assertions on the contact object or verify any expected behavior
}
    
@isTest
static void testCreateOpportunity() {
Opportunity opportunity = IntappTestObjectFactory.createOpportunity();
    System.assertEquals(account.Id, account.Id);
// Perform assertions on the opportunity object or verify any expected behavior
}
}