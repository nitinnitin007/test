@isTest 
private class SyncQuoteLineItems_Test {

	@isTest
	private static void syncLineItems() {
		//***Creating records for testing***
		Account a = (Account) SmartFactory.createSObject('Account');
		a.Industry = 'Legal';
		insert a;

		Contract c = (Contract) SmartFactory.createSObject('Contract');
		c.AccountId = a.Id;
		insert c;

		Contact con = (Contact) SmartFactory.createSObject('Contact');
		insert con;

		Opportunity opp = (Opportunity) SmartFactory.createSObject('Opportunity');
		opp.AccountId = a.Id;
		opp.Associated_Contract_OSA__c = c.Id;
		opp.Contract_Signer__c = con.Id;
		insert opp;

		Id pricebookId = Test.getStandardPricebookId();

		Item_Master_Product__c imp = (Item_Master_Product__c) SmartFactory.createSObject('Item_Master_Product__c');
		insert imp;
		//Create your product
		Product2 prod = new Product2(
			 Name = 'Product X',
			 ProductCode = 'Pro-X',
			 isActive = true,
			 Product_License_Type__c = 'Annual',
			 Item_Master_Product__c = imp.Id
		);
		insert prod;

		//Create your pricebook entry
		PricebookEntry pbEntry = new PricebookEntry(
			 Pricebook2Id = pricebookId,
			 Product2Id = prod.Id,
			 UnitPrice = 100.00,
			 IsActive = true
		);
		insert pbEntry;


		//create your opportunity line item.  This assumes you already have an opportunity created, called opp
		OpportunityLineItem oli = new OpportunityLineItem(
			 OpportunityId = opp.Id,
			 Quantity = 5,
			 PricebookEntryId = pbEntry.Id,
			 Product2Id = prod.Id,
			 TotalPrice = 5 * pbEntry.UnitPrice,
			 OSA_Discount_Amount__c = 10
		);

		insert oli;
		//***Creating records for testing***

		SBQQ__Quote__c q = (SBQQ__Quote__c) SmartFactory.createSObject('SBQQ__Quote__c');
		q.Contract_Master_Terms__c = 'URL Terms';
		q.SBQQ__Opportunity2__c = opp.Id;
		q.SBQQ__Account__c = a.Id;
		insert q;

		Test.startTest();
		String msg = SyncQuoteLineItems.syncLineItems(q.Id);
		Test.stopTest();
	}
}