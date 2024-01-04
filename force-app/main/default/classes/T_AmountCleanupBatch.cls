/**** @Name       : T_AmountCleanupBatch
***** @Created By  : KPMG
***** @Created On  : Nov 11th, 2023
***** @Description : Update Amount in temp tables removing extra characters
******/
//Cleanup Amount with symbol
//Database.executeBatch(new T_AmountCleanupBatch('CMLines'),200);
//Database.executeBatch(new T_AmountCleanupBatch('OrderProducts'),200);
//Database.executeBatch(new T_AmountCleanupBatch('Payment'),200);
//Database.executeBatch(new T_AmountCleanupBatch('InvoiceLines'),200);
public class T_AmountCleanupBatch  implements Database.Batchable<sObject>, Database.Stateful {
    //Database.executeBatch(new T_AmountCleanupBatch(),200);  
    // Start method to query the records you want to process.
    public string tempFileName;
    public T_AmountCleanupBatch(){}
    public T_AmountCleanupBatch(String fileName){
        this.tempFileName = fileName;
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
       if(this.tempFileName == 'CMLines'){
      	String queryCMLines = 'Select Id,Amount_Foreign_Currency__c,T_Amount_Without_Symbol__c from QtC_Mig_CreditMemoLines_Temp_Table__c ';  
        return Database.getQueryLocator(queryCMLines);
        } else if(this.tempFileName == 'OrderProducts'){
      	String queryOrderProducts = 'Select Id,Amount_Foreign_Currency_without_Symbol__c,T_Amount_Without_Symbol__c from QTC_Mig_OrderProducts__c';  
        return Database.getQueryLocator(queryOrderProducts);
        } else if(this.tempFileName == 'Payment'){
        String queryPay = 'Select Id,Amount_Foreign_Currency__c,T_Amount_Without_Symbol__c from QtC_Mig_Payments_Temp_Table__c';
        return Database.getQueryLocator(queryPay);
        } else if(this.tempFileName == 'InvoiceLines'){
      	String queryInvLines = 'Select Id,T_Amount__c,Amount_Foreign_Currency__c from QtC_Mig_Invoice_Lines_Temp_Table__c'; 
        return Database.getQueryLocator(queryInvLines);
        } else {
            return null;
        }
    }
    public void execute(Database.BatchableContext bc, List<sObject> records){
       amountCleanUp(records,this.tempFileName);
    }
    public static void amountCleanUp(List<sObject> records , String tempFileName){
        if(tempFileName == 'InvoiceLines'){
            List<QtC_Mig_Invoice_Lines_Temp_Table__c> recordList = (List<QtC_Mig_Invoice_Lines_Temp_Table__c>) records;
            invLinesMethod(recordList);     
            } 
        else if(tempFileName == 'OrderProducts'){
            List<QTC_Mig_OrderProducts__c> recordList = (List<QTC_Mig_OrderProducts__c>) records;
            ordProdMethod(recordList);
            }
        else if(tempFileName == 'CMLines' ){
            List<QtC_Mig_CreditMemoLines_Temp_Table__c> recordList = (List<QtC_Mig_CreditMemoLines_Temp_Table__c>) records;
            creditMemoLinesMethod(recordList);
            }
        else if(tempFileName == 'Payment'){
            List<QtC_Mig_Payments_Temp_Table__c> recordList = (List<QtC_Mig_Payments_Temp_Table__c>) records;
            paymentMethod(recordList);
            }
    }
     public static void invLinesMethod(List<QtC_Mig_Invoice_Lines_Temp_Table__c> records) {
        //List<String> specChars = {'($',')','(A','(','$A','€','�','NZ','Can'}; 
        List<QtC_Mig_Invoice_Lines_Temp_Table__c> invLinesToUpdate = new List<QtC_Mig_Invoice_Lines_Temp_Table__c>();
        for (QtC_Mig_Invoice_Lines_Temp_Table__c payRecord : records) {
            String amountWithoutOpenBrackets = payRecord.Amount_Foreign_Currency__c.contains('(') ? payRecord.Amount_Foreign_Currency__c.replace('(','-')
                : payRecord.Amount_Foreign_Currency__c;
            String amountWithoutOpenCloseBrackets = amountWithoutOpenBrackets.contains(')') ? amountWithoutOpenBrackets.replace(')','')
                : amountWithoutOpenBrackets;
            String amountWithoutocdBrackets = amountWithoutOpenCloseBrackets.contains('$') ? amountWithoutOpenCloseBrackets.replace('$','')
                :amountWithoutOpenCloseBrackets;
            String amountWithoutcan = amountWithoutocdBrackets.containsIgnoreCase('CAN') || amountWithoutocdBrackets.containsIgnoreCase('Can') ? amountWithoutocdBrackets.replace('CAN','').replace('Can','')
                : amountWithoutocdBrackets;
            String amountWithoutA =amountWithoutcan.containsIgnoreCase('A') ? amountWithoutcan.replace('A','').replace('a','')
                : amountWithoutcan;
            String amountWithoutE = amountWithoutA.contains('€') ? amountWithoutA.replace('€','')
                :amountWithoutA;
            String amountWithoutSpec = amountWithoutE.contains('�') ? amountWithoutE.replace('�','')
                    :amountWithoutE;
             String amountWithoutNZ =  amountWithoutSpec.containsIgnoreCase('NZ') ? amountWithoutSpec.replace('NZ','').replace('Nz','')
                  : amountWithoutSpec;
            String amountWithoutComma =  amountWithoutNZ.contains(',') ? amountWithoutNZ.replaceAll(',','')
                 :amountWithoutNZ;
            String amountWithoutSpace =  amountWithoutComma.contains(' ') ? amountWithoutComma.replaceAll(' ','')
                 :amountWithoutComma;
            //System.debug('amountWithoutSpace:'+amountWithoutSpace);
               Decimal pay = Decimal.valueOf(amountWithoutSpace.trim());
               payrecord.T_Amount__c = String.valueof(pay);
                invLinesToUpdate.add(Payrecord);
        }
        // Update the modified records
        if (! invLinesToUpdate.isEmpty()) {
            update invLinesToUpdate;
        }
    }
    
	 public static void ordProdMethod(List<QTC_Mig_OrderProducts__c> records) {
        //List<String> specChars = {'($',')','(A','(','$A','€','�','NZ','Can'}; 
        List<QTC_Mig_OrderProducts__c> ordProdToUpdate = new List<QTC_Mig_OrderProducts__c>();
        for (QTC_Mig_OrderProducts__c payRecord : records) {
            String amountWithoutOpenBrackets = payRecord.Amount_Foreign_Currency_without_Symbol__c.contains('(') ? payRecord.Amount_Foreign_Currency_without_Symbol__c.replace('(','-')
                : payRecord.Amount_Foreign_Currency_without_Symbol__c;
            String amountWithoutOpenCloseBrackets = amountWithoutOpenBrackets.contains(')') ? amountWithoutOpenBrackets.replace(')','')
                : amountWithoutOpenBrackets;
            String amountWithoutocdBrackets = amountWithoutOpenCloseBrackets.contains('$') ? amountWithoutOpenCloseBrackets.replace('$','')
                :amountWithoutOpenCloseBrackets;
            String amountWithoutcan = amountWithoutocdBrackets.containsIgnoreCase('CAN') || amountWithoutocdBrackets.containsIgnoreCase('Can') ? amountWithoutocdBrackets.replace('CAN','').replace('Can','')
                : amountWithoutocdBrackets;
            String amountWithoutA =amountWithoutcan.containsIgnoreCase('A') ? amountWithoutcan.replace('A','').replace('a','')
                : amountWithoutcan;
            String amountWithoutE = amountWithoutA.contains('€') ? amountWithoutA.replace('€','')
                :amountWithoutA;
            String amountWithoutSpec = amountWithoutE.contains('�') ? amountWithoutE.replace('�','')
                    :amountWithoutE;
             String amountWithoutNZ =  amountWithoutSpec.containsIgnoreCase('NZ') ? amountWithoutSpec.replace('NZ','').replace('Nz','')
                  : amountWithoutSpec;
            String amountWithoutComma =  amountWithoutNZ.contains(',') ? amountWithoutNZ.replaceAll(',','')
                 :amountWithoutNZ;
            String amountWithoutSpace =  amountWithoutComma.contains(' ') ? amountWithoutComma.replaceAll(' ','')
                 :amountWithoutComma;
            //System.debug('amountWithoutSpace:'+amountWithoutSpace);
               Decimal pay = Decimal.valueOf(amountWithoutSpace.trim());
               payrecord.T_Amount_Without_Symbol__c = String.valueof(pay);
                ordProdToUpdate.add(Payrecord);
         }
        // Update the modified records
        if (! ordProdToUpdate.isEmpty()) {
            update ordProdToUpdate;
        }
    } 
     public static void creditMemoLinesMethod(List<QtC_Mig_CreditMemoLines_Temp_Table__c> records) {
        //List<String> specChars = {'($',')','(A','(','$A','€','�','NZ','Can'}; 
        List<QtC_Mig_CreditMemoLines_Temp_Table__c> creditMemoLinesToUpdate = new List<QtC_Mig_CreditMemoLines_Temp_Table__c>();
        for (QtC_Mig_CreditMemoLines_Temp_Table__c payRecord : records) {
            String amountWithoutOpenBrackets = payRecord.Amount_Foreign_Currency__c.contains('(') ? payRecord.Amount_Foreign_Currency__c.replace('(','-')
                : payRecord.Amount_Foreign_Currency__c;
            String amountWithoutOpenCloseBrackets = amountWithoutOpenBrackets.contains(')') ? amountWithoutOpenBrackets.replace(')','')
                : amountWithoutOpenBrackets;
            String amountWithoutocdBrackets = amountWithoutOpenCloseBrackets.contains('$') ? amountWithoutOpenCloseBrackets.replace('$','')
                :amountWithoutOpenCloseBrackets;
            String amountWithoutcan = amountWithoutocdBrackets.containsIgnoreCase('CAN') || amountWithoutocdBrackets.containsIgnoreCase('Can') ? amountWithoutocdBrackets.replace('CAN','').replace('Can','')
                : amountWithoutocdBrackets;
            String amountWithoutA =amountWithoutcan.containsIgnoreCase('A') ? amountWithoutcan.replace('A','').replace('a','')
                : amountWithoutcan;
            String amountWithoutE = amountWithoutA.contains('€') ? amountWithoutA.replace('€','')
                :amountWithoutA;
            String amountWithoutSpec = amountWithoutE.contains('�') ? amountWithoutE.replace('�','')
                    :amountWithoutE;
             String amountWithoutNZ =  amountWithoutSpec.containsIgnoreCase('NZ') ? amountWithoutSpec.replace('NZ','').replace('Nz','')
                  : amountWithoutSpec;
            String amountWithoutComma =  amountWithoutNZ.contains(',') ? amountWithoutNZ.replaceAll(',','')
                 :amountWithoutNZ;
            String amountWithoutSpace =  amountWithoutComma.contains(' ') ? amountWithoutComma.replaceAll(' ','')
                 :amountWithoutComma;
            //System.debug('amountWithoutSpace:'+amountWithoutSpace);
               Decimal pay = Decimal.valueOf(amountWithoutSpace.trim());
               payrecord.T_Amount_Without_Symbol__c = pay;
                creditMemoLinesToUpdate.add(Payrecord);
        }
        // Update the modified records
        if (! creditMemoLinesToUpdate.isEmpty()) {
            update creditMemoLinesToUpdate;
        }
    }
//Payment Amount cleanup
     public static void paymentMethod(List<QtC_Mig_Payments_Temp_Table__c> records) {
        //List<String> specChars = {'($',')','(A','(','$A','€','�','NZ','Can'}; 
        List<QtC_Mig_Payments_Temp_Table__c> payToUpdate = new List<QtC_Mig_Payments_Temp_Table__c>();
        for (QtC_Mig_Payments_Temp_Table__c payRecord : records) {
            String amountWithoutOpenBrackets = payRecord.Amount_Foreign_Currency__c.contains('(') ? payRecord.Amount_Foreign_Currency__c.replace('(','-')
                : payRecord.Amount_Foreign_Currency__c;
            String amountWithoutOpenCloseBrackets = amountWithoutOpenBrackets.contains(')') ? amountWithoutOpenBrackets.replace(')','')
                : amountWithoutOpenBrackets;
            String amountWithoutocdBrackets = amountWithoutOpenCloseBrackets.contains('$') ? amountWithoutOpenCloseBrackets.replace('$','')
                :amountWithoutOpenCloseBrackets;
            String amountWithoutcan = amountWithoutocdBrackets.containsIgnoreCase('CAN') || amountWithoutocdBrackets.containsIgnoreCase('Can') ? amountWithoutocdBrackets.replace('CAN','').replace('Can','')
                : amountWithoutocdBrackets;
            String amountWithoutA =amountWithoutcan.containsIgnoreCase('A') ? amountWithoutcan.replace('A','').replace('a','')
                : amountWithoutcan;
            String amountWithoutE = amountWithoutA.contains('€') ? amountWithoutA.replace('€','')
                :amountWithoutA;
            String amountWithoutSpec = amountWithoutE.contains('�') ? amountWithoutE.replace('�','')
                    :amountWithoutE;
             String amountWithoutNZ =  amountWithoutSpec.containsIgnoreCase('NZ') ? amountWithoutSpec.replace('NZ','').replace('Nz','')
                  : amountWithoutSpec;
            String amountWithoutComma =  amountWithoutNZ.contains(',') ? amountWithoutNZ.replaceAll(',','')
                 :amountWithoutNZ;
            String amountWithoutSpace =  amountWithoutComma.contains(' ') ? amountWithoutComma.replaceAll(' ','')
                 :amountWithoutComma;
            System.debug('amountWithoutSpace:'+amountWithoutSpace);
               Decimal pay = Decimal.valueOf(amountWithoutSpace.trim());
               payrecord.T_Amount_Without_Symbol__c = pay;
                payToUpdate.add(Payrecord);
            
        }
        // Update the modified records
        if (! payToUpdate.isEmpty()) {
            update payToUpdate;
        }
    }
// Finish method to perform post-processing tasks.
     public void finish(Database.BatchableContext bc) {
        
    }
}