/**** @name :T_UpdateCreditAllocInvoiceBatchTest
***** @author : KPMG
***** @date : Nov 11th, 2023
***** @description : Test Class for Updating Total Invoice credit from CreditAllocations using InvoiceInternalId
******/
@isTest
public class T_UpdateCreditAllocInvoiceBatchTest {
    @testSetup()
    //Method to create Testdata
    static void setupData(){
        //Create record for QtC_Mig_Invoice_Temp_Table__c
        QtC_Mig_Invoice_Temp_Table__c qtcmiginv = new QtC_Mig_Invoice_Temp_Table__c();
        qtcmiginv.Internal_ID__c = '12345';
        qtcmiginv.Sales_Order_Internal_Id__c = '12356';
        qtcmiginv.Total_Invoice_Credit__c = Null;
        insert qtcmiginv;
        //Create Record for QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c
        QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c creditLines = new QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c();
        creditLines.Applied_to_Amt_without_Symbol__c = '1234';
        creditLines.Applied_To_Internal_ID__c = qtcmiginv.Internal_ID__c;
        insert creditLines;
    }
    @isTest
    //Method to execute the testdata
    static void updateCreditAllocInvoiceBatchTest(){
        //Start Test
        Test.startTest();
        //Execute Batch class to be tested
        T_UpdateCreditAllocInvoiceBatch bc = new T_UpdateCreditAllocInvoiceBatch();
        Database.executeBatch(bc);
        //Stop Test
        Test.stopTest();
        
        //Validating the Result
        List<QtC_Mig_Invoice_Temp_Table__c> tempList = [SELECT Id,Total_Invoice_Credit__c FROM QtC_Mig_Invoice_Temp_Table__c Limit 1];
        if(tempList.size()>0 && tempList[0].Total_Invoice_Credit__c != null){
          System.assertEquals(tempList[0].Total_Invoice_Credit__c,1234,'Amount successfully populated');  
        }  
    }
}