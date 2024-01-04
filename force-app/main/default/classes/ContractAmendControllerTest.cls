/**
 * @description       : Test class for ContractAmendController
 * @author            : Vivek Singh Jadaun
 * Jira story : BIZ-46098
**/
@isTest
public class ContractAmendControllerTest {
    
    @testSetup
    public static void setup(){
        List<Account> accList = TestDataFactory.createAccount(1,True);
        List<Contract> conList = TestDataFactory.createContract(10,accList[0].id,true);
    }
    
    @istest
    private static void updateContract(){
        List<Contract> conList = [Select Id from Contract Limit 5];
        Test.startTest();
        ContractAmendController.updateContract( conList[0].Id,'Test','Cancellation');
        ContractAmendController.updateContract( conList[1].Id,'Test','Cancellation');
        ContractAmendController.updateContract( conList[2].Id,'Test','Cancellation');
        ContractAmendController.updateContract( conList[3].Id,'Test','Cancellation');
        ContractAmendController.updateContract( conList[4].Id,'Test','Cancellation');
        ContractAmendController.updateContract( '123456','Test','Cancellation');
        Test.stopTest();
        List<Contract> checkConList = [Select Id,Deal_Type__c,OP4I_Deal_ID__c from Contract Limit 5];
        System.assertEquals('Cancellation', checkConList[0].Deal_Type__c);
        System.assertEquals('Test', checkConList[0].OP4I_Deal_ID__c);
        
    }
}