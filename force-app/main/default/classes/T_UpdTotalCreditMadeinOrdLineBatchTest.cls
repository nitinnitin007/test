/**** @name        : T_UpdTotalCreditMadeinOrdLineBatchTest 
***** @author      : KPMG
***** @date        : Dec 21th, 2023
***** @description : Test class for T_UpdateTotalCreditMadeinOrderLineBatch for Updating Total credit made from Invoice to OrderLineDMSummary table using SalesOrderInternalId.
******/

@isTest
public class T_UpdTotalCreditMadeinOrdLineBatchTest {
    @isTest
    public static void updateTotalCreditMadeinOrderLineBatchTestMethod(){
        //Create Account
        List<Account> accList = TestDataFactory.createAccount(1,True);
        List<Account> tempAcc = [SELECT Id,IntApp_Account_Number__c FROM Account];
        //Create QtC_Mig_Invoice_Temp_Table__c
        QtC_Mig_Invoice_Temp_Table__c qtcmigInv = new QtC_Mig_Invoice_Temp_Table__c();
        qtcmigInv.AccName__c = 'Test';
        qtcmigInv.Account_ID__c = tempAcc[0].IntApp_Account_Number__c;
        qtcmigInv.T_Account__c = tempAcc[0].Id;
        qtcmigInv.Name__c = 'Test';
        qtcmigInv.Internal_ID__c = '12345';
        qtcmigInv.Document_Number__c = '12345';
        qtcmigInv.Total_Invoice_Payment__c=1;
        qtcmigInv.Sales_Order_Internal_Id__c='12345';
        qtcmigInv.Total_Invoice_Credit__c=1;
        insert qtcmigInv;
        
        //Create T_OrderLineDMSummary__c
        T_OrderLineDMSummary__c oline =new T_OrderLineDMSummary__c();
		oline.Total_Payments_Made__c=1;
        oline.Total_Credit_memo_applied__c=1;
		oline.NSOrderID__c = '12345';
        insert oline;
        
        test.startTest();
        //Execute the batch class to be tested
        Database.executeBatch(new T_UpdateTotalCreditMadeinOrderLineBatch()); 
        //Stop test
        test.stopTest();
        
        oline = [Select Id,Total_Payments_Made__c,NSOrderID__c,Total_Credit_memo_applied__c from T_OrderLineDMSummary__c where NSOrderID__c = :qtcmigInv.Sales_Order_Internal_Id__c];
        System.assertEquals(oline.Total_Credit_memo_applied__c,1,'Total Credit memo applied is updated successfully');
    }
    

}