@isTest
private class AccountMergeBatchTest {

    @isTest
    static void testBatchExecution() {
        List<Account> accountList = new List<Account>();
        Account survivingAccount = IntappTestObjectFactory.createAccount(false);
        accountList.add(survivingAccount);
        
        Account mergeAccount = IntappTestObjectFactory.createAccount(false);
        accountList.add(mergeAccount);
        
        Account survivingAccount2 = IntappTestObjectFactory.createAccount(false);
        accountList.add(survivingAccount2);
        
        Account mergeAccount2 = IntappTestObjectFactory.createAccount(false);
        accountList.add(mergeAccount2);
        
        insert accountList;
        
        Contact contact = IntappTestObjectFactory.createContact(false);
        contact.AccountId = survivingAccount.id;
        insert contact;
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        AccountContactRelation acr = new AccountContactRelation(
            AccountId = survivingAccount.Id,
            ContactId = contact.Id
        );
        //acrList.add(acr);
        
        AccountContactRelation acr2 = new AccountContactRelation(
            AccountId = mergeAccount.Id,
            ContactId = contact.Id
        );
        acrList.add(acr2);
        insert acrList;
        
        // Create test data - ContentVersion with CSV data
        ContentVersion content = new ContentVersion(
            Title = 'test.csv',
            PathOnClient = 'test.csv',
            VersionData = Blob.valueOf(survivingAccount.Id+ ','+ mergeAccount.Id + '\n' + survivingAccount2.Id + ',' + mergeAccount2.Id)
        );
        insert content;

        // Start the batch job
        AccountMergeBatch.RecordIdentifier recordIdentity = AccountMergeBatch.RecordIdentifier.Id;
        Test.startTest();
        AccountMergeBatch batch = new AccountMergeBatch('test.csv', recordIdentity);
        Id batchJobId = Database.executeBatch(batch);
        Test.stopTest();

        // Query the results and validate
        List<Account> survivingAccounts = [SELECT Id, IntApp_Account_Number__c FROM Account WHERE Id = :survivingAccount.Id LIMIT 1];
        List<Account> mergeAccounts = [SELECT Id, IntApp_Account_Number__c FROM Account WHERE Id = :mergeAccount.Id LIMIT 1];

        System.assertEquals(1, survivingAccounts.size(), 'Surviving account not found');
        System.assertEquals(0, mergeAccounts.size());
        System.assertEquals(1, [SELECT Id from AccountContactRelation].size());
        
        
        // Ensure the batch job completed successfully
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :batchJobId LIMIT 1];
        System.assertEquals('Completed', job.Status, 'Batch job did not complete successfully');
    }   
}