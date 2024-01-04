/********************************************************************************     
 *  Name             :  OpportunityTriggerHandler
 *  Author           :  Anisha Dhekne
 *  Description      : Test Class for Opportunity Trigger
 *                   
 *  Change history   :
 *  Date		  Author					  Description
 * 03/29/2018    Anisha Dhekne					Created
 ********************************************************************************/

@isTest
private class OpportunityTriggerHandlerTest {
    @isTest
	private static void checkClosedWonValue() {
    	OpportunityTriggerHandler.populateValueofOpportunities(new List<opportunity>());
    }
    
	/*
	//Test method for summation formula of Closed Won Opportunities
	@isTest
	private static void checkClosedWonValue() {
		User usr = (User) SmartFactory.createSObject('User');
		insert usr;

		List<Opportunity> list_opps = new List<Opportunity> ();

		Campaign camp = (Campaign) SmartFactory.createSObject('Campaign');
		camp.name = 'test';
		insert camp;

		Opportunity oppt = (Opportunity) SmartFactory.createSObject('Opportunity');
		oppt.Type = 'Legal -Open';
		oppt.Name = 'testa';
		oppt.CloseDate = Date.today();
		oppt.StageName = 'Closed Won';
		oppt.CurrencyIsoCode = 'USD';
		oppt.CampaignId = camp.Id;

		oppt.Maintenance_Amount__c = 3500;
		//insert oppt;
		list_opps.add(oppt);

		Opportunity oppt1 = (Opportunity) SmartFactory.createSObject('Opportunity');
		oppt1.Type = 'Legal -Open';
		oppt1.Name = 'testb';
		oppt1.CloseDate = Date.today();
		oppt1.StageName = 'Closed Won';
		oppt1.CurrencyIsoCode = 'USD';
		oppt1.CampaignId = camp.Id;
		oppt1.Maintenance_Amount__c = 3000;
		//	insert oppt1;


		list_opps.add(oppt1);

		System.runAs(usr)
		{
			insert list_opps;
		}
		camp.Value_of_Closed_Won_opportunities__c = [Select Value_of_Closed_Won_opportunities__c, (Select Maintenance_Amount__c from Opportunities) from Campaign where Id = :camp.Id].Value_of_Closed_Won_opportunities__c;
		update(list_opps);
		System.assertEquals(camp.Value_of_Closed_Won_opportunities__c, 6500);
	}

	//Test method for summation formula of Open Opportunities
	@isTest
	private static void checkOpenValue() {
		User usr = (User) SmartFactory.createSObject('User');
		insert usr;

		List<Opportunity> list_opps = new List<Opportunity> ();

		Campaign camp = (Campaign) SmartFactory.createSObject('Campaign');
		camp.name = 'test';
		insert camp;

		Opportunity oppt = (Opportunity) SmartFactory.createSObject('Opportunity');
		oppt.Type = 'Legal -Open';
		oppt.Name = 'testa';
		oppt.CloseDate = Date.today();
		oppt.StageName = 'Expression of Interest';
		oppt.CurrencyIsoCode = 'USD';
		oppt.CampaignId = camp.Id;

		oppt.Maintenance_Amount__c = 2000;

		list_opps.add(oppt);

		Opportunity oppt1 = (Opportunity) SmartFactory.createSObject('Opportunity');
		oppt1.Type = 'Legal -Open';
		oppt1.Name = 'testb';
		oppt1.CloseDate = Date.today();
		oppt1.StageName = 'Expression of Interest';
		oppt1.CurrencyIsoCode = 'USD';
		oppt1.CampaignId = camp.Id;
		oppt1.Maintenance_Amount__c = 5500;

		list_opps.add(oppt1);

		System.runAs(usr)
		{
			insert list_opps;
		}
		camp.Value_of_Open_opportunities__c = [Select Value_of_Open_opportunities__c, (Select Maintenance_Amount__c from Opportunities) from Campaign where Id = :camp.Id].Value_of_Open_opportunities__c;
		update(list_opps);
		System.assertEquals(camp.Value_of_Open_opportunities__c, 7500);

	}

	//Test method for summation formula of Target Account Opportunities
	@isTest
	private static void checkTargetAccountValue() {
		User usr = (User) SmartFactory.createSObject('User');
		insert usr;

		List<Opportunity> list_opps = new List<Opportunity> ();

		Campaign camp = (Campaign) SmartFactory.createSObject('Campaign');
		camp.name = 'test';
		insert camp;

		Opportunity oppt = (Opportunity) SmartFactory.createSObject('Opportunity');
		oppt.Type = 'Legal -Open';
		oppt.Name = 'testa';
		oppt.CloseDate = Date.today();
		oppt.StageName = 'Target Account';
		oppt.CurrencyIsoCode = 'USD';
		oppt.CampaignId = camp.Id;

		oppt.Maintenance_Amount__c = 4000;

		list_opps.add(oppt);

		Opportunity oppt1 = (Opportunity) SmartFactory.createSObject('Opportunity');
		oppt1.Type = 'Legal -Open';
		oppt1.Name = 'testb';
		oppt1.CloseDate = Date.today();
		oppt1.StageName = 'Target Account';
		oppt1.CurrencyIsoCode = 'USD';
		oppt1.CampaignId = camp.Id;
		oppt1.Maintenance_Amount__c = 8000;

		list_opps.add(oppt1);

		System.runAs(usr)
		{
			insert list_opps;
		}
		camp.Value_of_Target_Account_opportunities__c = [Select Value_of_Target_Account_opportunities__c, (Select Maintenance_Amount__c from Opportunities) from Campaign where Id = :camp.Id].Value_of_Target_Account_opportunities__c;
		update(list_opps);
		System.assertEquals(camp.Value_of_Target_Account_opportunities__c, 12000);
	}
*/
}