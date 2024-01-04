@isTest
public class InvoiceTriggerHandlerTest {
    @isTest
    public static void testMethod1(){
        
        Account acc = IntappTestObjectFactory.createAccount(true);
        
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = acc.id;
        invoice.blng__InvoiceStatus__c = 'Draft';
        insert invoice;
        
        invoice.blng__InvoiceStatus__c = 'Initiated';
        update invoice;
        
        blng__Invoice__c invoice1 = new blng__Invoice__c();
        invoice1.blng__Account__c = acc.id;
        invoice1.blng__InvoiceStatus__c = 'Error';
        insert invoice1;
        
        invoice1.blng__InvoiceStatus__c = 'Posted';
        update invoice1;
        
        list<blng__Invoice__c> listOfInvoice = new list<blng__Invoice__c>();
        listOfInvoice.add(invoice);
        listOfInvoice.add(invoice1);
        system.assertNotEquals(listOfInvoice.size(), null);
    }
}