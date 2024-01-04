@isTest(seeAllData=true)
private class TestOpportunityProductTrigger {

	static testMethod void testCreateOppCompRecord(){
		Account accId = TestUtil.createAccount(true);
		Opportunity opp = TestUtil.createOpportunity( accId.Id , true);
		
		Item_Master_Product__c master = TestUtil.createItemMaster(true);
		
		Pricebook2 p = new Pricebook2();
		p.Name = 'Test';
		p.CurrencyIsoCode = 'USD';
		insert p;
		
		ACV_Allocation__c acvLocation1 = TestUtil.createAcvAllocation(master.Id, 30 , true);
		ACV_Allocation__c acvLocation2 = TestUtil.createAcvAllocation(master.Id, 70 , true);
		
		Product2 pd = TestUtil.createProduct(false);
		pd.Item_Master_Product__c = master.Id;
		insert pd;
		
		PricebookEntry pbook = TestUtil.createPriceBookEntry(pd.Id, 10, true);
		OpportunityLineItem oppProduct = TestUtil.createOpportunityLineItem(opp.Id, pbook.Id , 10000, true);
		
	 // Integer total = new Integer([Select count(id) from Opportunity_Product_Component__c where Opportunity_Product_ID__c = :oppProduct.Id]);
		//system.assertEquals(2, total);
		
		oppProduct.UnitPrice = 15000;
		update oppProduct;
		
		delete oppProduct;
		//Test.startTest();
		//undelete oppProduct;
		//test.stopTest();
	}
}