/**
* @description       : This class is used in Approval Email Template.
* @author            : Rajani
* @last modified on  : 01-08-2024
* @last modified by  : Pankaj Kumar
**/
public class SendAttachmentsWithEmails {

    public  String controllerValue;
    public  Boolean attachmentFound{get;set;}
    
    public SendAttachmentsWithEmails(){
        attachmentFound =false;
    }
    public  void  setControllerValue (String s) {      
        try{ 
            SBQQ__QuoteDocument__c cdl = [select Id,SBQQ__AttachmentId__c,SBQQ__DocumentId__c,SBQQ__Quote__c from SBQQ__QuoteDocument__c 
                                          where SBQQ__Quote__c =: s 
                                          ORDER BY CreatedDate DESC LIMIT 1];    
            
            if(cdl.SBQQ__DocumentId__c !=null){       
                controllerValue = URL.getOrgDomainURL().toExternalForm()+'/servlet/servlet.FileDownload?file='+cdl.SBQQ__DocumentId__c;
                attachmentFound = true;
            }else if(cdl.SBQQ__AttachmentId__c !=null){
                controllerValue = URL.getOrgDomainURL().toExternalForm()+'/servlet/servlet.FileDownload?file='+cdl.SBQQ__AttachmentId__c;
                attachmentFound = true;            
            }
       }
        catch(Exception ex){
            System.debug('Exception Caught  :'+ex.getMessage() + ' **Line Number : '+ex.getLineNumber());
        } 
    }
    
    public  String getControllerValue() {
        return controllerValue;
    }   
}