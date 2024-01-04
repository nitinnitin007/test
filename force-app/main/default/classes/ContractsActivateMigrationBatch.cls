global class ContractsActivateMigrationBatch implements Database.Batchable<sObject> {
    List<string> lstOfContractAssignment;
    global ContractsActivateMigrationBatch() {}

    global ContractsActivateMigrationBatch(List<string> lstOfContractNumbers){
        lstOfContractAssignment = lstOfContractNumbers ;
    }

    global Database.QueryLocator start(Database.BatchableContext bc){
        string endCondition;
        if (lstOfContractAssignment != null && !lstOfContractAssignment.isempty()) {
            for (string endDigit : lstOfContractAssignment) {
                endCondition = endCondition != null? (endCondition +  ' OR ContractNumber like \'%' + endDigit + '\'') :' ContractNumber like \'%' + endDigit + '\'';
            }
        } 
        String query = 'SELECT Id,Processing_Status__c FROM Contract WHERE Processing_Status__c = \'Contract Created\'';
        query = endCondition != null? query + ' AND (' + endCondition + ')' : query;
        system.debug('Start Query' +query);   
        return Database.getQueryLocator(query);        
    }
    
    global void execute(Database.BatchableContext bc, List<Contract> lstOfContracts){
        set<id> setOfOrderIds = new set<id>();
        List<OP4I_Entitlement_View__c> lstOfEntitlementRecords = new List<OP4I_Entitlement_View__c>();
        Map<String,Contract> mapOfOrderToContractRecord = new Map<String,Contract>();
        Map<String,OP4I_Entitlement_View__c> mapOfOrderToEntitlement = new Map<String,OP4I_Entitlement_View__c>();
        set<id> setOfOrderUpd = new set<id>();
        List<Contract> updatedContracts = new List<Contract>();
        List<Contract> listOfExistingContracts = new List<Contract>();
        if(!lstOfContracts.IsEmpty())
        {
            lstOfEntitlementRecords = [SELECT Id,DLIP_Id__c,Account__c,Quote__c,Quote__r.SBQQ__Ordered__c,Order__c,Order__r.status,Order__r.SBQQ__Contracted__c,Quantity__c
                                     ,Start_Date__c,End_Date__c,Associated_OSA__c,Account__r.Name,Associated_OSA__r.ContractNumber,Opportunity__c,Processing_Status__c
                                     ,Associated_OSA__r.additional_Requester_email__c,Associated_OSA__r.PO_Number__c,Associated_OSA__r.Active__c
                                     ,Associated_OSA__r.Amendment_Expiration__c,Associated_OSA__r.Appliance_1_ID__c,Associated_OSA__r.Appliance_2_ID__c,Associated_OSA__r.Appliance_Model_2__c
                                     ,Associated_OSA__r.Appliance_Model_1__c,Associated_OSA__r.Appliance_Ship_Date_Appliance_2_opt__c,Associated_OSA__r.Status
                                     ,Associated_OSA__r.Appliance_Ship_Date__c,Associated_OSA__r.Approval_Request_Notes__c,Associated_OSA__r.Approver_1__c
                                     ,Associated_OSA__r.Approver_2__c,Associated_OSA__r.Approver_3__c,Associated_OSA__r.Approver_4__c,Associated_OSA__r.Approver_5__c,Associated_OSA__r.Approver_6__c
                                     ,Associated_OSA__r.Audited_for_Supersession__c,Associated_OSA__r.Billed_Under__c,Associated_OSA__r.Billing_Account__c
                                     ,Associated_OSA__r.Billing_Pause_Expiration__c,Associated_OSA__r.Billing_Pause_Owner__c,Associated_OSA__r.Billing_Pause_Status__c,Associated_OSA__r.Cancellation_fee__c
                                     ,Associated_OSA__r.Client_Confidentiality_Agreement2__c,Associated_OSA__r.Client_Onboarding_Status__c,Associated_OSA__r.Co_Marketing_Agreement_2__c
                                     ,Associated_OSA__r.Confidentiality_Svcs_Data_Sheet__c,Associated_OSA__r.Contingency_Deadline__c,Associated_OSA__r.Contingency__c
                                     ,Associated_OSA__r.Contingency_Type__c,Associated_OSA__r.Contracted_Amendment_Date__c,Associated_OSA__r.Contract_Recipient__c,Associated_OSA__r.Contract_Uploaded__c
                                     ,Associated_OSA__r.Current_Invoice_Due_Date__c,Associated_OSA__r.Customer_Form_Received__c,Associated_OSA__r.Custom_Terms__c,Associated_OSA__r.Date_Invoice_Sent__c
                                     ,Associated_OSA__r.DCP_Contract_Number__c,Associated_OSA__r.Deal_Cloud_Id__c,Associated_OSA__r.Deferral__c,Associated_OSA__r.Discount_Approved__c
                                     ,Associated_OSA__r.Discount_Calculated__c,Associated_OSA__r.Discount_Justified__c,Associated_OSA__r.Early_Payment_Incentive__c,Associated_OSA__r.Early_Payment_Notes__c
                                     ,Associated_OSA__r.Enterprise_Development__c,Associated_OSA__r.Enterprise_Production__c,Associated_OSA__r.Entitled_to_Permanent_License__c,Associated_OSA__r.Escrow_Agreement__c
                                     ,Associated_OSA__r.Escrow_Commitments__c,Associated_OSA__r.Exception_Approval__c,Associated_OSA__r.Exception_Approver_1__c,Associated_OSA__r.Exception_Approver_2__c
                                     ,Associated_OSA__r.Exception_Approver_3__c,Associated_OSA__r.Exception_Approver_4__c,Associated_OSA__r.Exception_Approver_5__c,Associated_OSA__r.Exception_Approver_6__c
                                     ,Associated_OSA__r.External_Notification_Sent__c,Associated_OSA__r.Future_Lawyer_FE_Uplift_Commitments__c,Associated_OSA__r.Includes_modification_to_contract_term__c
                                     ,Associated_OSA__r.Includes_multi_year_term_for_on_perm__c,Associated_OSA__r.Includes_platform_deployment_conversion__c,Associated_OSA__r.Includes_Termination_Clause__c
                                     ,Associated_OSA__r.Initial_Software_Term_Length__c,Associated_OSA__r.Initial_Term_End_Date__c,Associated_OSA__r.Installation_Setup_Project__c
                                     ,Associated_OSA__r.Tsunami_Appliance_Terms2__c,Associated_OSA__r.Wall_Builder_Terms__c,Associated_OSA__r.Invoice_Type__c,Associated_OSA__r.Law_Firm_Confidentiality_Mgmt_Overview__c
                                     ,Associated_OSA__r.Legacy_DCP_Billing_Account__c,Associated_OSA__r.Liability__c,Associated_OSA__r.Liability_Confidentiality_Exception__c
                                     ,Associated_OSA__r.Liability_Notes__c,Associated_OSA__r.Applicable_Subsidiary__c,Associated_OSA__r.Manual_OSA_Indicator__c
                                     ,Associated_OSA__r.Multi_Product_Deal__c,Associated_OSA__r.Network_Configuration_Datasheet__c,Associated_OSA__r.Non_cancelable_Multiyear_Agreements__c,Associated_OSA__r.Non_standard_Cloud_Data_Location__c
                                     ,Associated_OSA__r.Non_standard_Cloud_Data_Location_Detail__c,Associated_OSA__r.Non_Standard_Cloud_Location__c,Associated_OSA__r.Notes__c
                                     ,Associated_OSA__r.Number_of_users__c,Associated_OSA__r.OP4I_Contract_Id__c,Associated_OSA__r.OP4I_Deal_Owner__c,Associated_OSA__r.Opportunity_Engagement_Summary2__c
                                     ,Associated_OSA__r.Order_and_Sale_Agreement2__c,Associated_OSA__r.OSA_Customer_Name__c,Deal_Type__c
                                     ,Associated_OSA__r.OSA_Type__c,Associated_OSA__r.Contract__c,Associated_OSA__r.Parent_Contract__c
                                     ,Associated_OSA__r.Consulting_Dollars_non_Tsunami__c,Associated_OSA__r.Partner_Consulting_Hours__c,Associated_OSA__r.Partner_Consulting_Sale_Agreement2__c
                                     ,Associated_OSA__r.Payment_Processor__c,Associated_OSA__r.Payment_Received__c,Associated_OSA__r.Payment_Status__c,Associated_OSA__r.Payment_Terms_Services__c
                                     ,Associated_OSA__r.Payment_Terms_Software__c,Associated_OSA__r.Pending_Amendment_Date__c,Associated_OSA__r.Price_book_exception__c,Associated_OSA__r.Additional_Data_Sources__c
                                     ,Associated_OSA__r.Proposal__c,Associated_OSA__r.Recipient__c,Associated_OSA__r.Recipient_s_Title__c,Associated_OSA__r.Recipient_Phone__c,Associated_OSA__r.Recipient_Title__c
                                     ,Associated_OSA__r.Recurring_Adjustment_Renewal__c,Associated_OSA__r.Reference_Program__c,Associated_OSA__r.Replace_existing_agreement__c
                                     ,Associated_OSA__r.Change_Requestor__c,Associated_OSA__r.Requester_2__c,Associated_OSA__r.Retainer_percentage__c,Associated_OSA__r.Retainer__c
                                     ,Associated_OSA__r.Right_of_Return__c,Associated_OSA__r.Risk_Management_Program__c,Associated_OSA__r.ROR__c
                                     ,Associated_OSA__r.ROR_Expiration_Date__c,Associated_OSA__r.Send_Notification__c,Associated_OSA__r.Services_Expiration__c
                                     ,Associated_OSA__r.Services_Expiration_Amendment__c,Associated_OSA__r.Services_Expiration_Amendment_Status__c
                                     ,Associated_OSA__r.Services_Expiration_Duration__c,Associated_OSA__r.Services_Payment_Terms__c,Associated_OSA__r.Services_Request_link__c
                                     ,Associated_OSA__r.CPI__c,Associated_OSA__r.CPI_Other__c,Associated_OSA__r.Shipper_Tracking_Number_Appliance_2__c,Associated_OSA__r.Shipper_Tracking_Number__c
                                     ,Associated_OSA__r.Shipping_Address__c,Associated_OSA__r.Shipping_Company_Appliance_2_opt__c,Associated_OSA__r.Shipping_Company__c
                                     ,Associated_OSA__r.Shipping_Status__c,Associated_OSA__r.Software_Billing_Frequency_1st_Year__c,Associated_OSA__r.OSA_Number__c
                                     ,Associated_OSA__r.Software_Days_Payment_Due_Renewal__c,Associated_OSA__r.SOW__c,Associated_OSA__r.Special_Financing_Terms__c
                                     ,Associated_OSA__r.Standard_Development__c,Associated_OSA__r.Standard_Production__c,Associated_OSA__r.Subsidiary__c
                                     ,Associated_OSA__r.Superseded_by_OSA__c,Associated_OSA__r.Superseded_by_OSA_2__c,Associated_OSA__r.Superseded_by_OSA_3__c,Associated_OSA__r.Superseded_by_OSA_4__c
                                     ,Associated_OSA__r.Superseded_by_OSA_5__c,Associated_OSA__r.Support_SLA__c,Associated_OSA__r.Support_Stream__c,Associated_OSA__r.Time_Builder_Terms__c
                                     ,Associated_OSA__r.Total_Contract_Value__c,Associated_OSA__r.Type__c,Associated_OSA__r.Vera_s_Email_Address__c,Associated_OSA__r.Migration_Status__c,Associated_OSA__r.Processing_Status__c
                                     ,Associated_OSA__r.VPN_Access_Limitation_Type__c,Associated_OSA__r.Warranty__c FROM OP4I_Entitlement_View__c 
                                     WHERE Associated_OSA__c IN: lstOfContracts];
                                     
                                     
         if(!lstOfEntitlementRecords.IsEmpty()){ 
              for(OP4I_Entitlement_View__c entitlemnt : lstOfEntitlementRecords)
              {
                setOfOrderIds.add(entitlemnt.Order__c); 
                mapOfOrderToContractRecord.put(entitlemnt.Order__c ,entitlemnt.Associated_OSA__r);
                
                if(!mapOfOrderToEntitlement.containskey(entitlemnt.Order__c))
                {
                  mapOfOrderToEntitlement.put(entitlemnt.Order__c ,entitlemnt); 
                }            
              }
            }                            
                                     
        List<Contract> existingContracts = [Select Id,SBQQ__Quote__c,Active__c,ContractNumber,Old_Contract_Reference__c,Old_Contract_Reference__r.ContractNumber,Contract_Number_Display__c,status,SBQQ__Order__c,Deal_Type__c,Subsidiary__c FROM Contract WHERE SBQQ__Order__c IN: setOfOrderIds];
                
        for(Contract contractObj : existingContracts)
        {
            if(contractObj.Active__c == false)
            contractObj.status = 'In Force';
            if(mapOfOrderToContractRecord.containsKey(contractObj.SBQQ__Order__c))
            {
                Contract existingContract = mapOfOrderToContractRecord.get(contractObj.SBQQ__Order__c);
                setContractFields1(contractObj,existingContract,mapOfOrderToEntitlement);
                setContractFields2(contractObj,existingContract);
                setContractFields3(contractObj,existingContract);
                contractObj.Old_Contract_Reference__c = existingContract.id;
                contractObj.Contract_Number_Display__c = existingContract.ContractNumber;
                setOfOrderUpd.add(contractObj.SBQQ__Order__c);
                existingContract.status = 'Closed Migrated';
                listOfExistingContracts.add(existingContract);
            }
            else
            {
                contractObj.Contract_Number_Display__c = contractObj.ContractNumber;    
            }
            updatedContracts.add(contractObj);          
        }
        if(!updatedContracts.IsEmpty())
        {
            updateContract(updatedContracts,lstOfEntitlementRecords,setOfOrderUpd);
            
        }
        if(!listOfExistingContracts.IsEmpty())
        {
          Database.SaveResult[] listOfExistingContractsToUpdate = Database.update(listOfExistingContracts, false);
          HandleCustomException.logDatabaseErrors(listOfExistingContractsToUpdate);
        }
      } 
    }
    
     global void finish(Database.BatchableContext bc){
        
    }
    
     global static void updateContract(List<Contract> updatedContracts,List<OP4I_Entitlement_View__c> lstOfEntitlementRecords,set<id> setOfOrderUpd){
        Database.SaveResult[] contractUpdateResult = Database.update(updatedContracts, false);
        //HandleCustomException.logDatabaseErrors(listOfContracts); 
        map<string,string> resultMap = HandleCustomException.logMigrationDatabaseError(
            contractUpdateResult,
            new Map<string,OP4I_Entitlement_View__c>(),
            'SBQQ__Order__c',
            updatedContracts
        ); 
        List<Contract> lstOfOldContractsToUpdate = new List<Contract>();
        List<OP4I_Entitlement_View__c> lstOfEntitlementRecordsUpd = new List<OP4I_Entitlement_View__c>();
        string keyFields = 'Order__c';
        for(OP4I_Entitlement_View__c entitlemnt : lstOfEntitlementRecords) {
            if(setOfOrderUpd.contains(entitlemnt.Order__c)) {
                string key = HandleCustomException.getKey(keyFields, entitlemnt);
                if (resultMap.containsKey(key)) {
                    entitlemnt.Processing_Status__c = 'Contract activation Failed';
                    entitlemnt.Error_Log__c = resultMap.get(key);
                    entitlemnt.Associated_OSA__r.Processing_Status__c = 'Contract activation Failed';
                } else {
                    entitlemnt.Processing_Status__c = 'Contract Activated'; 
                    entitlemnt.Associated_OSA__r.Processing_Status__c = 'Contract Activated';
                    entitlemnt.Migration_Status__c  = 'Migrated';
                    entitlemnt.Associated_OSA__r.Migration_Status__c = 'Migrated';
                }
                lstOfEntitlementRecordsUpd.add(entitlemnt);
                if(!lstOfOldContractsToUpdate.contains(entitlemnt.Associated_OSA__r)){
                    lstOfOldContractsToUpdate.add(entitlemnt.Associated_OSA__r);
                }
            }               
        }
        Database.SaveResult[] listOfEntitlements = Database.update(lstOfEntitlementRecordsUpd, false);
        HandleCustomException.logDatabaseErrors(listOfEntitlements); 
 
        Database.SaveResult[] listOfContractsToUpdate = Database.update(lstOfOldContractsToUpdate, false);
        HandleCustomException.logDatabaseErrors(listOfContractsToUpdate);  
    }
    
    global static void setContractFields1(Contract contractObj , Contract existingContract , Map<String,OP4I_Entitlement_View__c> mapOfOrderToEntitlement){
        contractObj.PO_Number__c = existingContract.PO_Number__c;  
        contractObj.additional_Requester_email__c = existingContract.additional_Requester_email__c;
        contractObj.Amendment_Expiration__c = existingContract.Amendment_Expiration__c;
        contractObj.Appliance_1_ID__c = existingContract.Appliance_1_ID__c;
        contractObj.Appliance_2_ID__c = existingContract.Appliance_2_ID__c;
        contractObj.Appliance_Model_2__c = existingContract.Appliance_Model_2__c;
        contractObj.Appliance_Model_1__c = existingContract.Appliance_Model_1__c;
        contractObj.Appliance_Ship_Date_Appliance_2_opt__c = existingContract.Appliance_Ship_Date_Appliance_2_opt__c;
        contractObj.Appliance_Ship_Date__c = existingContract.Appliance_Ship_Date__c;
        contractObj.Approval_Request_Notes__c = existingContract.Approval_Request_Notes__c;
        contractObj.Approver_1__c = existingContract.Approver_1__c;
        contractObj.Approver_2__c = existingContract.Approver_2__c;
        contractObj.Approver_3__c = existingContract.Approver_3__c;
        contractObj.Approver_4__c = existingContract.Approver_4__c;
        contractObj.Approver_5__c = existingContract.Approver_5__c;
        contractObj.Approver_6__c = existingContract.Approver_6__c;
        contractObj.Audited_for_Supersession__c = existingContract.Audited_for_Supersession__c;
        contractObj.Billed_Under__c = existingContract.Billed_Under__c;
        contractObj.Billing_Account__c = existingContract.Billing_Account__c;
        contractObj.Billing_Pause_Expiration__c = existingContract.Billing_Pause_Expiration__c;
        contractObj.Billing_Pause_Owner__c = existingContract.Billing_Pause_Owner__c;
        contractObj.Billing_Pause_Status__c = existingContract.Billing_Pause_Status__c;
        contractObj.Cancellation_fee__c = existingContract.Cancellation_fee__c;
        contractObj.Client_Confidentiality_Agreement2__c = existingContract.Client_Confidentiality_Agreement2__c;
        contractObj.Client_Onboarding_Status__c = existingContract.Client_Onboarding_Status__c;
        contractObj.Co_Marketing_Agreement_2__c = existingContract.Co_Marketing_Agreement_2__c;
        contractObj.Confidentiality_Svcs_Data_Sheet__c = existingContract.Confidentiality_Svcs_Data_Sheet__c;
        contractObj.Contingency_Deadline__c = existingContract.Contingency_Deadline__c;
        contractObj.Contingency__c = existingContract.Contingency__c;
        contractObj.Contingency_Type__c = existingContract.Contingency_Type__c;
        contractObj.Contracted_Amendment_Date__c = existingContract.Contracted_Amendment_Date__c;
        contractObj.Contract_Recipient__c = existingContract.Contract_Recipient__c;
        contractObj.Contract_Uploaded__c = existingContract.Contract_Uploaded__c;
        contractObj.Current_Invoice_Due_Date__c = existingContract.Current_Invoice_Due_Date__c;
        contractObj.Customer_Form_Received__c = existingContract.Customer_Form_Received__c;
        contractObj.Custom_Terms__c = existingContract.Custom_Terms__c;
        contractObj.Date_Invoice_Sent__c = existingContract.Date_Invoice_Sent__c;
        contractObj.DCP_Contract_Number__c = existingContract.DCP_Contract_Number__c;
        contractObj.Deal_Cloud_Id__c = existingContract.Deal_Cloud_Id__c;
        contractObj.Deferral__c = existingContract.Deferral__c;
        contractObj.Discount_Approved__c = existingContract.Discount_Approved__c;
        contractObj.Discount_Calculated__c = existingContract.Discount_Calculated__c;
        contractObj.Discount_Justified__c = existingContract.Discount_Justified__c;
        contractObj.Early_Payment_Incentive__c = existingContract.Early_Payment_Incentive__c;
        contractObj.Early_Payment_Notes__c = existingContract.Early_Payment_Notes__c;
        contractObj.Enterprise_Development__c = existingContract.Enterprise_Development__c;
        contractObj.Enterprise_Production__c = existingContract.Enterprise_Production__c;
        contractObj.Entitled_to_Permanent_License__c = existingContract.Entitled_to_Permanent_License__c;
        contractObj.Escrow_Agreement__c = existingContract.Escrow_Agreement__c;
        contractObj.OSA_Number__c = existingContract.OSA_Number__c;
        contractObj.Deal_Type__c = mapOfOrderToEntitlement.get(contractObj.SBQQ__Order__c).Deal_Type__c;
    }
    global static void setContractFields2(Contract contractObj , Contract existingContract){
        contractObj.Escrow_Commitments__c = existingContract.Escrow_Commitments__c;
        contractObj.Exception_Approval__c = existingContract.Exception_Approval__c;
        contractObj.Exception_Approver_1__c = existingContract.Exception_Approver_1__c;
        contractObj.Exception_Approver_2__c = existingContract.Exception_Approver_2__c;
        contractObj.Exception_Approver_3__c = existingContract.Exception_Approver_3__c;
        contractObj.Exception_Approver_4__c = existingContract.Exception_Approver_4__c;
        contractObj.Exception_Approver_5__c = existingContract.Exception_Approver_5__c;
        contractObj.Exception_Approver_6__c = existingContract.Exception_Approver_6__c;
        contractObj.External_Notification_Sent__c = existingContract.External_Notification_Sent__c;
        contractObj.Future_Lawyer_FE_Uplift_Commitments__c = existingContract.Future_Lawyer_FE_Uplift_Commitments__c;
        contractObj.Includes_modification_to_contract_term__c = existingContract.Includes_modification_to_contract_term__c;
        contractObj.Includes_multi_year_term_for_on_perm__c = existingContract.Includes_multi_year_term_for_on_perm__c;
        contractObj.Includes_platform_deployment_conversion__c = existingContract.Includes_platform_deployment_conversion__c;
        contractObj.Includes_Termination_Clause__c = existingContract.Includes_Termination_Clause__c;
        contractObj.Initial_Software_Term_Length__c = existingContract.Initial_Software_Term_Length__c;
        contractObj.Initial_Term_End_Date__c = existingContract.Initial_Term_End_Date__c;
        contractObj.Installation_Setup_Project__c = existingContract.Installation_Setup_Project__c;
        contractObj.Tsunami_Appliance_Terms2__c = existingContract.Tsunami_Appliance_Terms2__c;
        contractObj.Wall_Builder_Terms__c = existingContract.Wall_Builder_Terms__c;
        contractObj.Invoice_Type__c = existingContract.Invoice_Type__c;
        contractObj.Law_Firm_Confidentiality_Mgmt_Overview__c = existingContract.Law_Firm_Confidentiality_Mgmt_Overview__c;
        contractObj.Legacy_DCP_Billing_Account__c = existingContract.Legacy_DCP_Billing_Account__c;
        contractObj.Liability__c = existingContract.Liability__c;
        contractObj.Liability_Confidentiality_Exception__c = existingContract.Liability_Confidentiality_Exception__c;
        contractObj.Liability_Notes__c = existingContract.Liability_Notes__c;
        contractObj.Applicable_Subsidiary__c = existingContract.Applicable_Subsidiary__c;
        contractObj.Manual_OSA_Indicator__c = existingContract.Manual_OSA_Indicator__c;
        contractObj.Multi_Product_Deal__c = existingContract.Multi_Product_Deal__c;
        contractObj.Network_Configuration_Datasheet__c = existingContract.Network_Configuration_Datasheet__c;
        contractObj.Non_cancelable_Multiyear_Agreements__c = existingContract.Non_cancelable_Multiyear_Agreements__c;
        contractObj.Non_standard_Cloud_Data_Location__c = existingContract.Non_standard_Cloud_Data_Location__c;
        contractObj.Non_standard_Cloud_Data_Location_Detail__c = existingContract.Non_standard_Cloud_Data_Location_Detail__c;
        contractObj.Non_Standard_Cloud_Location__c = existingContract.Non_Standard_Cloud_Location__c;
        contractObj.Notes__c = existingContract.Notes__c;
        contractObj.Number_of_users__c = existingContract.Number_of_users__c;
        contractObj.OP4I_Contract_Id__c = existingContract.OP4I_Contract_Id__c;
        contractObj.OP4I_Deal_Owner__c = existingContract.OP4I_Deal_Owner__c;
        contractObj.Opportunity_Engagement_Summary2__c = existingContract.Opportunity_Engagement_Summary2__c;
        contractObj.Order_and_Sale_Agreement2__c = existingContract.Order_and_Sale_Agreement2__c;
        contractObj.OSA_Customer_Name__c = existingContract.OSA_Customer_Name__c;
        contractObj.OSA_Type__c = existingContract.OSA_Type__c;
        contractObj.Contract__c = existingContract.Contract__c;
        contractObj.Parent_Contract__c = existingContract.Parent_Contract__c;
        contractObj.Consulting_Dollars_non_Tsunami__c = existingContract.Consulting_Dollars_non_Tsunami__c;
        contractObj.Partner_Consulting_Hours__c = existingContract.Partner_Consulting_Hours__c;
        contractObj.Partner_Consulting_Sale_Agreement2__c = existingContract.Partner_Consulting_Sale_Agreement2__c;
        contractObj.Payment_Processor__c = existingContract.Payment_Processor__c;
        contractObj.Payment_Received__c = existingContract.Payment_Received__c;
        contractObj.Payment_Status__c = existingContract.Payment_Status__c;
        contractObj.Payment_Terms_Services__c = existingContract.Payment_Terms_Services__c;
        contractObj.Payment_Terms_Software__c = existingContract.Payment_Terms_Software__c;
        contractObj.Pending_Amendment_Date__c = existingContract.Pending_Amendment_Date__c;
        contractObj.Price_book_exception__c = existingContract.Price_book_exception__c;
        contractObj.Additional_Data_Sources__c = existingContract.Additional_Data_Sources__c;
    }
    global static void setContractFields3(Contract contractObj , Contract existingContract){
        contractObj.Proposal__c = existingContract.Proposal__c;
        contractObj.Recipient__c = existingContract.Recipient__c;
        contractObj.Recipient_s_Title__c = existingContract.Recipient_s_Title__c;
        contractObj.Recipient_Phone__c = existingContract.Recipient_Phone__c;
        contractObj.Recurring_Adjustment_Renewal__c = existingContract.Recurring_Adjustment_Renewal__c;
        contractObj.Reference_Program__c = existingContract.Reference_Program__c;
        contractObj.Replace_existing_agreement__c = existingContract.Replace_existing_agreement__c;
        contractObj.Change_Requestor__c = existingContract.Change_Requestor__c;
        contractObj.Requester_2__c = existingContract.Requester_2__c;
        contractObj.Retainer_percentage__c = existingContract.Retainer_percentage__c;
        contractObj.Retainer__c = existingContract.Retainer__c;
        contractObj.Right_of_Return__c = existingContract.Right_of_Return__c;
        contractObj.Risk_Management_Program__c = existingContract.Risk_Management_Program__c;
        contractObj.ROR__c = existingContract.ROR__c;
        contractObj.ROR_Expiration_Date__c = existingContract.ROR_Expiration_Date__c;
        contractObj.Send_Notification__c = existingContract.Send_Notification__c;
        contractObj.Services_Expiration__c = existingContract.Services_Expiration__c;
        contractObj.Services_Expiration_Amendment__c = existingContract.Services_Expiration_Amendment__c;
        contractObj.Services_Expiration_Amendment_Status__c = existingContract.Services_Expiration_Amendment_Status__c;
        contractObj.Services_Expiration_Duration__c = existingContract.Services_Expiration_Duration__c;
        contractObj.Services_Payment_Terms__c = existingContract.Services_Payment_Terms__c;
        contractObj.Services_Request_link__c = existingContract.Services_Request_link__c;
        contractObj.CPI__c = existingContract.CPI__c;
        contractObj.CPI_Other__c = existingContract.CPI_Other__c;
        contractObj.Shipper_Tracking_Number_Appliance_2__c = existingContract.Shipper_Tracking_Number_Appliance_2__c;
        contractObj.Shipper_Tracking_Number__c = existingContract.Shipper_Tracking_Number__c;
        contractObj.Shipping_Address__c = existingContract.Shipping_Address__c;
        contractObj.Shipping_Company_Appliance_2_opt__c = existingContract.Shipping_Company_Appliance_2_opt__c;
        contractObj.Shipping_Company__c = existingContract.Shipping_Company__c;
        contractObj.Shipping_Status__c = existingContract.Shipping_Status__c;
        contractObj.Software_Billing_Frequency_1st_Year__c = existingContract.Software_Billing_Frequency_1st_Year__c;
        contractObj.Software_Days_Payment_Due_Renewal__c= existingContract.Software_Days_Payment_Due_Renewal__c;
        contractObj.SOW__c = existingContract.SOW__c;
        contractObj.Special_Financing_Terms__c = existingContract.Special_Financing_Terms__c;
        contractObj.Standard_Development__c = existingContract.Standard_Development__c;
        contractObj.Standard_Production__c = existingContract.Standard_Production__c;
        contractObj.Subsidiary__c = existingContract.Subsidiary__c;
        contractObj.Superseded_by_OSA__c = existingContract.Superseded_by_OSA__c;
        contractObj.Superseded_by_OSA_2__c = existingContract.Superseded_by_OSA_2__c;
        contractObj.Superseded_by_OSA_3__c = existingContract.Superseded_by_OSA_3__c;
        contractObj.Superseded_by_OSA_4__c = existingContract.Superseded_by_OSA_4__c;
        contractObj.Superseded_by_OSA_5__c = existingContract.Superseded_by_OSA_5__c;
        contractObj.Support_SLA__c = existingContract.Support_SLA__c;
        contractObj.Support_Stream__c = existingContract.Support_Stream__c;
        contractObj.Time_Builder_Terms__c = existingContract.Time_Builder_Terms__c;
        contractObj.Total_Contract_Value__c = existingContract.Total_Contract_Value__c;
        contractObj.Type__c = existingContract.Type__c;
        contractObj.Vera_s_Email_Address__c = existingContract.Vera_s_Email_Address__c;
        contractObj.Warranty__c = existingContract.Warranty__c;
    }
}