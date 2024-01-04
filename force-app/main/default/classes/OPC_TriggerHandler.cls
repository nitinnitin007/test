public class OPC_TriggerHandler {
    
    public static void beforeInsert(List<Opportunity_Product_Component__c> Records){
        updateType(Records);
    }
    
    public static void afterInsert(List<Opportunity_Product_Component__c> Records){
        updateRAC_onOpp(Records, null, false);
    }
    
    public static void afterUpdate(List<Opportunity_Product_Component__c> Records, Map<Id, Opportunity_Product_Component__c> oldRecords){
        updateRAC_onOpp(Records, oldRecords, false);
    }
    
    public static void afterDelete(List<Opportunity_Product_Component__c> Records){
      updateRAC_onOpp(Records, null, true);
    }    
    
    public static void updateRAC_onOpp(List<Opportunity_Product_Component__c> opcs, Map<Id, Opportunity_Product_Component__c> oldRecords, Boolean isDelete){
        if(RecursionHandler.checkRecursion()){
            return;
        }
        Map<Id, Decimal> Map_OppId_RACUpdate = new Map<Id, Decimal>();
        List<Opportunity> list_ToUpdate = new List<Opportunity>();
        
        for(Opportunity_Product_Component__c opc : opcs){
            Decimal RAC = 0;
            
            if(Map_OppId_RACUpdate.containsKey(opc.Opportunity__c)){
              RAC = Map_OppId_RACUpdate.get(opc.Opportunity__c);
            }
            
            Decimal opc_RAC = opc.Recurring_Amount_Change__c == null ? 0 : opc.Recurring_Amount_Change__c;
            
            RAC += opc_RAC; 
                
            Map_OppId_RACUpdate.put(opc.Opportunity__c, RAC);
        }
        
        for(Opportunity opp: [Select Id, Maintenance_Amount__c, Opp_Product_Lines__c,
                             (Select Id, Recurring_Amount_Change__c,Product_Line__c, Product_LineNew__c, Product_LineNew__r.Name from Opportunity_Product_Components__r) 
                              FROM Opportunity where Id in : Map_OppId_RACUpdate.keySet()]){
            opp.Maintenance_Amount__c = 0;
            //opp.Opportunity_Product_Lines__c = '';
            opp.Opp_Product_Lines__c = '';
            for(Opportunity_Product_Component__c opc: opp.Opportunity_Product_Components__r){
                //OPP RAC
                opp.Maintenance_Amount__c += opc.Recurring_Amount_Change__c == null ? 0 : opc.Recurring_Amount_Change__c;
                
                //OPP PROD LINES (TEXT)
                /*
                  if(opc.Product_Line__c != null && !opp.Opp_Product_Lines__c.contains(opc.Product_Line__c))
                    opp.Opp_Product_Lines__c += opc.Product_Line__c + ';';
                */
                
                if(opc.Product_LineNew__c == null && !opp.Opp_Product_Lines__c.contains('Other')){
                    opp.Opp_Product_Lines__c += 'Other;';
                }
                else if(opc.Product_LineNew__c != null && opc.Product_LineNew__r.Name != null && !opp.Opp_Product_Lines__c.contains(opc.Product_LineNew__r.Name)){
                    opp.Opp_Product_Lines__c += opc.Product_LineNew__r.Name + ';';
                }
            }
                                  
            opp.Opp_Product_Lines__c = opp.Opp_Product_Lines__c.removeEnd(';');
            list_ToUpdate.add(opp);
        }
        
        if(list_ToUpdate.size() > 0) update list_ToUpdate;
        
    }
    
    private static void updateType(List<Opportunity_Product_Component__c> opcs){
        Map<Id, Opportunity> OppsWithType = new Map<Id, Opportunity>();
        
        //Get all Opportunities into the above map
        for(Opportunity_Product_Component__c opc: opcs){
            OppsWithType.put(opc.Opportunity__c, null);
        }
        
        //Query for type of the opportunities
        for(Opportunity opp: [Select Id, Type from Opportunity where Id in : OppsWithType.keySet()]){
            OppsWithType.put(opp.Id, opp);
        }
        
        for(Opportunity_Product_Component__c opc: opcs){
            if(OppsWithType.containskey(opc.Opportunity__c))
                opc.Type__c = OppsWithType.get(opc.Opportunity__c).Type;
        }
    }
}