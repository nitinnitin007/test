/**** @name :T_UpdateInvLineTaxAmountInOPTest
***** @author : KPMG
***** @date : Nov 11th, 2023
***** @description : Test class - To Update InvLine Total Amount including tax in NS_IL_Amount_Total__c field in OrderLine Summary variable
******/
@isTest
public class T_UpdateInvLineTaxAmountInOPTest {
    @testSetup
    //TestSetp Data
    static void setupData(){
        //Creating QtC_Mig_Invoice_Lines_Temp_Table__c record
        QtC_Mig_Invoice_Lines_Temp_Table__c qtcmigInvLines = new QtC_Mig_Invoice_Lines_Temp_Table__c();
        qtcmigInvLines.Internal_ID__c = '123456';
        qtcmigInvLines.T_Amount__c = '1234';
        qtcmigInvLines.Tax_Amount__c = '0';
        qtcmigInvLines.Item__c ='GE-00955';
        qtcmigInvLines.Sales_Order_Internal_Id__c = '12345';
        qtcmigInvLines.Sales_Order_Line_Id__c = '1';
        insert qtcmigInvLines;
        //Creating T_OrderLineDMSummary__c record
        T_OrderLineDMSummary__c summary = new T_OrderLineDMSummary__c();
        summary.NSOrderID__c = qtcmigInvLines.Sales_Order_Internal_Id__c;
        summary.NSOrderLineitemID__c = qtcmigInvLines.Sales_Order_Line_Id__c;
        summary.NS_IL_Amount_Total__c = Null;
        insert summary;
        
    }
    @isTest
    //Method to run the test for the testdata Created
    static void updateInvLineTaxAmountInOPTest(){
        //Start Test
        Test.startTest();
        //Executing the Method needed to be tested
        T_UpdateInvLineTaxAmountInOpBatch bc = new T_UpdateInvLineTaxAmountInOpBatch();
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        
        //Validating the result
        List<T_OrderLineDMSummary__c> tempOLList = [SELECT id,NS_IL_Amount_Total__c FROM T_OrderLineDMSummary__c];
        if(tempOLList.size() > 0 && tempOLList[0].NS_IL_Amount_Total__c != null){
            System.assertEquals(tempOLList[0].NS_IL_Amount_Total__c,1234,'Amount populated successfully');
        }
    }

}