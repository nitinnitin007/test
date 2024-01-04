public class Batch_Historical_UpdateOppProdLines implements Database.Batchable<SObject>,Database.Stateful{
    public String query;
    public Integer batch_number = 0; 
    public Set<Integer> batchToSkip = new Set<Integer>();
    
    public Batch_Historical_UpdateOppProdLines(String query, Set<Integer> bToSkip) {
        this.query = query;
        this.batchToSkip = bToSkip;
    }
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Opportunity> listToUpdate = new List<Opportunity>();
        
        List<Opportunity_Product_Component__c> list_opcs = new List<Opportunity_Product_Component__c>();
        
        String listWithProblem = '';
        batch_number ++;
        
        for(Opportunity opp: [Select Id, Opp_Product_Lines__c, (Select Id, Product_LineNew__c, Product_LineNew__r.Name from Opportunity_Product_Components__r) from Opportunity where id in : scope]){
            opp.Opp_Product_Lines__c = '';
            for(Opportunity_Product_Component__c opc : opp.Opportunity_Product_Components__r){
                String opc_pl = '';
                opc_pl = opc.Product_LineNew__c != null ? opc.Product_LineNew__r.Name : 'Other';
                opp.Opp_Product_Lines__c += opc_pl + ';';
            }   
            opp.Opp_Product_Lines__c = opp.Opp_Product_Lines__c.removeEnd(';');
            listWithProblem += Opp.Id + '-' + opp.Opp_Product_Lines__c + '<br/>\r\n';
            listToUpdate.add(opp);
        }
        
        if(batchToSkip != null && batchToSkip.contains(batch_number)){
        	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Batch # ' + batch_number);
            mail.setHtmlBody(listWithProblem);
            mail.setToAddresses(new List<String>{'venkat.sriram@intapp.com'});
            List<Messaging.SingleEmailMessage> Mails = new List<Messaging.SingleEmailMessage>();
            Mails.add(mail);
            Messaging.sendEmail(Mails);   
        }
        
        if(batchToSkip == null || !batchToSkip.contains(batch_number))
        //if(listToUpdate.size() > 0) update listToUpdate;
        	list<Database.SaveResult> results = Database.update(listToUpdate, false);    
        
    }
    
    public void finish(Database.BatchableContext context) {
            /*
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Batch # ' + batch_number);
            mail.setHtmlBody(listWithProblem);
            mail.setToAddresses(new List<String>{'venkat.sriram@intapp.com'});
            List<Messaging.SingleEmailMessage> Mails = new List<Messaging.SingleEmailMessage>();
            Mails.add(mail);
            Messaging.sendEmail(Mails);
            */
    }

}