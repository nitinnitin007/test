/**** @name :T_SourceInvoiceMoveTest
***** @author : KPMG
***** @date : Nov 11th, 2023
***** @description : Test Class for T_SourceInvoiceMove to check - If the records with flag for main load - Based on OSA contract
******/
@isTest
public class T_SourceInvoiceMoveTest {
    @isTest
    public static void updateInvoiceTest(){
        //Creating a T_OSA__c Record
        T_OSA__c tempOSA = new T_OSA__c();
        tempOSA.ContractNumber__c = '12345';
        insert tempOSA;
        
        //Creating a T_Invoice_NewTemp__c Record        
        T_Invoice_NewTemp__c invTemp = new T_Invoice_NewTemp__c();
        invTemp.T_OSAMatched__c= False;
        invTemp.Rev_Rec_Special_Case__c=Null;
        invTemp.Shipping_Address_2__c=Null;
        invTemp.Shipping_Attention__c=Null;
        invTemp.ROR_Date__c=Null;
        invTemp.Replaced_Invoice__c=Null;
        invTemp.Document_Number__c=Null;
        invTemp.Terms__c=Null;
        invTemp.Termination_for_Convenience__c=Null;
        invTemp.Billing_Country_Code__c=Null;
        invTemp.Billing_Address_3__c=Null;
        invTemp.Amount_Foreign_Currency_without_Symbol__c=Null;
        invTemp.OSA_Contract_Number_from_Salesforce__c='12345';
        invTemp.Shipping_StateProvince__c=Null;
        invTemp.SFA_Uplift__c=Null;
        invTemp.Subsidiary__c=Null;
        invTemp.Deal_ID__c=Null;
        invTemp.Start_Date__c=Null;
        invTemp.OA_Project_ID__c=Null;
        invTemp.Billing_Addressee__c=Null;
        invTemp.Invoice_Status__c=Null;
        invTemp.Shipping_Zip__c=Null;
        invTemp.Billing_Country__c=Null;
        invTemp.Shipping_Address_3__c=Null;
        invTemp.Sales_Order_Type__c=Null;
        invTemp.OA_Business_Unit__c=Null;
        invTemp.Status__c=Null;
        invTemp.Shipping_Country__c=Null;
        invTemp.Currency__c=Null;
        invTemp.Shipping_Address_1__c=Null;
        invTemp.End_Date__c=Null;
        invTemp.Name__c=Null;
        invTemp.Amount_Foreign_Currency__c=Null;
        invTemp.Exchange_Rate__c=Null;
        invTemp.Billing_City__c=Null;
        invTemp.Formula_Text__c=Null;
        invTemp.Shipping_City__c=Null;
        invTemp.Shipping_Country_Code__c=Null;
        invTemp.Account__c=Null;
        invTemp.Amount_Tax__c=Null;
        invTemp.Due_DateReceive_By__c=Null;
        invTemp.OA_Project_Type__c=Null;
        invTemp.Memo__c=Null;
        invTemp.Account_ID__c=Null;
        invTemp.Date__c=Null;
        invTemp.To_Be_Emailed__c=Null;
        invTemp.Period__c=Null;
        invTemp.Shipping_Addressee__c=Null;
        invTemp.T_Name__c=Null;
        invTemp.Billing_Attention__c=Null;
        invTemp.Billing_StateProvince__c=Null;
        invTemp.Term_Start_Date__c=Null;
        invTemp.Tax__c=Null;
        invTemp.Multi_Year__c=Null;
        invTemp.Billing_Zip__c=Null;
        invTemp.Billing_Address_1__c=Null;
        invTemp.Created_From__c=Null;
        invTemp.Billing_Address_2__c=Null;
        invTemp.Internal_ID__c=Null;
        invTemp.Term_End_Date__c=Null;
        invTemp.SFA_Cap__c=Null;
        invTemp.PO__c=Null;
        invTemp.Invoice_Type__c=Null;
        
        insert invTemp;
        // Start the test
        test.startTest();
        
        // Execute the batch class to be tested
        String tempInv ='Invoice';
        T_SourceInvoiceMove batchClass = new T_SourceInvoiceMove(tempInv);
        Database.executeBatch(batchClass);
        
        // Stop the test
        test.stopTest();
        
        // Verify the results
        List<T_Invoice_NewTemp__c> tempList = [SELECT Id,T_OSAMatched__c FROM T_Invoice_NewTemp__c ];
        if(tempList.size()>0){
            System.assertEquals(tempList[0].T_OSAMatched__c,True,'Record Matched Succesfully');
        }  
    }
    @isTest
    public static void updateInvoiceLinesTest(){
        
        //Creating a T_OSA__c record
        T_OSA__c temp = new T_OSA__c();
        temp.ContractNumber__c = '12345';
        insert temp;
        
        //Creating a T_qtc_Active_Invoice_Line__c Record  
        T_qtc_Active_Invoice_Line__c invLineTemp = new T_qtc_Active_Invoice_Line__c();
        invLineTemp.Internal_ID__c=null;
        invLineTemp.Line_Sequence_Number__c=null;
        invLineTemp.Price_Level__c=null;
        invLineTemp.Amount_Foreign_Currency__c=null;
        invLineTemp.Tax_Item__c=null;
        invLineTemp.OSA_Contract_Number_RA__c=null;
        invLineTemp.Order_Type__c=null;
        invLineTemp.Tax_Amount__c=null;
        invLineTemp.Document_Number__c=null;
        invLineTemp.Item__c=null;
        invLineTemp.Item_Rate__c=null;
        invLineTemp.Amount_Foreign_Currency_without_Symbol__c=null;
        invLineTemp.Support_Level__c=null;
        invLineTemp.Rev_Rec_Start_Date__c=null;
        invLineTemp.Contract_Item_Start_Date__c=null;
        invLineTemp.Tax__c=null;
        invLineTemp.Line_ID__c=null;
        invLineTemp.Quantity__c=null;
        invLineTemp.Item_Rate_Amount_without_Symbol__c=null;
        invLineTemp.OSA_Contract_Number_from_Salesforce__c='12345';
        invLineTemp.Rev_Rec_End_Date__c=null;
        invLineTemp.Contract_Item_End_Date__c=null;
        invLineTemp.ProServe_Software__c=null;
        invLineTemp.of_Months__c=null;
        invLineTemp.T_OSAMatched__c= False; 
        
        insert invLineTemp;
        
        // Start the test
        test.startTest();
        
        // Execute the batch class to be tested
        String tempInvLine='InvoiceLines';
        T_SourceInvoiceMove batchClass = new T_SourceInvoiceMove(tempInvLine);
        Database.executeBatch(batchClass);
        
        // Stop the test
        test.stopTest();
        
        //Verify the results    
        List<T_qtc_Active_Invoice_Line__c> tempList = [SELECT Id,T_OSAMatched__c FROM T_qtc_Active_Invoice_Line__c ];
        if(tempList.size()>0){
            System.assertEquals(tempList[0].T_OSAMatched__c,True,'Record Matched Succesfully');
        }  
    }
    @isTest
    public static void updatePaymentTest(){
        
        //// Creating a test T_OSA__c record
        T_OSA__c tempOSA = new T_OSA__c();
        tempOSA.ContractNumber__c = '12345';
        insert tempOSA;
        
        //// Creating a test T_qtc_Active_Payment_Customer_Detail__c record 
        T_qtc_Active_Payment_Customer_Detail__c invPayTemp = new T_qtc_Active_Payment_Customer_Detail__c();
        invPayTemp.Bank_Fee__c=Null;
        invPayTemp.OSA_Contract_Number_from_Salesforce__c='12345';
        invPayTemp.External_ID__c=Null;
        invPayTemp.Document_Number__c=Null;
        invPayTemp.Memo__c=Null;
        invPayTemp.Internal_ID__c=Null;
        invPayTemp.Amount_Foreign_Currency_without_Symbol__c=Null;
        invPayTemp.Formula_Text__c=Null;
        invPayTemp.Amount_Foreign_Currency__c=Null;
        invPayTemp.Date__c=Null;
        invPayTemp.Status__c=Null;
        invPayTemp.Currency__c=Null;
        invPayTemp.Name__c=Null;
        invPayTemp.Subsidiary_no_hierarchy__c=Null;
        invPayTemp.Exchange_Rate__c=Null;
        invPayTemp.Account__c=Null;
        invPayTemp.Period__c=Null;
        invPayTemp.Type__c=Null;
        invPayTemp.T_OSAMatched__c= False;
        
        insert invPayTemp;
        
        // Start the test
        test.startTest();
        
        // Execute the batch class to be tested
        String tempPayment = 'Payment';
        T_SourceInvoiceMove batchClass = new T_SourceInvoiceMove(tempPayment);
        Database.executeBatch(batchClass);
        
        // Stop the test
        test.stopTest();
        
        //Verify the Results
        List<T_qtc_Active_Payment_Customer_Detail__c> tempList = [SELECT Id,T_OSAMatched__c FROM T_qtc_Active_Payment_Customer_Detail__c ];
        if(tempList.size()>0){
            System.assertEquals(tempList[0].T_OSAMatched__c,True,'Record Matched Succesfully');
        }
        
    }
    @isTest
    public static void updatePaymentAllocTest(){
        
        //Creating a test T_OSA__c record
        T_OSA__c tempOSA = new T_OSA__c();
        tempOSA.ContractNumber__c = '12345';
        insert tempOSA;
        
        // // Creating a test T_qtc_ActiveCustomer_Payment_Alloc_Detai__c record   
        T_qtc_ActiveCustomer_Payment_Alloc_Detai__c invPayAllocTemp = new T_qtc_ActiveCustomer_Payment_Alloc_Detai__c();
        invPayAllocTemp.Date__c=Null;
        invPayAllocTemp.Formula_Text__c=Null;
        invPayAllocTemp.Applied_Amount_without_Symbol__c=Null;
        invPayAllocTemp.Applied_To_Link_Type__c=Null;
        invPayAllocTemp.Document_Number__c=Null;
        invPayAllocTemp.Invoice_Internal_ID__c=Null;
        invPayAllocTemp.Applied_To_Trans__c=Null;
        invPayAllocTemp.Payment_Number__c=Null;
        invPayAllocTemp.Internal_ID__c=Null;
        invPayAllocTemp.Applied_Amount__c=Null;
        invPayAllocTemp.OSA__c='12345';
        invPayAllocTemp.T_OSAMatched__c= False;
        
        insert invPayAllocTemp;
        
        // Start the test
        test.startTest();
        
        // Execute the batch class to be tested
        String tempPayAlloc='PaymentAlloc';
        T_SourceInvoiceMove batchClass = new T_SourceInvoiceMove(tempPayAlloc);
        Database.executeBatch(batchClass);
        
        // Stop the test
        test.stopTest();
        
        
        // Verify the results
        List<T_qtc_ActiveCustomer_Payment_Alloc_Detai__c> tempList = [SELECT Id,T_OSAMatched__c FROM T_qtc_ActiveCustomer_Payment_Alloc_Detai__c];
        if(tempList.size()>0){
            System.assertEquals(tempList[0].T_OSAMatched__c,True,'Record Matched Succesfully');
        }
        
    }
    @isTest
    public static void updateCreditNoteTest(){
        
        //// Creating a test T_OSA__c record
        T_OSA__c tempOSA = new T_OSA__c();
        tempOSA.ContractNumber__c = '12345';
        
        insert tempOSA;
        
        // // Creating a test T_qtc_Active_Credit_Memo_Lines_Header__c record 
        T_qtc_Active_Credit_Memo_Lines_Header__c creditMemoTemp = new T_qtc_Active_Credit_Memo_Lines_Header__c();
        creditMemoTemp.Billing_StateProvince__c=Null;
        creditMemoTemp.Billing_Addressee__c=Null;
        creditMemoTemp.Shipping_Attention__c=Null;
        creditMemoTemp.Billing_Attention__c=Null;
        creditMemoTemp.Amount_Foreign_Currency__c=Null;
        creditMemoTemp.Billing_Address__c=Null;
        creditMemoTemp.Billing_Address_1__c=Null;
        creditMemoTemp.Price_Level__c=Null;
        creditMemoTemp.of_Months__c=Null;
        creditMemoTemp.Reference_ID_Bundle__c=Null;
        creditMemoTemp.Shipping_Zip__c=Null;
        creditMemoTemp.Currency__c=Null;
        creditMemoTemp.Billing_City__c=Null;
        creditMemoTemp.Item__c=Null;
        creditMemoTemp.Item_Rate_without_Currency_Symbol__c=Null;
        creditMemoTemp.Shipping_Country__c=Null;
        creditMemoTemp.Status__c=Null;
        creditMemoTemp.Line_ID__c=Null;
        creditMemoTemp.Created_From__c=Null;
        creditMemoTemp.Order_Type__c=Null;
        creditMemoTemp.Rev_Rec_End_Date__c=Null;
        creditMemoTemp.OSA_TEXT_for_vlookup__c=Null;
        creditMemoTemp.Shipping_Addressee__c=Null;
        creditMemoTemp.Shipping_Address_2__c=Null;
        creditMemoTemp.Account_ID__c=Null;
        creditMemoTemp.Item_Rate__c=Null;
        creditMemoTemp.Shipping_Country_Code__c=Null;
        creditMemoTemp.POCheck_Number__c=Null;
        creditMemoTemp.Credit_Memo_Reasons__c=Null;
        creditMemoTemp.Support_Level__c=Null;
        creditMemoTemp.VAT_Code__c=Null;
        creditMemoTemp.OSA_Contract_Number_RA__c=Null;
        creditMemoTemp.Memo_1__c=Null;
        creditMemoTemp.Memo__c=Null;
        creditMemoTemp.Internal_ID__c=Null;
        creditMemoTemp.Billing_Zip__c=Null;
        creditMemoTemp.OSA_Contract_Number_from_Salesforce__c='12345';
        creditMemoTemp.Document_Number__c=Null;
        creditMemoTemp.Billing_Address_2__c=Null;
        creditMemoTemp.Amount_without_currency_symbol__c=Null;
        creditMemoTemp.Sales_Order_Type__c=Null;
        creditMemoTemp.Rev_Rec_Start_Date__c=Null;
        creditMemoTemp.Shipping_Address__c=Null;
        creditMemoTemp.Shipping_Address_1__c=Null;
        creditMemoTemp.Subsidiary_no_hierarchy__c=Null;
        creditMemoTemp.Shipping_StateProvince__c=Null;
        creditMemoTemp.Tax_Item__c=Null;
        creditMemoTemp.Billing_Country__c=Null;
        creditMemoTemp.Shipping_City__c=Null;
        creditMemoTemp.Period__c=Null;
        creditMemoTemp.Type__c=Null;
        creditMemoTemp.Billing_Country_Code__c=Null;
        creditMemoTemp.T_OSAMatched__c= False;
        creditMemoTemp.Date__c=Null;
        creditMemoTemp.Name__c=Null;
        creditMemoTemp.Product_Line__c=Null;
        creditMemoTemp.Quantity__c=Null;
        
        insert creditMemoTemp;
        
        // Start the test
        test.startTest();
        
        // Execute the batch class to be tested
        String tempCR='CreditNote';
        T_SourceInvoiceMove batchClass = new T_SourceInvoiceMove(tempCR);
        Database.executeBatch(batchClass);
        
        // Stop the test
        test.stopTest();
        
        // Verify the results
        List<T_qtc_Active_Credit_Memo_Lines_Header__c> tempList = [SELECT Id,T_OSAMatched__c FROM T_qtc_Active_Credit_Memo_Lines_Header__c];
        if(tempList.size()>0){
            System.assertEquals(tempList[0].T_OSAMatched__c,True,'Record Matched Succesfully');
        }
        
    }
    @isTest
    public static void updateCMLinesTest(){
        
        //Creating a test T_OSA__c record
        T_OSA__c tempOSA = new T_OSA__c();
        tempOSA.ContractNumber__c = '12345';
        
        insert tempOSA;
        
        //// Creating a test T_qtc_Active_Credit_Memo_Tax_Line__c record
        T_qtc_Active_Credit_Memo_Tax_Line__c creditMemoTaxLineTemp = new T_qtc_Active_Credit_Memo_Tax_Line__c();
        creditMemoTaxLineTemp.Internal_ID__c=Null;
        creditMemoTaxLineTemp.Type__c=Null;
        creditMemoTaxLineTemp.Subsidiary_no_hierarchy__c=Null;
        creditMemoTaxLineTemp.Created_From__c=Null;
        creditMemoTaxLineTemp.Memo__c=Null;
        creditMemoTaxLineTemp.OSA_TEXT_for_vlookup__c=Null;
        creditMemoTaxLineTemp.Line_ID__c=Null;
        creditMemoTaxLineTemp.Price_Level__c=Null;
        creditMemoTaxLineTemp.Item_Rate_without_Symbol__c=Null;
        creditMemoTaxLineTemp.Amount_Foreign_Currency__c=Null;
        creditMemoTaxLineTemp.Foreign_Amount_without_Symbol__c=Null;
        creditMemoTaxLineTemp.Support_Level__c=Null;
        creditMemoTaxLineTemp.Reference_ID_Bundle__c=Null;
        creditMemoTaxLineTemp.Rev_Rec_End_Date__c=Null;
        creditMemoTaxLineTemp.Order_Type__c=Null;
        creditMemoTaxLineTemp.Document_Number__c=Null;
        creditMemoTaxLineTemp.Name__c=Null;
        creditMemoTaxLineTemp.Date__c=Null;
        creditMemoTaxLineTemp.Period__c=Null;
        creditMemoTaxLineTemp.OSA_Contract_Number_from_Salesforce__c='12345';
        creditMemoTaxLineTemp.Credit_Memo_Reasons__c=Null;
        creditMemoTaxLineTemp.Item__c=Null;
        creditMemoTaxLineTemp.Item_Rate__c=Null;
        creditMemoTaxLineTemp.Tax_Item__c=Null;
        creditMemoTaxLineTemp.OSA_Contract_Number_RA__c=Null;
        creditMemoTaxLineTemp.Rev_Rec_Start_Date__c=Null;
        creditMemoTaxLineTemp.Product_Line__c=Null;
        creditMemoTaxLineTemp.Sales_Order_Type__c=Null;
        creditMemoTaxLineTemp.Quantity__c=Null;
        creditMemoTaxLineTemp.VAT_Code__c=Null;
        creditMemoTaxLineTemp.of_Months__c=Null;
        creditMemoTaxLineTemp.T_OSAMatched__c= False;
        creditMemoTaxLineTemp.Currency__c=Null;
        creditMemoTaxLineTemp.PO_Check_Number__c=Null; 
        
        insert creditMemoTaxLineTemp;
        
        // Start the test
        test.startTest();
        
        // Execute the batch class to be tested
        String tempCM = 'CMLines';
        T_SourceInvoiceMove batchClass = new T_SourceInvoiceMove(tempCM);
        Database.executeBatch(batchClass);
        
        // Stop the test
        test.stopTest();
        
        // Verify the results
        List<T_qtc_Active_Credit_Memo_Tax_Line__c> tempList = [SELECT Id,T_OSAMatched__c FROM T_qtc_Active_Credit_Memo_Tax_Line__c];
        if(tempList.size()>0){
            System.assertEquals(tempList[0].T_OSAMatched__c,True,'Record Matched Succesfully');
        }   
    }
    @isTest
    public static void updateCMAllocTest() {
        
        // Creating a test T_OSA__c record
        T_OSA__c osaRecord = new T_OSA__c();
        osaRecord.ContractNumber__c = '12345';
        insert osaRecord;
        
        // Creating a test T_qtc_Active_Credit_Memo_Allocation__c record
        T_qtc_Active_Credit_Memo_Allocation__c creditMemoAllocRecord = new T_qtc_Active_Credit_Memo_Allocation__c();
        creditMemoAllocRecord.Type__c = null;
        creditMemoAllocRecord.Applied_To_Internal_ID__c = null;
        creditMemoAllocRecord.Applied_To_Doc_Number__c = null;
        creditMemoAllocRecord.OSA_Contract_Number_from_Salesforce__c = '12345';
        creditMemoAllocRecord.Document_Number__c = null;
        creditMemoAllocRecord.Applied_To_Amt__c = null;
        creditMemoAllocRecord.Applied_to_Amt_without_Symbol__c = null;
        creditMemoAllocRecord.Applied_To_Link__c = null;
        creditMemoAllocRecord.Internal_ID__c = null;
        creditMemoAllocRecord.Date__c = null;
        creditMemoAllocRecord.Formula_Text__c = null;
        creditMemoAllocRecord.T_OSAMatched__c = False;
        insert creditMemoAllocRecord;
        
        // Start the test
        test.startTest();
        
        // Execute the batch class to be tested
        String tempCMAlloc = 'CMAlloc';
        T_SourceInvoiceMove batchClass = new T_SourceInvoiceMove(tempCMAlloc);
        Database.executeBatch(batchClass);
        
        // Stop the test
        test.stopTest();
        
        // Verify the results
        List<T_qtc_Active_Credit_Memo_Allocation__c> resultList = [SELECT Id, T_OSAMatched__c FROM T_qtc_Active_Credit_Memo_Allocation__c];
        if (resultList.size() > 0) {
            System.assertEquals(true, resultList[0].T_OSAMatched__c, 'Record Matched Successfully');
        }
    }    
}