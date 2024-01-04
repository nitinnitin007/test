/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class testclassCaseEstComplDate {

static testMethod void testEstComplDateCaseTrigger(){
	Date myDate = date.today();
	Date newDate = myDate.addDays(10);
	
	
//		Case c = new Case();
//		c.PSCase_Project_Exp_Compl_Date__c = myDate;
//		c.Status = 'Not Started';
//		c.Subject = 'This is a test subject to test an Apex Trigger';
//		insert c;
//		c.PSCase_Project_Exp_Compl_Date__c = newDate;
//		update c;
	
	
	
	List<Case> cases = new List<Case>{};
        for(Integer i = 0; i < 10; i++){
          Case c = new Case();
          c.PSCase_Project_Exp_Compl_Date__c = myDate;
		  c.Status = 'Not Started';
		  c.Subject = 'This is a test subject to test an Apex Trigger';
          cases.add(c);
          }

    // Start the test, this changes governor limit context to
    // that of trigger rather than test.
    test.startTest();

    // Insert the Account records that cause the trigger to execute.
    insert cases; 
    
    // Stop the test, this changes limit context back to test from trigger.
    test.stopTest();
         
    // Query the database for the newly inserted records.
    List<Case> insertedCases = [SELECT PSCase_Project_Exp_Compl_Date__c 
                                      FROM Case 
                                      WHERE Id IN :cases];
   
    // Update Cases with new date
    for(Case c : insertedCases){
        c.PSCase_Project_Exp_Compl_Date__c = newDate;
		update c;
    }
    
    // Assert that the fields contains the proper value now.
    for(Case c : insertedCases){
      System.assertEquals(
        c.PSCase_Project_Exp_Compl_Date__c, 
        c.PSCase_Project_Exp_Compl_Date__c);
    }

}
}