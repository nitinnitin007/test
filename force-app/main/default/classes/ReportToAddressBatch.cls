public class ReportToAddressBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    string reportId;
    public ReportToAddressBatch(String reportId) {
        this.reportId = reportId;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        String query = '';
        List<String> headerNameList = new List<String>();
       	List<String> splitedCSVDataList = new List<String>();
        Set<String> opportunityIdSet = new Set<String>();
        Integer opportunityIdIndex;
        
        /*List<Report> reportList = [
            SELECT Id
            	 , Name 
              FROM Report
             WHERE Name = 'Client Shipping & Billing Addresses'
       	];*/
        
        if(reportId != null || Test.isRunningTest()){
            ApexPages.PageReference pageRef = new ApexPages.PageReference('/' + reportId + '?csv=1&exp=1&enc=UTF-8&isdtp=p1');
            String fileString;
            
            if(!Test.isRunningTest()) { 
            	fileString = pageRef.getContent().toString();
            } else {
                List<Opportunity> opportunityList = [Select id from Opportunity];
                fileString = '"Opportunity ID"\n' ;
                for (Opportunity opportunity : opportunityList) {
                    fileString += '"'+opportunity.Id + '"\n';
                }
                fileString +='1\n2\n3\n4\n5\n6\n7\n';
            }
            System.debug('fileString--'+fileString);
            if(fileString.contains('\n')){
                splitedCSVDataList = fileString.split('\n');
                String fileHeaders = splitedCSVDataList[0];
                headerNameList.addAll(fileHeaders.split(','));
                system.debug('headerNameList--->'+headerNameList);
                
                for(Integer i = 0; i < headerNameList.size(); i++) {
                    if(headerNameList[i].remove('"') == 'Opportunity ID'){
                        opportunityIdIndex = i;
                        continue; 
                    }
                }
                
                System.debug('opportunityIdIndex--'+opportunityIdIndex);
                System.debug('splitedCSVDataList.size()--'+splitedCSVDataList.size());
                if(opportunityIdIndex != null){
                    for(Integer i = 1; i < splitedCSVDataList.size() - 7; i++) {
                        String fileValues = splitedCSVDataList[i];
                        System.debug('fileValues--'+fileValues);
                        List<String> rowValueList = fileValues.split(',');
                        System.debug('rowValueList[opportunityIdIndex]--'+rowValueList[opportunityIdIndex]);
                        opportunityIdSet.add(rowValueList[opportunityIdIndex].remove('"'));
                    }
                }
            }
            System.debug('opportunityIdSet--'+opportunityIdSet);
            query = '' 
            	+ ' SELECT Id'
                + '      , Name'
                + '      , AccountId'
                + '      , Account.BillingAddress, Account.BillingStreet'
                + '      , Account.BillingCity, Account.BillingState'
                + '      , Account.BillingPostalCode, Account.BillingCountry'
                + '      , Account.ShippingAddress, Account.ShippingStreet '
                + '      , Account.ShippingCity, Account.ShippingState'
                + '      , Account.ShippingPostalCode, Account.ShippingCountry'
                + '   FROM Opportunity WHERE Id IN: opportunityIdSet';
        }
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Opportunity> scope){
        System.debug('scope--'+scope);
        Map<String,Account> newAccountIdVsAccountsMap = new Map<String,Account>();
        Map<String,Address__c> accountToAddressMap = new Map<String,Address__c>();
        
        for(Opportunity opportunityRec : scope){
            System.debug('scope Account--'+opportunityRec.Account);
            System.debug('BillingAddress--'+opportunityRec.Account.BillingAddress);
            System.debug('ShippingAddress--'+opportunityRec.Account.ShippingAddress);
            newAccountIdVsAccountsMap.put(opportunityRec.AccountId, opportunityRec.Account);
        }

        //fetch country mapping data
        Map<string,string> countryCodeMap = new Map<string,string>();
        Map<string,string> stateCountryWiseCodeMap = new Map<string,string>();
        Map<string,string> stateCodeMap = new Map<string,string>();
        set<string> countryCodes = new set<string>();
        set<string> stateCodes = new set<string>();
        for (Country_Info__mdt countryInfo : [
            SELECT Id 
                 , Country_Code__c
                 , Country_Label__c
                 , State_Code__c
                 , State_Label__c
              FROM Country_Info__mdt
        ]) {
            countryCodes.add(countryInfo.Country_Code__c);
            stateCodes.add(countryInfo.State_Code__c);
            countryCodeMap.put(getValue(countryInfo.Country_Label__c).toLowerCase(),countryInfo.Country_Code__c);
            stateCountryWiseCodeMap.put(getValue(countryInfo.Country_Code__c).toLowerCase() + '-' +getValue(countryInfo.State_Label__c).toLowerCase(),countryInfo.State_Code__c);
        }
        
        List<Address__c> addressUpsertList = new list<Address__c>();
        for(Address__c addressRecord : [
            SELECT Id
                 , Account__c
                 , Address__City__s
            	 , Type__c 
                 , Address__CountryCode__s
                 , Address__Street__s
                 , Address__StateCode__s
                 , Address__PostalCode__s  
              FROM Address__c 
              WHERE Account__c IN: newAccountIdVsAccountsMap.keySet()
        ]){
            string addressLine = getValue(addressRecord.Address__Street__s) + getValue(addressRecord.Address__City__s)
                + getValue(addressRecord.Address__StateCode__s) + getValue(addressRecord.Address__CountryCode__s) +getValue(addressRecord.Address__PostalCode__s);
            
            accountToAddressMap.put(addressRecord.Account__c + '-' + addressLine, addressRecord);
        }
        
        for (Account account : newAccountIdVsAccountsMap.values()) {
            string billingCountryCode =  countryCodes.contains(account.BillingCountry)? account.BillingCountry : getValue(getCountryCode(countryCodeMap,account.BillingCountry));
            string billingStateCode = stateCodes.contains(account.BillingState)? account.BillingState : getValue(getStateCode(stateCountryWiseCodeMap,billingCountryCode,account.BillingState));
            string shippingCountryCode = countryCodes.contains(account.ShippingCountry)? account.ShippingCountry : getValue(getCountryCode(countryCodeMap,account.ShippingCountry));
            string shippingStateCode = stateCodes.contains(account.ShippingState)? account.ShippingState : getValue(getStateCode(stateCountryWiseCodeMap,shippingCountryCode,account.ShippingState));
            string billingAddress = getValue(account.BillingStreet) + getValue(account.BillingCity)
                + billingStateCode + billingCountryCode +getValue(account.BillingPostalCode);
            string shippingAddress = getValue(account.ShippingStreet) + getValue(account.ShippingCity)
                + shippingStateCode + shippingCountryCode +getValue(account.ShippingPostalCode);
            boolean sameAddress = string.isNotBlank(billingAddress) && billingAddress == shippingAddress? true :false;
            
            //check if same and already present?
            if (sameAddress == true && accountToAddressMap.containsKey(account.Id + '-' +billingAddress)) {
                Address__c existingAddress = accountToAddressMap.get(account.Id + '-' +billingAddress);
                if (!'Both'.equalsIgnoreCase(existingAddress.Type__c) ) {
                    existingAddress.Type__c = 'Both';
                    addressUpsertList.add(existingAddress);
                    System.debug('addressUpsertList--133--->'+addressUpsertList);
                }
            } else {
                if (sameAddress == true) {
                    Address__c address = getBillingAddress(account,'Both',billingStateCode,billingCountryCode);
                    addressUpsertList.add(address);
                    accountToAddressMap.put(account.Id + '-' + billingAddress,address);
                } else {
                	//check if billing address present and it also present in existing address?
                	if (string.isNotBlank(billingAddress) && accountToAddressMap.containsKey(account.Id + '-' +billingAddress)) {
                        //update type if it is not both or billing
                        Address__c existingAddress = accountToAddressMap.get(account.Id + '-' +billingAddress);
                        if ( string.isNotBlank(existingAddress.Type__c) 
                            && !'Both'.equalsIgnoreCase(existingAddress.Type__c)
                            && !'Billing'.equalsIgnoreCase(existingAddress.Type__c) 
                        ) {
                            existingAddress.Type__c = 'Both';
                            addressUpsertList.add(existingAddress);
                            System.debug('addressUpsertList--159--->'+addressUpsertList);
                        }
                    } else {
                        //not found so create one
                        Address__c address = getBillingAddress(account,'Billing',billingStateCode,billingCountryCode);
                        addressUpsertList.add(address);
                        accountToAddressMap.put(account.Id + '-' + billingAddress,address);
                        System.debug('addressUpsertList--171--->'+addressUpsertList);
                    }
                    //check if shipping address present and it also present in existing address?
                	if (string.isNotBlank(shippingAddress) && accountToAddressMap.containsKey(account.Id + '-' +shippingAddress)) {
                        //update type if it is not both or billing
                        Address__c existingAddress = accountToAddressMap.get(account.Id + '-' +shippingAddress);
                        if ( string.isNotBlank(existingAddress.Type__c) 
                            && !'Both'.equalsIgnoreCase(existingAddress.Type__c)
                            && !'Shipping'.equalsIgnoreCase(existingAddress.Type__c) 
                        ) {
                            existingAddress.Type__c = 'Both';
                            addressUpsertList.add(existingAddress);
                        }
                    } else {
                        //not found so create one
                        Address__c address = getShippingAddress(account,shippingStateCode,shippingCountryCode);
                        addressUpsertList.add(address);
                        accountToAddressMap.put(account.Id + '-' + shippingAddress,address);
                    }
                }
            }
            System.debug('addressUpsertList--'+addressUpsertList);
            if (!addressUpsertList.isEmpty()) {
                Database.upsert(addressUpsertList,false);
            }
        }
    }

    public Address__c getBillingAddress(Account account,string addressType,string stateCode, string countryCode) {
        Address__c address = new Address__c();
        address.Address__Street__s = account.BillingStreet;
        address.Address__City__s = account.BillingCity;
        address.Address__StateCode__s = stateCode;
        address.Address__CountryCode__s = countryCode;
        address.Address__PostalCode__s = account.BillingPostalCode;
        address.Type__c = addressType;
        address.Account__c = account.Id;
        return address;
    }

    public Address__c getShippingAddress(Account account,string stateCode, string countryCode) {
        Address__c address = new Address__c();
        address.Address__Street__s = account.ShippingStreet;
        address.Address__City__s = account.ShippingCity;
        address.Address__StateCode__s = stateCode;
        address.Address__CountryCode__s = countryCode;
        address.Address__PostalCode__s = account.ShippingPostalCode;
        address.Type__c = 'Shipping';
        address.Account__c = account.Id;
        return address;
    }

    public string getCountryCode(Map<string,string> countryCodeMap,String country) {
        country = string.isNotBlank(country)? country.toLowerCase() : country;
        return string.isNotBlank(country) && countryCodeMap.containsKey(country)? countryCodeMap.get(country) : null;
    }

    public string getStateCode(Map<string,string> stateCountryWiseCodeMap,String country,String state) {
        country = string.isNotBlank(country)? country.toLowerCase() : country;
        state = string.isNotBlank(state)? state.toLowerCase() : state;
        string key = getValue(country) + '-' + getValue(state);
        return stateCountryWiseCodeMap.containsKey(key)? stateCountryWiseCodeMap.get(key) : null;
    }
    
    public string getValue(string data){
        return data != null? data : '';
    }
    
    public void finish(Database.BatchableContext bc){
    }
}