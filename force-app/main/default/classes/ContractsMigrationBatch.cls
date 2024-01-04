global class ContractsMigrationBatch implements Database.Batchable<sObject>{
    List<string> lstOfContractAssignment;
    global ContractsMigrationBatch() {}

    global ContractsMigrationBatch(List<string> lstOfContractNumbers){
        lstOfContractAssignment = lstOfContractNumbers ;
    }

    global Database.QueryLocator start(Database.BatchableContext bc){
        string endCondition;
        if (lstOfContractAssignment != null && !lstOfContractAssignment.isempty()) {
            for (string endDigit : lstOfContractAssignment) {
                endCondition = endCondition != null? (endCondition +  ' OR ContractNumber like \'%' + endDigit + '\'') :' ContractNumber like \'%' + endDigit + '\'';
            }
        } 
        String query = 'SELECT Id,Processing_Status__c FROM Contract WHERE Processing_Status__c = \'Order and OLI created\'';
        query = endCondition != null? query + ' AND (' + endCondition + ')' : query;
        system.debug('Start Query' +query);   
        return Database.getQueryLocator(query);        
    }
    
    global void execute(Database.BatchableContext bc, List<Contract> lstOfContracts){
        List<order> lstOfOrders = new List<order>();
        List<order> lstOfOrders1 = new List<order>();
        List<order> lstOfOrders2 = new List<order>();
        List<OP4I_Entitlement_View__c> lstOfEntitlementRecords = new List<OP4I_Entitlement_View__c>();
        set<id> setOfOrderIds = new set<id>();
        set<id> setOfOrderIdsNew = new set<id>();
        List<order> lstOfOrderContracts = new List<order>();
        Map<String,Contract> mapOfOrderToContractRecord = new Map<String,Contract>();
        Map<String,OP4I_Entitlement_View__c> mapOfOrderToContractRecords = new Map<String,OP4I_Entitlement_View__c>();
        set<id> setOfOrderUpd = new set<id>();  
        List<Contract> updatedContracts = new List<Contract>(); 
        List<OP4I_Entitlement_View__c> lstOfEntitlementRecordsUpd = new List<OP4I_Entitlement_View__c>();
        if(!lstOfContracts.IsEmpty())
        {
            lstOfEntitlementRecords = [SELECT Id,DLIP_Id__c,Account__c,Quote__c,Quote__r.SBQQ__Ordered__c,Order__c,Order__r.status,Order__r.SBQQ__Contracted__c,Quantity__c
                                     ,Start_Date__c,End_Date__c,Associated_OSA__c,Account__r.Name,Associated_OSA__r.ContractNumber,Opportunity__c,Processing_Status__c
                                     ,Associated_OSA__r.additional_Requester_email__c,Associated_OSA__r.PO_Number__c 
                                     ,Associated_OSA__r.Amendment_Expiration__c,Associated_OSA__r.Appliance_1_ID__c,Associated_OSA__r.Appliance_2_ID__c,Associated_OSA__r.Appliance_Model_2__c
                                     ,Associated_OSA__r.Appliance_Model_1__c,Associated_OSA__r.Appliance_Ship_Date_Appliance_2_opt__c
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
                                     ,Associated_OSA__r.Order_and_Sale_Agreement2__c,Associated_OSA__r.OSA_Customer_Name__c
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
                                     ,Associated_OSA__r.Shipping_Status__c,Associated_OSA__r.Software_Billing_Frequency_1st_Year__c
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
                mapOfOrderToContractRecords.put(entitlemnt.Associated_OSA__c,entitlemnt);                  
              }
            }
            lstOfOrders = [Select Id,status FROM Order WHERE ID IN:setOfOrderIds];                 
            
            if(!lstOfOrders.IsEmpty())
            {
                for(Order orderObj : lstOfOrders)
                {
                    orderObj.status = 'Activated';
                    lstOfOrders1.add(orderObj);                                     
                }
                
                updateOrder(lstOfOrders1,mapOfOrderToContractRecord,mapOfOrderToContractRecords);
                for(Order orderObj : lstOfOrders1)
                {
                    orderObj.SBQQ__Contracted__c = true; 
                    lstOfOrders2.add(orderObj);             
                }
                createContract(lstOfOrders2,mapOfOrderToContractRecords);
                
            }
            
        }         
    }
    global void finish(Database.BatchableContext bc){
        
    }
    global static void updateOrder(List<order> lstOfOrders1,Map<String,Contract> mapOfOrderToContractRecord,Map<String,OP4I_Entitlement_View__c>mapOfOrderToContractRecords){
        Database.SaveResult[] orderActivationResult = Database.update(lstOfOrders1, false);
        //HandleCustomException.logDatabaseErrorsForEntitlements(entitlementListOrderActivation,mapOfOrderToContractRecords);  
        map<string,string> resultMap = HandleCustomException.logMigrationDatabaseError(
            orderActivationResult,
            mapOfOrderToContractRecords,
            'Id',
            lstOfOrders1
        );   
        string keyFields = 'Order__c';
        for(OP4I_Entitlement_View__c entitlement : mapOfOrderToContractRecords.values()) {          
            string key = HandleCustomException.getKey(keyFields, entitlement);
            if (resultMap.containsKey(key)) {
                entitlement.Processing_Status__c = 'Order activation Failed';
                entitlement.Error_Log__c = resultMap.get(key);
                entitlement.Associated_OSA__r.Processing_Status__c = 'Order activation Failed';
            }
        }
    }
    
    global static void createContract(List<order> lstOfOrders2,Map<String,OP4I_Entitlement_View__c>mapOfOrderToContractRecords){
        List<Contract> contractUpdLst = new List<Contract>();
        Database.SaveResult[] orderUpdateResult = Database.update(lstOfOrders2, false);
        //HandleCustomException.logDatabaseErrorsForEntitlements(entitlementListOrderContracts,mapOfOrderToContractRecords);
        map<string,string> resultMap = HandleCustomException.logMigrationDatabaseError(
            orderUpdateResult,
            mapOfOrderToContractRecords,
            'Id',
            lstOfOrders2
        ); 
        
        set<string> failedContractIds = new set<string>();
        string keyFields = 'Order__c';
        for(OP4I_Entitlement_View__c entitlement : mapOfOrderToContractRecords.values()) {          
            string key = HandleCustomException.getKey(keyFields, entitlement);
            if (resultMap.containsKey(key)) {
                entitlement.Processing_Status__c = 'Contract creation Failed';
                entitlement.Error_Log__c = resultMap.get(key);
                entitlement.Associated_OSA__r.Processing_Status__c = 'Contract creation Failed';
                failedContractIds.add(entitlement.Associated_OSA__c);
            } 
        }

        contractUpdLst = [Select Id,Processing_Status__c FROM Contract WHERE ID IN:mapOfOrderToContractRecords.keyset() and Id NOT IN :failedContractIds];
        
        if(contractUpdLst.size()>0)
        {
            for(Contract contr : contractUpdLst)
            {
              contr.Processing_Status__c = 'Contract Created';
            }
            Database.SaveResult[] contractUpdList = Database.update(contractUpdLst, false);
            HandleCustomException.logDatabaseErrorsForEntitlements(contractUpdList,mapOfOrderToContractRecords);  
            
            for(OP4I_Entitlement_View__c entitlemnt : mapOfOrderToContractRecords.values())
            {
                entitlemnt.Processing_Status__c = 'Contract Created';               
            }
        }  
        Database.SaveResult[] entitlementLst = Database.update(mapOfOrderToContractRecords.values(), false);
        HandleCustomException.logDatabaseErrorsForEntitlements(entitlementLst,mapOfOrderToContractRecords);     
    }
}