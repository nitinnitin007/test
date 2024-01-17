/********************************************************************************     
*  Name             :  ContractTriggerHandler
*  Author           :  Hiforte Technologies
*  Description      :  1. Populate Billing Account on contracts
*                                  
*  Change history   :
*  Date                Author                          Description
*  06/01/14        Vasu Pulipati                   Created
********************************************************************************/
public class ContractTriggerHandler {
    Public static Boolean firstcall = false;
    
    public static void afterUpdate (List<Contract> contracts,Map<Id,Contract> contractOldMap){
        List<Contract> lstOfContractsToSend = new List<Contract>();
        if(!contracts.IsEmpty())
        {
            for(Contract contr : contracts)
            {
                if(contr.SBQQ__Quote__r.SBQQ__Type__c != 'Migration Quote'){
                    lstOfContractsToSend.add(contr);              
                }
            }        
        }
        
        if(!lstOfContractsToSend.IsEmpty() && lstOfContractsToSend.size() > 0)
        {
            IntegrationHandler.CreateSignedCustomer(lstOfContractsToSend);
        }
        ContractTriggerHandler.contractEventAfterUpdate(contracts,contractOldMap);
    }
    
    public static void afterInsert (List<Contract> contracts){
        List<Contract> lstOfContractsToSend = new List<Contract>();
        if(!contracts.IsEmpty())
        {
            for(Contract contr : contracts)
            {
                if(contr.SBQQ__Quote__r.SBQQ__Type__c != 'Migration Quote'){
                    lstOfContractsToSend.add(contr);              
                }
            }        
        }
        
        if(!lstOfContractsToSend.IsEmpty() && lstOfContractsToSend.size() > 0)
        {
            IntegrationHandler.CreateSignedCustomer(contracts);
        }
        ContractTriggerHandler.contractEventAfterInsert(contracts);
    }
    
    public static void populateBillingAccount(List<Contract> newContracts){
        Map<Id, Id> mapAcct2ParentId = new Map<Id, Id>();
        for(Contract con: newContracts){
            if(con.AccountId != null && con.Billing_Account__c == null){
                mapAcct2ParentId.put(con.AccountId, null);
            }
        }
        for(Account a: [select Id, ParentId from Account where Id in :mapAcct2ParentId.keySet()]){
            mapAcct2ParentId.put(a.Id, a.ParentId);
        }
        for(Contract con: newContracts){
            if(con.AccountId != null && con.Billing_Account__c == null){
                con.Billing_Account__c = (mapAcct2ParentId.get(con.AccountId) != null)? mapAcct2ParentId.get(con.AccountId) : con.AccountId;
            }
        }    
    }
    
    public Static void contractEventAfterInsert(list<Contract> contractNewList) {
        if(!firstcall)
            IntegrationUtility.publishsObjectRecords(contractNewList,'Contract');
        firstcall = true;
    }
    
    public Static void contractEventAfterUpdate(list<Contract> contractNewList, Map<Id,Contract> contractOldMap) {
        List<Account> eligibleAccountList = new List<Account>();
        Set<id> setOfAccountId = new Set<id>();
        if(!firstcall) {
            if(!contractNewList.isEmpty())
            {
                for(Contract contractObj : contractNewList)
                {
                    IntegrationUtility.publishsObjectRecords(contractNewList,'Contract');
                    
                    if(contractObj.Status == 'In Force' && contractObj.Subsidiary__c != null)
                    {
                        setOfAccountId.add(contractObj.AccountId);
                    }      
                } 
                if(setOfAccountId!=null)
                {
                    String strQuery = createQuery(setOfAccountId);
                    String strQueryUpd = strQuery.replace('setOfAccount' , 'setOfAccountId');
                    eligibleAccountList = Database.query(strQueryUpd);
                }
                
                if(!eligibleAccountList.isEmpty()){
                    IntegrationUtility.publishsObjectRecords(eligibleAccountList,'Account');
                }
            }
            firstcall = true;
        }
        
    }
    
    public static string createQuery(set<Id> setOfAccount)
    {
        set<String> fieldNames = new set<String>();
        Schema.SObjectType targetObjType = Schema.getGlobalDescribe().get('Account');
        Map<String, Schema.SObjectField> fieldMap = targetObjType.getDescribe().fields.getMap();
        fieldNames = fieldMap.keyset();
        List<String> fields = new List<String>(fieldNames);
        String query =  ' SELECT ' +
            String.join( fields, ',' ) +
            ' FROM ' +
            'Account' +
            ' WHERE ' +
            ' Id IN: setOfAccount';
        
        String strQuery1 = query.remove('{');
        String strQuery2 = strQuery1.remove('}');
        
        return strQuery2;
    }   
}