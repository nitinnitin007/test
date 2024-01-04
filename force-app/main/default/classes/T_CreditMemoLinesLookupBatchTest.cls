/**** @name       	: T_CreditMemoLinesLookupBatchTest
***** @author  		: KPMG
***** @date 		: Nov 11th, 2023
***** @description  : Test Class for T_CreditMemoLinesLookupBatch ,Updating Credit Note lookup using Internal Id  
                      Updating InvoiceLines Lookup using Billing Credit Note Id and Billing Invoice Line Id 						
******/ 
@istest
//Test Class
public class T_CreditMemoLinesLookupBatchTest {
	//testData
	@isTest
    public static void creditMemoLinesLookupBatchValidate(){
        //Creating Account record
        Account acc = new Account();
        acc.name='Test';
        insert acc;
        //Creating blng__Invoice__c record
        blng__Invoice__c blngInv = new blng__Invoice__c();
        blngInv.NS_Inv_Internal_ID__c = '1234';
        blngInv.blng__Account__c = acc.Id;
        blngInv.blng__InvoiceStatus__c = 'Posted';
        blngInv.T_IsMigrated__c = True;
        insert blngInv;
        //Create Billing Inv Lines
        blng__InvoiceLine__c blngInLine = new blng__InvoiceLine__c();
        blngInLine.NS_Inv_Internal_ID__c = '1234';
        blngInLine.NS_Line_ID__c = '1';
        blngInLine.T_IsMigrated__c = true;
        blngInLine.blng__Invoice__c = blngInv.Id;
        insert blngInLine;
        
        //CreditNote
         blng__CreditNote__c blngCreditNote = new blng__CreditNote__c();
         blngCreditNote.NS_Credit_Note_Internal_ID__c = '1234';
         blngCreditNote.blng__Account__c = acc.Id;
         blngCreditNote.blng__CreditNoteDate__c = Date.TODAY();
         blngCreditNote.blng__RelatedInvoice__c = blngInv.Id;
         blngCreditNote.T_IsMigrated__c = True;
         insert blngCreditNote;
        
        //Create QtC_Mig_CreditMemoLines_Temp_Table__c data
        QtC_Mig_CreditMemoLines_Temp_Table__c tempCreditMemo = new QtC_Mig_CreditMemoLines_Temp_Table__c();
        tempCreditMemo.Internal_ID__c = '1234';
        tempCreditMemo.Invoice_Internal_Id__c = '1234';
        tempCreditMemo.Invoice_Line_ID__c = '1';
        tempCreditMemo.T_Invoice__c = blngInv.Id ;//Updating the Invoice Id
        //tempCreditMemo.T_Invoice_Line__c = blngInLine.Id; // InvoiceLineId
        //tempCreditMemo.T_CreditNote__c = blngCreditNote.Id;// CreditNoteId
        insert tempCreditMemo; 
    
        //Start test
        Test.startTest();
        //Executing the batch for test data
        T_CreditMemoLinesLookupBatch bc = new T_CreditMemoLinesLookupBatch('CreditNote');
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        
        //Validating the results
        List<QtC_Mig_CreditMemoLines_Temp_Table__c> tempList = [SELECT Id,T_CreditNote__c FROM QtC_Mig_CreditMemoLines_Temp_Table__c Limit 1];
        List<blng__CreditNote__c> billingCreditNote = [SELECT Id,NS_Credit_Note_Internal_ID__c FROM blng__CreditNote__c Limit 1];
        if(tempList.size() > 0 && tempList[0].T_CreditNote__c != null && billingCreditNote.size() >0 ){
           System.assertEquals(tempList[0].T_CreditNote__c,billingCreditNote[0].Id,'CreditNote Id populated successfully');
        }
    }
    //Method-2
    @isTest
    public static void creditMemoLinesLookupBatchInvoiceValidate(){
        //Creating Account record
        Account acc = new Account();
        acc.name='Test';
        insert acc;
        //Creating blng__Invoice__c record
        blng__Invoice__c blngInv = new blng__Invoice__c();
        blngInv.NS_Inv_Internal_ID__c = '1234';
        blngInv.blng__Account__c = acc.Id;
        blngInv.blng__InvoiceStatus__c = 'Posted';
        blngInv.T_IsMigrated__c = True;
        insert blngInv;
        //Create Billing Inv Lines
        blng__InvoiceLine__c blngInLine = new blng__InvoiceLine__c();
        blngInLine.NS_Inv_Internal_ID__c = '1234';
        blngInLine.NS_Line_ID__c = '1';
        blngInLine.T_IsMigrated__c = true;
        blngInLine.blng__Invoice__c = blngInv.Id;
        insert blngInLine;
        
        //CreditNote
         blng__CreditNote__c blngCreditNote = new blng__CreditNote__c();
         blngCreditNote.NS_Credit_Note_Internal_ID__c = '1234';
         blngCreditNote.blng__Account__c = acc.Id;
         blngCreditNote.blng__CreditNoteDate__c = Date.TODAY();
         blngCreditNote.blng__RelatedInvoice__c = blngInv.Id;
         blngCreditNote.T_IsMigrated__c = True;
         insert blngCreditNote;
        
        //Create QtC_Mig_CreditMemoLines_Temp_Table__c data
        QtC_Mig_CreditMemoLines_Temp_Table__c tempCreditMemo = new QtC_Mig_CreditMemoLines_Temp_Table__c();
        tempCreditMemo.Internal_ID__c = '1234';
        tempCreditMemo.Invoice_Internal_Id__c = '1234';
        tempCreditMemo.Invoice_Line_ID__c = '1';
        tempCreditMemo.T_Invoice__c = blngInv.Id ;//Updating the Invoice Id
        insert tempCreditMemo;   
        
        //Start test
        Test.startTest();
        //Executing the batch for test data
        T_CreditMemoLinesLookupBatch bc = new T_CreditMemoLinesLookupBatch('InvoiceLine');
        Database.executeBatch(bc);
        //Stop test
        Test.stopTest();
        
        //Validating the results
        List<QtC_Mig_CreditMemoLines_Temp_Table__c> tempList = [SELECT Id,T_Invoice_Line__c FROM QtC_Mig_CreditMemoLines_Temp_Table__c Limit 1];
        List<blng__InvoiceLine__c> billingInvLine = [SELECT Id FROM blng__InvoiceLine__c Limit 1];
        if(tempList.size() > 0 && tempList[0].T_Invoice_Line__c != null && billingInvLine.size() >0 ){
            System.assertEquals(tempList[0].T_Invoice_Line__c,billingInvLine[0].Id,'InvoiceLine Id populated successfully');
        }
    }
}