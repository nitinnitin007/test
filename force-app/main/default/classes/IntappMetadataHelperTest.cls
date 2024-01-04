@isTest(SeeAllData = true)
private class IntappMetadataHelperTest {
	@isTest static void TestGetPicklistValues() {
		List<String> results = IntappMetadataHelper.GetPicklistValues('Contact', 'pse__Resource_Role__c');
		system.assert(results.size() > 0);
	}
	@isTest static void TestGetMultiPicklistValues() {
		List<String> results = IntappMetadataHelper.GetPicklistValues('Account', 'Intake__c');
		system.assert(results.size() > 0);
	}
}