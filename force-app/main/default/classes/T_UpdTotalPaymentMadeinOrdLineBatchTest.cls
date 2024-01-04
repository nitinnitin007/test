/**** @name        : T_UpdTotalPaymentMadeinOrdLineBatchTest
***** @author      : KPMG
***** @date        : Dec 21st, 2023
***** @description : Test class for T_UpdateTotalPaymentMadeinOrderLineBatch for Updating Total Payments made from Invoice to OrderLineDMSummary table using SalesOrderInternalId.
******/

@isTest
public class T_UpdTotalPaymentMadeinOrdLineBatchTest {
    @isTest
    public static void updateTotalPaymentMadeinOrderLineBatchTestMethod(){
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
        insert qtcmigInv;
        
        //Create T_OrderLineDMSummary__c
        T_OrderLineDMSummary__c oline =new T_OrderLineDMSummary__c();
		oline.Total_Payments_Made__c=1;
		oline.NSOrderID__c = '12345';
        insert oline;
        
        test.startTest();
        //Execute the batch class to be tested
        Database.executeBatch(new T_UpdateTotalPaymentMadeinOrderLineBatch()); 
        //Stop test
        test.stopTest();
        
        oline = [Select Id,Total_Payments_Made__c,NSOrderID__c from T_OrderLineDMSummary__c where NSOrderID__c = :qtcmigInv.Sales_Order_Internal_Id__c];
        System.assertEquals(oline.Total_Payments_Made__c,1,'Total payment made is updated successfully');
    }
    

}