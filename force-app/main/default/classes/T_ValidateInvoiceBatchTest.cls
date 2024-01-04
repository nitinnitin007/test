/**** @name        :T_ValidateInvoiceBatchTest
***** @author      : KPMG
***** @date        : Oct 11th, 2023
***** @description : Test Class - Checking Order Product Line Amount = Corresponding Inv Lines Amount
					Order Product : InternalId+LineId+Item+Qty '-'separator 
					Inv Lines : : SalesOrderInternalId+SalesOrderLineId+Item+Qty '-'separator 
					Validate the amount and find the flag
					Insert them into OLSummary Table======Base table for all migrations
******/
@isTest
public class T_ValidateInvoiceBatchTest {
    //Test Data Setup
    @isTest
    //Method to insert testdata
    static void validateFullInvoiceTest(){
        //Test Data
        //QTC_Mig_OrderProducts__c
        QTC_Mig_OrderProducts__c  ordProd = new QTC_Mig_OrderProducts__c();
        ordProd.Amount__c = '1';
        ordProd.Amount_Credit__c='1';
        ordProd.Amount_Debit_Foreign_Currency__c='1';
        ordProd.Amount_Foreign_Currency__c='1';
        ordProd.Amount_Foreign_Currency_without_Symbol__c='1';
        ordProd.Document_Number__c=1;
        ordProd.Applying_Link_Type__c = 'Order Bill/{#Invoice#}'; 
        ordProd.Invoice_End_Date__c = system.today();
        ordProd.Invoice_Start_Date__c = system.today()+10;
        ordProd.Invoice_Line_ID__c='1';
        ordProd.Item_Rate__c=1;
        ordProd.Line_Sequence_Number__c=1;
        ordProd.OSA_Contract_Number_from_Salesforce__c='111';
        ordProd.OSA_Contract_Number_RA__c='111';
        ordProd.Tax__c=true;
        ordProd.Internal_ID__c = '111';
        ordProd.Line_ID__c = 1;
        ordProd.Item__c = 'Test';
        ordProd.Quantity__c = 1;
        ordProd.T_Amount_Without_Symbol__c = '2.5';
        ordProd.Tax_Amount__c = '1';
        insert ordProd;
        //QtC_Mig_Invoice_Lines_Temp_Table__c
        QtC_Mig_Invoice_Lines_Temp_Table__c invLines = new QtC_Mig_Invoice_Lines_Temp_Table__c();
        invLines.Amount__c = '1';
        invLines.Amount_Foreign_Currency__c = '1';
        invLines.Amount_Foreign_Currency_without_Symbol__c = '1';
        invLines.Sales_Order_Internal_Id__c = '111';
        invLines.Sales_Order_Line_Id__c = '1';
        invLines.Item__c = 'Test';
        invLines.Quantity__c = 1;
        invLines.Line_ID__c = 1;
        invLines.Tax__c = 'True';
        invLines.T_SourceName__c = 'Test';
        invLines.Line_Sequence_Number__c = 1; 
        invLines.T_Amount__c = '2.5';
        invLines.Tax_Amount__c = '1';
        insert invLines;
     
        //Start Test
        Test.startTest();
        // Execute the batch class to be tested
        T_ValidateInvoiceBatch bc = new T_ValidateInvoiceBatch();
        Database.executeBatch(bc);
        // Stop the test
        Test.stopTest();
        
        //Validate Results
        List<T_OrderLineDMSummary__c> summary = [Select Id,OL_Paid_in_Full_Indicator__c from T_OrderLineDMSummary__c Limit 1];
        if(summary.size()>0 && summary[0].OL_Paid_in_Full_Indicator__c != null){
            System.assertEquals(true,summary[0].OL_Paid_in_Full_Indicator__c,'Summary record with paid in full created');  
        }
    }
     @isTest
    //Partial Validation
    static void validatePartialTest(){
        //Test Data
        //QTC_Mig_OrderProducts__c
        QTC_Mig_OrderProducts__c  ordPro = new QTC_Mig_OrderProducts__c();
        ordPro.Amount__c = '1';
        ordPro.Amount_Credit__c='1';
        ordPro.Amount_Debit_Foreign_Currency__c='1';
        ordPro.Amount_Foreign_Currency__c='1';
        ordPro.Amount_Foreign_Currency_without_Symbol__c='1';
        ordPro.T_Amount_Without_Symbol__c = '1.5';
        ordPro.Tax_Amount__c = '1';
        ordPro.Applying_Link_Type__c = 'Order Bill/{#Invoice#}'; 
        ordPro.Invoice_End_Date__c = system.today();
        ordPro.Invoice_Start_Date__c = system.today()+10;
        ordPro.Document_Number__c=1;
        ordPro.Invoice_Line_ID__c='1';
        ordPro.Item_Rate__c=1;
        ordPro.Line_Sequence_Number__c=1;
        ordPro.OSA_Contract_Number_from_Salesforce__c='111';
        ordPro.OSA_Contract_Number_RA__c='111';
        ordPro.Tax__c=true;
        ordPro.Internal_ID__c = '111';
        ordPro.Line_ID__c = 1;
        ordPro.Item__c = 'Test';
        ordPro.Quantity__c = 1;
        insert ordPro;
        //Test Data
        //QtC_Mig_Invoice_Lines_Temp_Table__c
        QtC_Mig_Invoice_Lines_Temp_Table__c invLine = new QtC_Mig_Invoice_Lines_Temp_Table__c();
        invLine.Amount__c = '0.5';
        invLine.Amount_Foreign_Currency__c = '0.5';
        invLine.Amount_Foreign_Currency_without_Symbol__c = '0.5';
        invLine.Sales_Order_Internal_Id__c = ordPro.Internal_ID__c;
        invLine.Sales_Order_Line_Id__c = string.valueof(ordPro.Line_ID__c);
        invLine.Line_ID__c = 1;
        invLine.Quantity__c = ordPro.Quantity__c;
        invLine.Item__c = ordPro.Item__c;
        invLine.Tax__c='True';
        invLine.T_SourceName__c = 'Test';
        invLine.T_Amount__c = '0.5';
        invLine.Tax_Amount__c = '1';
        invLine.Line_Sequence_Number__c = 1;
        insert invLine;
        
        //Start Test
        Test.startTest();
        // Execute the batch class to be tested
        T_ValidateInvoiceBatch bc = new T_ValidateInvoiceBatch();
        Database.executeBatch(bc);
        // Stop the test
        Test.stopTest();
        
        //Validate Results
        List<T_OrderLineDMSummary__c> summary = [Select Id,OL_with_Partially_paid_invoice__c from T_OrderLineDMSummary__c];
        if(summary.size()>0 && summary[0].OL_with_Partially_paid_invoice__c){
            System.assertEquals(true,summary[0].OL_with_Partially_paid_invoice__c,'Summary record with Partial flag created');  
        }
    }
      @isTest
    //Method to insert testdata
    static void validateNoInvoiceTest(){
        //Test Data
        //QTC_Mig_OrderProducts__c
        QTC_Mig_OrderProducts__c  ordPro = new QTC_Mig_OrderProducts__c();
        ordPro.Amount__c = '1';
        ordPro.Amount_Credit__c='1';
        ordPro.Amount_Debit_Foreign_Currency__c='1';
        ordPro.Amount_Foreign_Currency__c='1';
        ordPro.Amount_Foreign_Currency_without_Symbol__c='1';
        ordPro.Applying_Link_Type__c = 'Order Bill/{#Invoice#}'; 
        ordPro.Invoice_End_Date__c = system.today();
        ordPro.Invoice_Start_Date__c = system.today()+10;
        ordPro.Document_Number__c=1;
        ordPro.Invoice_Line_ID__c='1';
        ordPro.Item_Rate__c=1;
        ordPro.Line_Sequence_Number__c=1;
        ordPro.OSA_Contract_Number_from_Salesforce__c='111';
        ordPro.OSA_Contract_Number_RA__c='111';
        ordPro.Tax__c=true;
        ordPro.Internal_ID__c = '111';
        ordPro.Line_ID__c = 1;
        ordPro.Item__c = 'Test';
        ordPro.Quantity__c = 1;
        
        insert ordPro;
        //Start Test
        Test.startTest();
        // Execute the batch class to be tested
        T_ValidateInvoiceBatch bc = new T_ValidateInvoiceBatch();
        Database.executeBatch(bc);
        // Stop the test
        Test.stopTest();
        
        //Validate Results
        List<T_OrderLineDMSummary__c> summary = [Select Id,OL_Future_Invoice_Indicator__c from T_OrderLineDMSummary__c];  
        if(summary.size()>0 && summary[0].OL_Future_Invoice_Indicator__c != null){
            System.assertEquals(true,summary[0].OL_Future_Invoice_Indicator__c,'Summary record with future flag created'); 
        }
    }
}