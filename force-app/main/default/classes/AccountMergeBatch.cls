global with sharing class AccountMergeBatch implements Database.Batchable<AccountMergeBatch.AccountDetail> {
    global Enum RecordIdentifier {
        ID,
        INTAPPACCOUNTNUMBER
    }

    RecordIdentifier recordIdentity;
    string fileName;

    global AccountMergeBatch(string fileName, RecordIdentifier recordIdentity) {
        this.recordIdentity = recordIdentity;
        this.fileName = fileName;

    }

    global Iterable<AccountMergeBatch.AccountDetail> start(Database.BatchableContext bc){
        List<AccountDetail> accountDetailList = new List<AccountDetail>();
        List<ContentVersion> contentVersionList = [
            SELECT Id
                 , VersionData
                 , ContentDocument.Title 
              FROM ContentVersion 
             WHERE ContentDocument.Title = :fileName 
             ORDER BY createdDate desc 
             LIMIT 1
        ];

        //system.debug(contentVersion.VersionData.tostring());
        if (!contentVersionList.isEmpty()) {
            String fileData = contentVersionList[0].VersionData.tostring();
            if (string.isNotBlank(fileData)) {
                list<string> rows = fileData.split('\n');
                system.debug('rows--->'+rows);
                system.debug('rows size--->'+rows.size());
                for (string row : rows) {
                    list<string> cols = row.replace('"','').split(',');
                    system.debug('cols--->'+cols);
                    system.debug('cols size--->'+cols.size());
                    if (cols.size() == 2) {
                        AccountDetail  accountDetail = new AccountDetail(cols[0].trim(),cols[1].trim());
                        accountDetailList.add(accountDetail);
                    }
                }
            }
        }

        system.debug('accountDetailList--->'+accountDetailList);
        return accountDetailList;  
    }

    global void execute(Database.BatchableContext bc, List<AccountDetail> accountDetailList){
        Set<string> servivingIds = new set<string>();
        Set<string> mergeIds = new set<string>();
        Set<string> accountIds = new set<string>();
        for(AccountDetail accountDetail : accountDetailList){
            accountIds.add(accountDetail.servivingId);
            accountIds.add(accountDetail.mergeId);
        }

        String query = '' 
                    + ' SELECT Id'
                    + '      , Name'
            		+ '      , IntApp_Account_Number__c'
                    + '   FROM Account';

        String accountQuery = query +
            (RecordIdentifier.Id == recordIdentity? 
            ' WHERE Id IN :accountIds': 
            ' WHERE IntApp_Account_Number__c IN :accountIds'); 


        String mergeAccountQuery = query +
            (RecordIdentifier.Id == recordIdentity? 
            ' WHERE Id IN :mergeIds': 
            ' WHERE IntApp_Account_Number__c IN :mergeIds') 
            + ' Limit 1'; 

        map<string,Account> accountMap = new map<string,Account>();
        for (Account account : (List<Account>)dataBase.query(accountQuery)) {
            if (RecordIdentifier.ID == recordIdentity) {
                accountMap.put(account.Id,account);
            } else {
                accountMap.put(account.IntApp_Account_Number__c,account);
            }
        }

        if (!accountMap.isEmpty()) {
            set<Id> servivingAccountIds = new set<Id>();
            set<Id> mergeAccountIds = new set<Id>();
            map<Id,Id> mergeToservivingMap = new map<Id,Id>();
            for(AccountDetail accountDetail : accountDetailList){
                if (!accountMap.containsKey(accountDetail.servivingId)) {
                    System.debug(accountDetail.servivingId + ' Surving Account Was Not Found.');
                } else if (!accountMap.containsKey(accountDetail.mergeId)) {
                    System.debug(accountDetail.mergeId + ' Merge Account Was Not Found.');
                } else {
                    servivingAccountIds.add(accountMap.get(accountDetail.servivingId).Id);
                    mergeAccountIds.add(accountMap.get(accountDetail.mergeId).Id);
                    mergeToservivingMap.put(accountMap.get(accountDetail.mergeId).Id,accountMap.get(accountDetail.servivingId).Id);
                }
            }

            if (!servivingAccountIds.isempty()) {
                map<String,AccountContactRelation> accountContactRelationIds = new map<String,AccountContactRelation>();
                set<Id> contactIds = new set<Id>();
                for (AccountContactRelation serAccRelCon : [
                    SELECT Id
                         , AccountId
                         , ContactId
                         , IsDirect
                      FROM AccountContactRelation
                      WHERE AccountId IN :servivingAccountIds
                ]) {
                    accountContactRelationIds.put(serAccRelCon.AccountId + '-' +  serAccRelCon.ContactId,serAccRelCon);
                    contactIds.add(serAccRelCon.ContactId);
                }

                if (!contactIds.isEmpty()) {
                    list<AccountContactRelation> accountContactRelationList = new list<AccountContactRelation>();
                    for (AccountContactRelation mergAccRelCon : [
                        SELECT Id
                            , AccountId
                            , ContactId
                            , IsDirect
                         FROM AccountContactRelation
                        WHERE AccountId IN :mergeAccountIds
                          AND ContactId IN :contactIds
                    ]) {
                        
                        Id servAccId = mergeToservivingMap.get(mergAccRelCon.AccountId);
                        if (accountContactRelationIds.containsKey(servAccId + '-' + mergAccRelCon.ContactId)) {
                            if (mergAccRelCon.IsDirect == false) {
                                accountContactRelationList.add(mergAccRelCon);
                            } else {
                                accountContactRelationList.add(accountContactRelationIds.get(servAccId + '-' + mergAccRelCon.ContactId));
                            }
                        }
                        
                    }

                    if (!accountContactRelationList.isEmpty()) {
                        HandleCustomException.logDatabaseDeleteErrors(Database.delete(accountContactRelationList, false),'AccountMergeBatch','Execute');
                    }
                    
                }

                //merge accounts
                for (Id mergeAccountId : mergeToservivingMap.keySet()) {
                    Id servivingAccountId = mergeToservivingMap.get(mergeAccountId); 
                    try {
                        Merge new Account(Id=servivingAccountId) new Account(Id=mergeAccountId);
                    } catch(Exception pEx) {
                        system.debug('Exception in merge--->' + pEx.getMessage());
                        HandleCustomException.logException(pEx);
                    }
                    
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc){
       
    }


    global class AccountDetail {
        global string servivingId;
        global string mergeId;
        global AccountDetail(string servivingId,string mergeId) {
            this.servivingId = servivingId;
            this.mergeId = mergeId;
        }
    }
}