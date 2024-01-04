/*********************************************************************************************************     
 *  Name             :  PSADashboardSchedulerTest
 *  Author           :  Anisha Dhekne
 *  Description      :  Test class for PSADashboardScheduler
 *
 *  Change history   :
 *  Date            Author                      Description
 *  05/10/2018      Anisha Dhekne               Created
 *********************************************************************************************************/
@isTest 
private class PSADashboardSchedulerTest {

	@isTest
	private static void testName() {
		List<Contact> list_con= new List<Contact> ();
	
		Contact con = (Contact) SmartFactory.createSObject('Contact');
		//con.Id = Id;
		//con.Name = 'testName';
		con.Send_PSA_Dashboard__c = true;
		con.Email = 'anisha.dhekne@example.com';
		con.pse__Salesforce_User__c = UserInfo.getUserId();
		insert con;

		String cronExpr = '0 0 0 15 3 ? 2022';
		test.startTest();
		//Batch_ActiveCampaignCountScheduler bca = new Batch_ActiveCampaignCountScheduler();
		String jobId =	System.schedule('PSADashboardScheduler', cronExpr, new PSADashboardScheduler());
		
		test.stopTest();
	}
}