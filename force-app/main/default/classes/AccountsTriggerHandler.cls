public class AccountsTriggerHandler {
    Private static Boolean firstcall = false;
    Public static Boolean firstcall(){
        return firstcall;
    }
    public static void accountAfterUpdate(List<Account> accountList,Map<Id,Account> accountOldMap){
        
        String integrationUsername = System.Label.Integration_Username;
        String currentUser = UserInfo.getUserName();
        List<Account> accList = new List<Account>();
        if(!firstcall){
        if(currentUser != integrationUsername){
            for(Account acc : accountList){
                if(!accountList.isEmpty() && accountList.size()>0){
                    accList.add(acc);
                }
            }
        }
        IntegrationUtility.publishEligibleSobjectRecords(accList,accountOldMap,'Account');
            firstcall = true;
        }
    }
}