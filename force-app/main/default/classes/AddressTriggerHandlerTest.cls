/**
 * @description       : This test class will cover AddressTriggerHandler class.
 * @author            : Pankaj Kumar
 * @last modified on  : 13-07-2023
 * @last modified by  : Pankaj Kumar
 * Modifications Log
 * Ver   Date         Author         Modification
 * 1.0   07-07-2023   Pankaj Kumar   Initial Version
**/
@isTest
public class AddressTriggerHandlerTest {
   
    /**
* ***********************************************************
* This method is test SetUp method for Address object
* ***********************************************************
*/
    @testSetup
    public static void setup(){
        List<Account> accList = TestDataFactory.createAccount(1,True);              
        List<Address__c> createAddress = TestDataFactory.createAddress(50,true,accList[0].Id);
        //List<User> createSalesUser = TestDataFactory.createSalesUser(1,false);
    }
/**
* ***********************************************************
* This method is test method for Billing Address Check
* ***********************************************************
*/
    @isTest
    public static void testBillingAddressCreation(){
        //User u = [Select id from User Limit 1];
        List<User> createSalesUser = TestDataFactory.createSalesUser(1,false);
        List<Account> accList = [Select Id,Name From Account Limit 1];
        List<Address__c> createAddress=[Select id,Default_Shipping_Address__c from Address__c limit 1];
        System.runAs(createSalesUser[0]){
            Test.startTest();
            List<Address__c> createBillingAddress = TestDataFactory.createBillingAddress(1,true,accList[0].Id);
            Test.stopTest();
            Address__c a =[Select id,Default_Billing_Address__c,Default_Shipping_Address__c from Address__c where id=:createAddress[0].id];
            System.assertEquals(false, a.Default_Billing_Address__c);
            System.assertNotEquals(false, a.Default_Shipping_Address__c);
       }
    }
/**
* ***********************************************************
* This method is test method for Shipping Address Check
* ***********************************************************
*/
    @isTest
    public static void testShippingAddressCreation(){
        //User u = [Select id from User Limit 1];
        List<User> createSalesUser = TestDataFactory.createSalesUser(1,false);
        List<Account> accList = [Select Id,Name From Account Limit 1];
        List<Address__c> createAddress = [Select id,Default_Shipping_Address__c from Address__c limit 1];
        System.runAs(createSalesUser[0]){
            Test.startTest();
            List<Address__c> createShippingAddress = TestDataFactory.createShippingAddress(1,true,accList[0].Id);
            Test.stopTest();
            Address__c a =[Select id,Default_Shipping_Address__c,Default_Billing_Address__c from Address__c where id=:createAddress[0].id];
            System.assertEquals(false, a.Default_Shipping_Address__c);
            System.assertNotEquals(false, a.Default_Billing_Address__c);
       }
    }
}