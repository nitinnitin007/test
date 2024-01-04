/**
Test class for OrderHeaderService class 
**/
@isTest
private class OrderHeaderServiceTest {

	@testSetup static void CreateTestData() {
		//Create using IntappTestObjectFactory (contract and opportunity)
		Account a = IntappTestObjectFactory.createAccount(true);

		Contract c = IntappTestObjectFactory.createContract(a.Id);
		insert c;

		Contact u = IntappTestObjectFactory.createContact(true);

		Opportunity o = IntappTestObjectFactory.createOpportunity();
		o.Client_Contact__c = u.Id;
		o.AccountId = a.Id;
		o.Associated_Contract_OSA__c = c.id;
		insert o;
		
        Product_Line__c pl1 = new Product_Line__c();
        pl1.Name = 'Walls';
        pl1.Active__c = true;
        insert pl1;
        
        Product_Line__c pl2 = new Product_Line__c();
        pl2.Name = 'Integrate';
        pl2.Active__c = true;
        insert pl2;
        
		Opportunity_Product_Component__c opc1 = (Opportunity_Product_Component__c) SmartFactory.createSObject('Opportunity_Product_Component__c');
		opc1.Opportunity__c = o.Id;
		opc1.Product_Line__c = 'Intapp Walls';
		opc1.Product_LineNew__c = pl1.Id;
        
		Opportunity_Product_Component__c opc2 = (Opportunity_Product_Component__c) SmartFactory.createSObject('Opportunity_Product_Component__c');
		opc2.Opportunity__c = o.Id;
		opc2.Product_Line__c = 'Intapp Walls';
		opc2.Product_LineNew__c = pl1.Id;
        
		insert opc1;
		insert opc2;

		Intapp_Settings__c settings = Intapp_Settings__c.getOrgDefaults();
		settings.Multiple_OPC_Check__c = true;
		settings.Multiple_OPC_Error_Message__c = 'Multiple OPC Validation';
		settings.Different_Product_Line_Check__c = true;
		settings.Different_Product_Line_Error__c = 'Same OPC Product Line Validation';

		upsert settings Intapp_Settings__c.Id;
	}

	static testMethod void TestCreateKeyAndMedia() {
		Opportunity o = [SELECT Id from Opportunity LIMIT 1];

		Opportunity_Product_Component__c opcTest = new Opportunity_Product_Component__c();

		// Execute the test
		Test.startTest();
			//Have 2 OPCs of same product line - Intapp Walls
			String OHresponse = OrderHeaderService.CreateKeyAndMedia(o.id, true);
			System.assertEquals('Same OPC Product Line Validation', OHresponse);
			
        	Product_Line__c plIntegrate = [Select Id from Product_Line__c where Name = 'Integrate'];
			//Change one OPC to Intapp Integrate
			for(Opportunity_Product_Component__c opc: [Select Id, Product_Line__c ,Product_LineNew__c from Opportunity_Product_Component__c where Opportunity__c = : o.id]){
				opc.Product_Line__c = 'Intapp Integrate';
				opc.Product_LineNew__c = plIntegrate.Id; 
                opcTest = opc;
				break;
			}

			update opcTest;

			OHresponse = OrderHeaderService.CreateKeyAndMedia(o.id, true);
			System.assertEquals('Multiple OPC Validation', OHresponse);
			
			//Ideal situation 1
			OHresponse = OrderHeaderService.CreateKeyAndMedia(opcTest.id, true);
			System.assertEquals('Key and Media Order Headers created.', OHresponse);

			//Ideal situation 2 - Remove one OPC and hve only one OPC on Oppt
			delete opcTest;
			OHresponse = OrderHeaderService.CreateKeyAndMedia(o.id, true);
			System.assertEquals('Key and Media Order Headers created.', OHresponse);

			//Remove Client Contact and verify validation
			o.Client_Contact__c = null;
			update o;
			OHresponse = OrderHeaderService.CreateKeyAndMedia(o.id, true);
			System.assertEquals('There was an error processing your request. Please verify that the related Opportunity has both a Client Contact and an OSA populated.', OHresponse);
		Test.stopTest();
		//Test end
	}
}