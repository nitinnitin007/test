public class SendAttachmentsWithEmails {
    
/* method to send attachments with email alerts*/
	
	public  String controllerValue;
    public  Boolean attachmentFound{get;set;}
    
    public SendAttachmentsWithEmails(){
        attachmentFound =false;
    }
 	public  void  setControllerValue (String s) {
      
        try{ 
	ContentDocumentLink cdl = [select id,LinkedEntityId, ContentDocumentId  from ContentDocumentLink 
                               where LinkedEntityId =: s AND (ContentDocument.Title like '%Pricing Proposal%' OR ContentDocument.Title like '%OSA%')
                               ORDER BY ContentDocument.CreatedDate DESC LIMIT 1];
			
            if(cdl.ContentDocumentId !=null){		
    		controllerValue = URL.getOrgDomainURL().toExternalForm()+'/sfc/servlet.shepherd/document/download/'+cdl.ContentDocumentId+'?operationContext=S1';
            attachmentFound = true;
            }
   }
        catch(Exception ex)
        {
            System.debug('Exception Caught  :'+ex.getMessage() + ' **Line Number : '+ex.getLineNumber());
        } 
    }

  public  String getControllerValue() {
    return controllerValue;
  } 
   
}