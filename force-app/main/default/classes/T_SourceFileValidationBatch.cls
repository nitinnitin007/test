/**** @Name :T_SourceFileValidationBatch
***** @Created By : KPMG
***** @Created On : Nov 11th, 2023
***** @Description : Updates the Reason of bad data in the Temp tables with the missing field Name
******/
public class T_SourceFileValidationBatch implements Database.Batchable<sObject>,Database.Stateful {
    // Database.executeBatch(new T_SourceFileValidationBatch(),200);
    // Database.executeBatch(new T_SourceFileValidationBatch('QTC_Mig_OrderProducts__c'),200);
    // Database.executeBatch(new T_SourceFileValidationBatch('QtC_Mig_Invoice_Temp_Table__c'),200);
    // Database.executeBatch(new T_SourceFileValidationBatch('QtC_Mig_Invoice_Lines_Temp_Table__c'),200);
    // Database.executeBatch(new T_SourceFileValidationBatch('T_OrderLineDMSummary__c'),200);
    // Database.executeBatch(new T_SourceFileValidationBatch('QTC_Mig_OrderHeaders__c'),200);
    // QtC_Mig_Payments_Temp_Table__c,QtC_Mig_PaymentAlloc_Temp_Table__c,QtC_Mig_CreditMemo_Temp_Table__c
    // QtC_Mig_CreditMemoLines_Temp_Table__c,QtC_Mig_CreditMemoLines_Alloc_Temp_Table__c
    public T_SourceFileValidationBatch(){}
    public string tempFileName;
    public Map<String,DataMigration__mdt> metaDataMap = DataMigration__mdt.getAll();
    // Stores the name of the temporary file
    public String fieldsApi;
    public T_SourceFileValidationBatch(String fileName){
        this.tempFileName = fileName;
    }
    public Database.queryLocator start(Database.BatchableContext bc){
        for(String keySetString : metaDataMap.keySet()){
            //system.debug('keySetString---->'+keySetString);
            //system.debug('ObjectApiName---->'+metaDataMap.get(keySetString).ObjectApiName__c);
            if(tempFileName == metaDataMap.get(keySetString).ObjectApiName__c){
                fieldsApi = metaDataMap.get(keySetString).Fields__c; 
                break;
            }
        }
        //Dynamic SOQL query using the retrieved field API names and the provided tempFileName.
        String query = 'SELECT ID, ' + fieldsApi + ',Reason_for_Bad_Data__c FROM '+ tempFileName ;
        //System.debug('Query:'+query);
        if(query == Null){
            return null;
        } else{
            return Database.getQueryLocator(query);
        }
    }
    public void execute(Database.BatchableContext bc,List<sObject> sourceRecords)
    {
        updateReasons(sourceRecords,fieldsApi,tempFileName);
    }
    public static void updateReasons(List<sObject> sourceRecords,String fieldsApi,String tempFileName)
    {
        //Updates the "Reason_for_Bad_Data__c" field with information about missing fields
        Map<sObject,String> updateReasonMap = new Map<sObject,String>();
        List<String> fieldsApiNames = fieldsApi.split(',');
        //sObject objectType = (sObject)(Type.forName('Schema.'+ tempFileName).newInstance());
        for(sObject objectWithoutType : sourceRecords)
        {
            for(String fieldApiName : fieldsApiNames)
            {
                if(objectWithoutType.get(fieldApiName) == null)
                {	
                    //system.debug('fieldAPIName Value----->'+objectWithoutType.get(fieldApiName));
                    //system.debug('Reason for bad data field----->'+objectWithoutType.get('Reason_for_Bad_Data__c'));
                    if(updateReasonMap.containsKey(objectWithoutType))
                    {
                        String tempBadReason = updateReasonMap.get(objectWithoutType) +','+ fieldApiName + ' does not exist ';
                        updateReasonMap.put(objectWithoutType,tempBadReason);
                        //system.debug('updateReasonMap---->'+updateReasonMap.get(objectWithoutType)); 
                    }
                	else
                    {
                    String tempBadReason = fieldApiName + ' does not exist ';
                    updateReasonMap.put(objectWithoutType,tempBadReason);
                 }
            }
        }
        }
        List<sObject> tempList = new List<sObject>();
        if(updateReasonMap.size() > 0)
        {
            for(sObject tempUpdate : updateReasonMap.Keyset())
            {
                tempUpdate.put('Reason_for_Bad_Data__c',  updateReasonMap.get(tempUpdate));
                tempList.add(tempUpdate);  
            }
        }
        if(tempList.size()>0){
            update tempList;    
        }
    }
    /*public static void updateQTCMigOrdProd(List<QTC_Mig_OrderProducts__c> migOrdProd,String fieldsApi,string tempFileName)
    {
        List<String> tempFieldApis = fieldsApi.split(',');
        Set<QTC_Mig_OrderProducts__c> recordsToUpdate = new Set<QTC_Mig_OrderProducts__c>();
        for(QTC_Mig_OrderProducts__c tempOrdProd :migOrdProd ){
            for(Integer j=0;j<tempFieldApis.size();j++){
                if(tempOrdProd.get(tempFieldApis[j]) == Null){
                    if(tempOrdProd.Reason_for_Bad_Data__c != Null){
                        tempOrdProd.Reason_for_Bad_Data__c = tempOrdProd.Reason_for_Bad_Data__c +' , '+ tempFieldApis[j] + ' does not Exist';
                        system.debug('Reason for Bad data '+tempOrdProd);
                        recordsToUpdate.add(tempOrdProd);
                    }
                    else
                    {
                        tempOrdProd.Reason_for_Bad_Data__c =  tempFieldApis[j] + ' does not Exist';
                        system.debug('Reason for Bad data '+tempOrdProd);
                        recordsToUpdate.add(tempOrdProd);
                    }
                }
            }
        }
        List<QTC_Mig_OrderProducts__c> temprec = new List<QTC_Mig_OrderProducts__c>();
        for(QTC_Mig_OrderProducts__c temp :recordsToUpdate ){
            temprec.add(temp);
        }
        if(temprec.size()>0){
            update temprec;
            system.debug('recordsToUpdate---->'+temprec);
        }
    }*/
    //Finish Method
    public void finish(Database.BatchableContext bc){
        system.debug('the batch process finishes');
    }
    
}