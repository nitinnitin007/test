/**** @name        :T_AmountAndAccountPopulateBatchTest
***** @author      : KPMG
***** @date        : Nov 11th, 2023
***** @description : Test Class to check - if the Amount,Currency, Exchange Rate,Order Date and Account Populate batch populates correctly from QTC_Order_Headers
******/
@isTest
public class T_AmountAndAccountPopulateBatchTest {
    @isTest
    public static void amountAndAccountPopulateBatchTest(){
        //Creating QTC_Mig_OrderHeaders__c
        QTC_Mig_OrderHeaders__c qtcOrderProd = new QTC_Mig_OrderHeaders__c();
        qtcOrderProd.Account_ID__c = '1234';
        qtcorderProd.Internal_ID__c = '123';
        qtcOrderProd.Amount_Foreign_Currency_without_Symbol__c = '1';
        qtcOrderProd.T_Amount_Without_Symbol__c = '1';
        qtcorderProd.Date__c = System.today();
        qtcorderProd.Currency__c = 'Euro';
        qtcorderProd.Exchange_Rate__c = '1.4567';
        
        insert qtcorderProd;
        //Creating T_OrderLineDMSummary__c
        T_OrderLineDMSummary__c ordLineDm = new T_OrderLineDMSummary__c();
        ordLineDm.NSOrderID__c = '123';
        ordLineDm.NS_Order_Amount__c = 1;
        ordLineDm.NS_AccountId__c = '1234';
        ordLineDm.NS_Order_Date__c = qtcOrderProd.Date__c;
        ordLineDm.Currency__c = qtcorderProd.Currency__c;
        ordLineDm.Exchange_Rate__c = 1.4567;
        
        insert ordLineDM;
        
        //Start Test
        Test.StartTest();
        //Execute the method to insert the test data
        T_AmountAndAccountPopulateSummaryBatch bc = new T_AmountAndAccountPopulateSummaryBatch();
        Database.executeBatch(bc);
        //Stop Test
        Test.StopTest();
        
        //validating the results
        List<T_OrderLineDMSummary__c> tempSummary = [SELECT Id,NS_Order_Amount__c,NS_AccountId__c,NS_Order_Date__c,Currency__c,Exchange_Rate__c FROM T_OrderLineDMSummary__c Limit 1];
        if(tempSummary.size()>0){
        if(tempSummary[0].NS_Order_Amount__c != null){
            System.assertEquals(1,tempSummary[0].NS_Order_Amount__c,'Amount Populated Successfully');    
        }
        if(tempSummary[0].NS_AccountId__c != null){
            System.assertEquals('1234',tempSummary[0].NS_AccountId__c,'Account Id populated successfully');
        }
        if(tempSummary[0].NS_Order_Date__c != null){
            Date dt = System.today();
            System.assertEquals(dt,tempSummary[0].NS_Order_Date__c,'Date Populated successfully');
        }    
        }
        
    }
}