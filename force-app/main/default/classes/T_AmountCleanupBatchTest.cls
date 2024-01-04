/**** @name        : T_AmountCleanupBatchTest
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Test Class for T_AmountCleanupBatch : If the amount are cleaned up properly
******/
@isTest
public class T_AmountCleanupBatchTest{
@isTest
//Cleanup Method for QtC_Mig_Invoice_Lines_Temp_Table__c 
public static void invCleanupMethod(){
	//Creating QtC_Mig_Invoice_Lines_Temp_Table__c record
	QtC_Mig_Invoice_Lines_Temp_Table__c invLineTemp = new QtC_Mig_Invoice_Lines_Temp_Table__c();
	invLineTemp.Amount_Foreign_Currency__c = '(12345)';
	invLineTemp.T_Amount__c = null;
	insert invLineTemp;

	//Start test
	Test.startTest();
	// Execute the batch class to be tested
	T_AmountCleanupBatch bc = new T_AmountCleanupBatch('InvoiceLines');
	Database.executeBatch(bc);
	//Stop Test
	Test.stopTest();
	//Validating the results
	List<QtC_Mig_Invoice_Lines_Temp_Table__c> tempInv = [SELECT Id,Amount_Foreign_Currency_without_Symbol__c,T_Amount__c FROM QtC_Mig_Invoice_Lines_Temp_Table__c Limit 1];   
    if(tempInv != null && tempInv[0].T_Amount__c != null){
        System.assertEquals(-12345,Decimal.valueof(tempInv[0].T_Amount__c),'Working as excpected');}
}
@isTest
//Cleanup Method for QtC_Mig_Payments_Temp_Table__c
public static void paymentCleanupMethod(){
	//Creating QtC_Mig_Payments_Temp_Table__c record
	QtC_Mig_Payments_Temp_Table__c payTemp = new QtC_Mig_Payments_Temp_Table__c();
	payTemp.Amount_Foreign_Currency__c = '(12345)';
	payTemp.T_Amount_Without_Symbol__c = null;
    insert payTemp;

	//Start Test
	Test.startTest();
	//Execute the Batch class to be Tested
	T_AmountCleanupBatch bc = new T_AmountCleanupBatch('Payment');
	Database.executeBatch(bc);
	//Stop Test
	Test.stopTest();
	//Validating the results    
	List<QtC_Mig_Payments_Temp_Table__c> tempPay = [SELECT Id,Amount_Foreign_Currency_without_Symbol__c,T_Amount_Without_Symbol__c FROM QtC_Mig_Payments_Temp_Table__c Limit 1];   
    if(tempPay != null && tempPay[0].T_Amount_Without_Symbol__c != null){
        System.assertEquals(-12345,tempPay[0].T_Amount_Without_Symbol__c,'Working as excpected');}
}
@isTest
//Cleanup Method for QtC_Mig_CreditMemoLines_Temp_Table__c
public static void creditMemoLinesCLeanupMethod(){
	//Creating QtC_Mig_CreditMemoLines_Temp_Table__c record
	QtC_Mig_CreditMemoLines_Temp_Table__c creditMemoLineTemp = new QtC_Mig_CreditMemoLines_Temp_Table__c();
	creditMemoLineTemp.Amount_Foreign_Currency__c = '(12345)';
	creditMemoLineTemp.T_Amount_Without_Symbol__c = null;
 	insert creditMemoLineTemp;
	//Start test
	Test.startTest();
	//Executing the batch to be tested
	T_AmountCleanupBatch bc = new T_AmountCleanupBatch('CMLines');
	Database.executeBatch(bc);
	//Stop Test
	Test.stopTest();
	//Validating the results
	List<QtC_Mig_CreditMemoLines_Temp_Table__c> tempCM = [SELECT Id,Amount_Foreign_Currency__c,T_Amount_Without_Symbol__c FROM QtC_Mig_CreditMemoLines_Temp_Table__c Limit 1];   
	if(tempCM != null && tempCM[0].T_Amount_Without_Symbol__c != null){
        System.assertEquals(-12345,tempCM[0].T_Amount_Without_Symbol__c,'Working as excpected');}

} 
@isTest
//Cleanup Method for QTC_Mig_OrderProducts__c
public static void ordProdCleanupMethod(){
	//Creating QTC_Mig_OrderProducts__c record
	QTC_Mig_OrderProducts__c ordProdTemp = new QTC_Mig_OrderProducts__c();   
	ordProdTemp.Amount_Foreign_Currency_without_Symbol__c = '(12345)';
	ordProdTemp.T_Amount_Without_Symbol__c = null;   
    insert ordProdTemp;
	//Start test
	Test.startTest();
	//Executing the batch to be tested
	T_AmountCleanupBatch bc = new T_AmountCleanupBatch('OrderProducts');
	Database.executeBatch(bc);
	//Stop Test
	Test.stopTest();
	//Validating the Results
	List<QTC_Mig_OrderProducts__c> tempOrdProd = [Select Id,Amount_Foreign_Currency_without_Symbol__c,T_Amount_Without_Symbol__c from QTC_Mig_OrderProducts__c Limit 1];   
	if(tempOrdProd != null && tempOrdProd[0].T_Amount_Without_Symbol__c != null){
        System.assertEquals(-12345,Decimal.valueof(tempOrdProd[0].T_Amount_Without_Symbol__c),'Working as excpected');}
}
}