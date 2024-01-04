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
private class textclassCaseSurveyContact {

    static testMethod void myUnitTest() {
	// Test contact # C121033 / David Michel (Burr Forman):  0035000000h30Op
	String tempContact1 = '0035000000h30Op';
	// Test Owner Mark Burgard:  005500000016Ees
	String tempOwner = '005500000016Ees';    
		
	List<Case> cases = new List<Case>{};
        for(Integer i = 0; i < 10; i++){
        Case c = new Case();
        c.Survey_ContactID__c = tempContact1;
        c.Status = 'Not Started';
		c.Subject = 'This is a test subject to test an Apex Trigger';
		c.OwnerID = tempOwner;
        cases.add(c);
    	}

    // Start the test, this changes governor limit context to
    // that of trigger rather than test.
    test.startTest();

    // Insert the Account records that cause the trigger to execute.
    insert cases; 
    
    // Stop the test, this changes limit context back to test from trigger.
    test.stopTest();
    }
}