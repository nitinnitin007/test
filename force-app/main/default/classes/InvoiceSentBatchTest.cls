@isTest()
public class InvoiceSentBatchTest {
    
    @isTest()
    public static void testInvoiceSent() {

        List<T_Invoice_Sent__c> invoiceSentList = new List<T_Invoice_Sent__c>();
        T_Invoice_Sent__c invoiceSent = new T_Invoice_Sent__c();
        invoiceSent.Internal_Id__c = '12345';
        invoiceSent.count__c = 2;
        invoiceSentList.add(invoiceSent);

        T_Invoice_Sent__c invoiceSent2 = new T_Invoice_Sent__c();
        invoiceSent2.Internal_Id__c = '123456';
        invoiceSent2.count__c = 0;
        invoiceSentList.add(invoiceSent2);

        insert invoiceSentList;

        List<T_Invoice_NewTemp__c> invoiceList = new List<T_Invoice_NewTemp__c>();
        T_Invoice_NewTemp__c invoice = new T_Invoice_NewTemp__c();
        invoice.Internal_ID__c = '12345';
        invoiceList.add(invoice);

        T_Invoice_NewTemp__c invoice2 = new T_Invoice_NewTemp__c();
        invoice2.Internal_ID__c = '123456';
        invoiceList.add(invoice2);

        insert invoiceList;

        test.startTest();
        Database.executeBatch(new InvoiceSentBatch());
        test.stopTest();

        system.assertEquals(1, [SELECT Id FROM T_Invoice_NewTemp__c WHERE invoice_sent__c = true].size());
        system.assertEquals(1, [SELECT Id FROM T_Invoice_NewTemp__c WHERE invoice_sent__c = false].size());
    }
}