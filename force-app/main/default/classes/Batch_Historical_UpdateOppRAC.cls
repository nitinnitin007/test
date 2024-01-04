public class Batch_Historical_UpdateOppRAC implements Database.Batchable<SObject> {
    public String query;
    public Set<Integer> batchToSkip = new Set<Integer>();
    public Integer batch_number = 0; 
    
    public Batch_Historical_UpdateOppRAC(String query, Set<Integer> bToSkip) {
        this.query = query;
        this.batchToSkip = bToSkip;
    }
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Opportunity> listToUpdate = new List<Opportunity>();
        batch_number ++;
        String listWithProblem = '';
        for(Opportunity opp: (List<Opportunity>) scope){
            Decimal totalRAC = 0;
            for(Opportunity_Product_Component__c  opc: opp.Opportunity_Product_Components__r){
                if(opc.Recurring_Amount_Change__c != null)
                totalRAC += opc.Recurring_Amount_Change__c;
            }
            opp.Maintenance_Amount__c = totalRAC;
            listWithProblem +=  Opp.Id + '<br/>\r\n';
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
            list<Database.SaveResult> results = Database.update(listToUpdate, false);
    }
    
    public void finish(Database.BatchableContext context) {
        
    }


}