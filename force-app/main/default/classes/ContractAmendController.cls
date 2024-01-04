/**
* @description       : Controller class for LWC Component
* @author            : Vivek Singh
* Jira story : BIZ-46098
**/
public with sharing class ContractAmendController {

    //class to populate amendment details and land on contract record page.
    @AuraEnabled
    public static String updateContract(String contractId, String dealId, String dealType){
            try{
                
                List<Contract> contractLstToUpdate = new List<Contract>();
                Contract contractRecord = [Select Id From Contract Where Id =: contractId Limit 1];

                if(contractRecord != null){
                     contractRecord.Deal_Type__c =dealType;
                    contractRecord.OP4I_Deal_ID__c = dealId;
                    contractLstToUpdate.add(contractRecord);

                    if(contractLstToUpdate != null && !contractLstToUpdate.isEmpty()){
                        Database.update(contractLstToUpdate);
                    }

                }
                else{

                        return 'Error;'+'Contract not found. Please enter a valid Contract Id';
                    }
                return 'Success;'+contractRecord.Id; 
                
            }
            catch(Exception e){
                System.debug('Exception :'+e);
                return 'Error;'+e.getMessage();
            }
    }
}