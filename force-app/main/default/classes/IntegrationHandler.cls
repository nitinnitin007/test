public class IntegrationHandler {
    public class CustomerWrapper{
        public String recordId;
        public String customerNumber;
        public String customerCountry;
        public String subsidiary;
        public String updatedAccountSubsidiaries;
        public String accountType; //Prospect or Customer
        public String eventType;
        public String subsidiaries;
        
        public customerWrapper(String recordId, String customerNumber, String customerCountry, String subsidiary, 
                               String accountType, String accSubsidiaries, String eventType){
            this.recordId = recordId;
            if(subsidiary!=null) {
                this.customerNumber = subsidiary.contains('01')? customerNumber : customerNumber + ':' + subsidiary;
                this.UpdatedAccountSubsidiaries = accSubsidiaries == '' || accSubsidiaries == null ? subsidiary  : accSubsidiaries + ';' + subsidiary;
            } else {
                this.customerNumber = customerNumber;
            }
            this.customerCountry = getCountryNSFormat(customerCountry);
            this.subsidiary = subsidiary;
            //this.UpdatedAccountSubsidiaries += accountType.substring(0,1); //C or P
            this.accountType = accountType;                                   
            this.eventType = eventType;
        }
    }
    
    public static void createSignedCustomer(List<Contract> contracts){
        List<CustomerWrapper> wrapperList = new List<CustomerWrapper>();
        List<Contract> listContractsWithAccounts = [
            SELECT Id, Name, AccountId, Account.IntApp_Account_Number__c 
                 , Account.BillingCountry, Account.Subsidiaries__c
                 , Billing_Account__c, Billing_Account__r.IntApp_Account_Number__c 
                 , Billing_Account__r.BillingCountry, Billing_Account__r.Subsidiaries__c,Subsidiary__c
              FROM Contract
             WHERE Id in : contracts
               AND Subsidiary__c != null
               AND Active__c = TRUE
               AND Status = 'In Force'
        ];
        
        for(Contract contract : listContractsWithAccounts){
            
            //for Contract's Account
            if(contract.Account.BillingCountry != null) {
                CustomerWrapper customerWrapper = generateCustomerRequest(contract.Account,contract.Subsidiary__c);
                if (customerWrapper != null) {
                    wrapperList.add(customerWrapper);
                }
                
            }

            //for Contract's Billing Account is present and is not same as Account
            if(contract.Billing_Account__c != null 
                && contract.AccountId != contract.Billing_Account__c
                && contract.Billing_Account__r.BillingCountry != null) {
                CustomerWrapper customerWrapper = generateCustomerRequest(contract.Billing_Account__r,contract.Subsidiary__c);
                if (customerWrapper != null) {
                    wrapperList.add(customerWrapper);
                }
            }
            
        }
        
        if(wrapperList.size() > 0 && !Test.isRunningTest()) {
            SendRequest(JSON.serialize(wrapperList));
            System.debug('@@request Body' +JSON.serialize(wrapperList));
        }
        
    }

    public static void createSignedCustomerFromOrder(List<Order> orders){
        List<CustomerWrapper> wrapperList = new List<CustomerWrapper>();
        List<Order> orderList = [
            SELECT Id, Name, AccountId, Account.IntApp_Account_Number__c 
                 , Account.BillingCountry, Account.Subsidiaries__c
                 , blng__BillingAccount__c, blng__BillingAccount__r.IntApp_Account_Number__c 
                 , blng__BillingAccount__r.BillingCountry, blng__BillingAccount__r.Subsidiaries__c,Subsidiary__c
              FROM Order
             WHERE Id in : orders
        ];
        
        for(Order order : orderList){
            
            //for Order's Account
            if(order.Account.BillingCountry != null) {
                CustomerWrapper customerWrapper = generateCustomerRequest(order.Account,order.Subsidiary__c);
                if (customerWrapper != null) {
                    wrapperList.add(customerWrapper);
                }
                
            }

            //for Order's Billing Account is present and is not same as Account
            if(order.blng__BillingAccount__c != null 
                && order.AccountId != order.blng__BillingAccount__c
                && order.blng__BillingAccount__r.BillingCountry != null) {
                CustomerWrapper customerWrapper = generateCustomerRequest(order.blng__BillingAccount__r,order.Subsidiary__c);
                if (customerWrapper != null) {
                    wrapperList.add(customerWrapper);
                }
            }
            
        }
        
        if(wrapperList.size() > 0 && !Test.isRunningTest()) {
            SendRequest(JSON.serialize(wrapperList));
        }
        
    }

    public static CustomerWrapper generateCustomerRequest(Account account, string subsidiary) {
        CustomerWrapper customerWrapper;
        //subsidiary for this contract - eg. 01:200
        //String subsidiary = contract.Subsidiary__c;
        String eventType = 'Create';
        //subsidiary for all the contracts - eg. 01,05,06
        String accsubsidiaries = account.Subsidiaries__c == null? '': account.Subsidiaries__c;
        
        //If no subsidiary is assigned, then do not process 
        if(!(subsidiary == null || !subsidiary.contains(':'))) {
            subsidiary = subsidiary.split(':')[0];
            
            //If contract already has a customer in NetSuite
            if(!(accsubsidiaries != '' && accsubsidiaries.contains(subsidiary + 'C'))) {
                if(!(accsubsidiaries != '' && accsubsidiaries.contains(subsidiary + 'P'))){
                    accsubsidiaries = accsubsidiaries.contains(subsidiary + 'P;') ? accsubsidiaries.remove(subsidiary + 'P;'):accsubsidiaries.remove(subsidiary + 'P');
                    eventType = 'Update';
                }
                customerWrapper = new CustomerWrapper(account.Id, account.IntApp_Account_Number__c, account.BillingCountry, subsidiary, 'Customer', accsubsidiaries, eventType);
            }
        }
        return customerWrapper;
    }
    
    public static void createProspect(List<Account> accounts,Map<Id,Account> accountOldMap){
        List<CustomerWrapper> wrapperList = new List<CustomerWrapper>();
        for(Account acc : Accounts){
            String eventType = 'Create';
            //No value chosen in the action picklist - No processing required
            Account accountOld = accountOldMap.get(acc.Id);
            boolean hasProsepect = String.isNotblank(acc.Create_Prospect__c);
            system.debug('@@has Prospect' +hasProsepect);
            String custLabelValues = Label.Account_Details;
            List<String> accountFieldsCheck = custLabelValues.split(',');
            boolean isNameChange = false;
            for(String field: accountFieldsCheck){
                if(accountOld.get(field) != acc.get(field) && acc.Subsidiaries__c != null){
                    isNameChange = true;
                    break;      
                }
            }
            if (hasProsepect == false && isNameChange == false) {
                continue;
            }

            if(acc.Subsidiaries__c == null){
                acc.Subsidiaries__c = '';
            }
            
            //If subsidiaries for this account already includes the one set on the create subsidiary field, no processing required
            if(acc.Subsidiaries__c != '' && acc.Create_Prospect__c!=null && acc.Subsidiaries__c.contains(acc.Create_Prospect__c) && isNameChange == false){
                acc.Create_Prospect__c = null;
                continue;
            }

            eventType = hasProsepect == false && isNameChange == true? 'Update' : 'Create';
            
            CustomerWrapper wrapper = new CustomerWrapper(acc.Id, acc.IntApp_Account_Number__c, acc.BillingCountry, acc.Create_Prospect__c, 'Customer', acc.Subsidiaries__c, eventType);
            if (eventType == 'Update') {
                wrapper.customerNumber = acc.IntApp_Account_Number__c;
                wrapper.Subsidiaries = acc.Subsidiaries__c;
                wrapper.subsidiary = null;
                wrapper.accountType = null;
            }
            //SerializedWrapperList.add(JSON.serialize(wrapper));
            wrapperList.add(wrapper);
        }
        
        if(wrapperList.size() > 0 && !test.isRunningTest())
        {
            SendRequest(JSON.serialize(wrapperList)); 
            System.debug('@@request Body' +JSON.serialize(wrapperList));
        }       
    }
    
    public static String getCountryNSFormat(String countryCode){
        String customerCountry = countryCode.toLowerCase();
        
        if(countryCode == 'curaçao' || countryCode == 'usa' || countryCode == 'us')
            customerCountry = 'unitedStates';
        
        if(countryCode == 'uk') 
            customerCountry = 'unitedKingdom';
        
        if(countryCode.contains(' ')){
            List<String> wordSplit = countryCode.split(' ');
            Boolean firstWord = true;
            customerCountry = '';
            for(String eachWord: WordSplit){
                if(firstWord) customerCountry += eachWord.toLowerCase();
                else customerCountry += eachWord.capitalize();
                firstWord = false;
            }
        }
        
        return '_' + customerCountry;
    } 
    
    @future (callout = true)
    public static void sendRequest(String reqBody){
        Intapp_Settings__c settings = Intapp_Settings__c.getInstance();
        
        HttpRequest req = new HttpRequest();
        if(IsSandbox()) 
            req.setEndpoint(settings.NS_customer_webhook_sbx__c);
        else 
            req.setEndpoint(settings.NS_Customer_webhook_PROD__c);
        req.setMethod('POST');
        req.setBody(reqBody);
        Http http = new Http();
        HTTPResponse res = http.send(req);
    }
    
    public static Boolean isSandbox(){
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
}