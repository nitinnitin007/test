/********************************************************************************     
 *  Name             :  OpportunityQuoteMigrationBatch
 *  Author           :  Snehal Choudhary
 *  Description      :  Test Class for OpportunityQuoteMigrationBatch
 *                   
 *  Change history   :
 *  Date               Author             Description
 *  02/11/2023    Snehal Choudhary          Created
 ********************************************************************************/

@isTest
private class OpportunityQuoteMigrationBatchTest {
  @isTest 
  private static void TestMethod1() {
   List<Contract> listOfContracts = [Select Id,Migration_Status__c FROM Contract WHERE Migration_Status__c = 'Ready' LIMIT 1];
   Database.BatchableContext bc ;
   OpportunityQuoteMigrationBatch oppQuoteObj = new OpportunityQuoteMigrationBatch();
   oppQuoteObj.start(bc);  
 //  oppQuoteObj.execute(bc,listOfContracts);   
   oppQuoteObj.finish(bc);   
  }
}