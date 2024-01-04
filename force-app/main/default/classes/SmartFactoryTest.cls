@isTest(SeeAllData = true)
private class SmartFactoryTest {
	@isTest static void TestSmartFactory() {
		List<SObject> objects = SmartFactory.createSObjectList('Account', false, 2);
		System.assertEquals(objects.size(), 2);
	}
}