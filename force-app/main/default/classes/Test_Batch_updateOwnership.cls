@isTest
private class Test_Batch_updateOwnership {

    static testmethod void test_DC() {
    
    // Create test accounts to be updated
    // by the batch job.
    
        List<Account> accList = new List<Account>();
        for (Integer i=0;i<200;i++) {
            Account m = new Account(Name = 'Account ' + i, Type = 'DealCloud Customer');
            accList.add(m);
        }
        insert accList;
        
        Test.startTest();
            Batch_updateOwnership_DC c = new Batch_updateOwnership_DC('');
            Database.executeBatch(c);
        Test.stopTest();
        
        // Verify accounts updated
        Account[] accUpdatedList = [SELECT Id,Name,Dealcloud__c FROM Account];
        System.assertEquals('DealCloud', accUpdatedList[0].DealCloud__c);
    }
    
    static testmethod void test_nonDC() {
    
    // Create test accounts to be updated
    // by the batch job.
    
        List<Account> accList = new List<Account>();
        for (Integer i=0;i<1;i++) {
            Account m = new Account(Name = 'Account ' + i, Type = 'Customer');
            accList.add(m);
        }
        insert accList;
        
        List<Product_Ownership_Detail__c> podList = new List<Product_Ownership_Detail__c>();
        
        Product_line__c experience = new Product_Line__c();
        experience.Name = 'Experience - Cloud';
        experience.Simple_Product_Line__c = 'Experience';
        experience.Active__c = true;
        insert experience;
        
        Product_line__c crm = new Product_Line__c();
        crm.Name = 'CRM - Cloud';
        crm.Simple_Product_Line__c = 'CRM';
        crm.Active__c = true;
        insert crm;
        
        Product_line__c legalKey = new Product_Line__c();
        legalKey.Name = 'LegalKey - Legacy';
        legalKey.Simple_Product_Line__c = 'TFG - Other';
        legalKey.Active__c = true;
        insert legalKey;
        
        License_Basis__c crm_cloud = new License_Basis__c();
        crm_cloud.Name = 'CRM - Cloud';
        crm_cloud.Product_Line__c = crm.id;
        crm_cloud.Highest_Package__c = true;
        insert crm_cloud;
        
        for(Account a: accList){
            Product_Ownership_Detail__c pod_experience = new Product_Ownership_Detail__c();
            pod_experience.Product_line_link__c = legalKey.Id;
            pod_experience.Account_Name__c = a.Id;
            pod_experience.Status__c = 'Own it - Trial';
            pod_experience.Support_Level__c = 'Standard (Silver)';
            podList.add(pod_experience);
            
            /*
            Product_Ownership_Detail__c pod_crm = new Product_Ownership_Detail__c();
            pod_crm.Product_line_link__c = crm.Id;
            pod_crm.Account_Name__c = a.Id;
            pod_crm.Status__c = 'Own it';
            pod_crm.Support_Level__c = 'Standard (Silver)';
            pod_crm.License_basis_link__c = crm_cloud.id;
            
            podList.add(pod_crm);
			*/
        }
        
        insert podList;
        
        Test.startTest();
            Batch_updateOwnership_nonDC c = new Batch_updateOwnership_nonDC('');
            Database.executeBatch(c);
        Test.stopTest();
        
            // Verify accounts updated
        Account[] accUpdatedList = [SELECT Id,Name,Experience__c,TFG_Other__c, LegalKey__c FROM Account];
        System.assertEquals('LegalKey - On Prem', accUpdatedList[0].LegalKey__c);
        
    }
    
    static testmethod void test_nonDC2() {
        List<Account> accList = new List<Account>();
        List<Product_Ownership_Detail__c> podList = new List<Product_Ownership_Detail__c>();
        
        for (Integer i=0;i<1;i++) {
            Account m = new Account(Name = 'Account ' + i, Type = 'Customer', TFG_Other__c = 'LegalKey - Legacy');
            accList.add(m);
        }
        insert accList;
        
        Product_line__c legalKey = new Product_Line__c();
        legalKey.Name = 'LegalKey - Legacy';
        legalKey.Simple_Product_Line__c = 'TFG - Other';
        legalKey.Active__c = true;
        insert legalKey;
        
        for(Account a: accList){
            Product_Ownership_Detail__c pod_experience = new Product_Ownership_Detail__c();
            pod_experience.Product_line_link__c = legalKey.Id;
            pod_experience.Account_Name__c = a.Id;
            pod_experience.Status__c = 'Lapsed';
            pod_experience.Support_Level__c = 'Standard (Silver)';
            podList.add(pod_experience);
        }
        
        insert podList;
        
        Test.startTest();
            Batch_updateOwnership_nonDC c = new Batch_updateOwnership_nonDC('');
            Database.executeBatch(c);
        Test.stopTest();
    }
    
    static testmethod void test_scheduler_DC(){
        List<Account> accList = new List<Account>();
        for (Integer i=0;i<200;i++) {
            Account m = new Account(Name = 'Account ' + i, Type = 'DealCloud Customer');
            accList.add(m);
        }
        insert accList;
        String CRON_EXP = '0 0 0 15 3 ? *';
        String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, new Batch_updateOwnership_DC_scheduler());
    }
    
    static testmethod void test_scheduler_nonDC(){
        List<Account> accList = new List<Account>();
        for (Integer i=0;i<1;i++) {
            Account m = new Account(Name = 'Account ' + i, Type = 'Customer');
            accList.add(m);
        }
        insert accList;
        
        List<Product_Ownership_Detail__c> podList = new List<Product_Ownership_Detail__c>();
        
        Product_line__c experience = new Product_Line__c();
        experience.Name = 'Experience - Cloud';
        experience.Simple_Product_Line__c = 'Experience';
        experience.Active__c = true;
        insert experience;
        
        Product_line__c crm = new Product_Line__c();
        crm.Name = 'CRM - Cloud';
        crm.Simple_Product_Line__c = 'CRM';
        crm.Active__c = true;
        insert crm;
        
        Product_line__c legalKey = new Product_Line__c();
        legalKey.Name = 'LegalKey - Legacy';
        legalKey.Simple_Product_Line__c = 'TFG - Other';
        legalKey.Active__c = true;
        insert legalKey;
        
        License_Basis__c crm_cloud = new License_Basis__c();
        crm_cloud.Name = 'CRM - Cloud';
        crm_cloud.Product_Line__c = crm.id;
        crm_cloud.Highest_Package__c = true;
        insert crm_cloud;
        
        for(Account a: accList){
            Product_Ownership_Detail__c pod_experience = new Product_Ownership_Detail__c();
            pod_experience.Product_line_link__c = legalKey.Id;
            pod_experience.Account_Name__c = a.Id;
            pod_experience.Status__c = 'Own it - Trial';
            pod_experience.Support_Level__c = 'Standard (Silver)';
            podList.add(pod_experience);
            
            /*
            Product_Ownership_Detail__c pod_crm = new Product_Ownership_Detail__c();
            pod_crm.Product_line_link__c = crm.Id;
            pod_crm.Account_Name__c = a.Id;
            pod_crm.Status__c = 'Own it';
            pod_crm.Support_Level__c = 'Standard (Silver)';
            pod_crm.License_basis_link__c = crm_cloud.id;
            
            podList.add(pod_crm);
			*/
        }
        
        insert podList;

        String CRON_EXP = '0 0 0 15 3 ? *';
        String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, new Batch_updateOwnership_nonDC_scheduler());
    }
}