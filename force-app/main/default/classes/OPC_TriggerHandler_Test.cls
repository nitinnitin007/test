@isTest
public class OPC_TriggerHandler_Test {
    
	static testMethod void test_onInsert(){
            Opportunity opp = (Opportunity) SmartFactory.createSObject('Opportunity');
            insert opp;
            
            Opportunity_Product_Component__c opc = (Opportunity_Product_Component__c) SmartFactory.createSObject('Opportunity_Product_Component__c');
            opc.Recurring_Amount_Change__c = 2000;
            opc.Opportunity__c = opp.id;
            insert opc;
    }
}