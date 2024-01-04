@IsTest(SeeAllData = true)
public with sharing class aptySalesforceControllerTest {
    @IsTest
    static void testLoginWithInvalidCredentials() {
        Map<String,List<SObject>> objects = aptySalesforceController.fetchUser();
        System.assertNotEquals(true, objects.isEmpty());
    }
}