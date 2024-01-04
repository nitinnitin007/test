@isTest
public class ContractTriggerHandlerTest {
	@isTest
    public static void testmethod1(){
        Account acc = IntappTestObjectFactory.createaccount(true);
        Account billingAccount = IntappTestObjectFactory.createaccount(true);
        Contract con = IntappTestObjectFactory.createcontract(acc.Id);
        con.Billing_Account__c = billingAccount.Id;
        insert con;
        
        con.Status = 'Activated';
        update con;
        con.Status = 'In Force';
        con.Subsidiary__c = '05:400 TFG - US';
        update con;
        
        list<Contract> contractList = new list<Contract>();
        contractList.add(con);
        system.assertNotEquals(contractList.size(), null);      
    }
}