/**
* @File Name     : ContentFilesTriggerHandlerTest
* @Created BY    : Seena
* @Date          : 31 August ,2023
* @Description	 : Test class for ContentFilesTriggerHandler.
**/
@isTest
public class ContentFilesTriggerHandlerTest {
   @isTest
    public static void testAfterInsert() 
    {
        //Create Account
        Account acc = IntappTestObjectFactory.createAccount(true);
        //Create Billing Invoice
        blng__Invoice__c invoice = new blng__Invoice__c ();
        invoice.blng__Account__c = acc.Id;
        insert invoice;
  		//CreateContent Version
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'testdocument.txt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;    
        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId 
            FROM ContentDocument
        ];
        
        //Create ContentDocumentLink  
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = invoice.Id;//acc.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        Test.startTest();
        // Trigger the afterInsert logic
        Map<Id, ContentDocumentLink> newCDLinksMap = new Map<Id, ContentDocumentLink>{cdl.Id => cdl};
        ContentFilesTriggerHandler.afterInsert(newCDLinksMap);
        Test.stopTest();
        //After Insert
        List<blng__Invoice__c> blngInvs = [SELECT Id,Document_Generated_On__c,Latest_Document_Id__c FROM blng__Invoice__c
                                        WHERE Id = :invoice.Id];
        if(blngInvs.size()>0 && cdl.ContentDocumentId != null && blngInvs[0].Latest_Document_Id__c != null)
        {System.assertEquals(cdl.ContentDocumentId,blngInvs[0].Latest_Document_Id__c, 'ContentDocument Id updated');}
        
    }
 
}