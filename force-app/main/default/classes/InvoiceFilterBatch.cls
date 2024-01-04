global with sharing class InvoiceFilterBatch implements Database.Batchable<sObject> {
    List<string> recordIds;
    global InvoiceFilterBatch(List<string> recordIds){
        this.recordIds = recordIds;
    }

    global InvoiceFilterBatch(){}

    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = '' 
            + ' SELECT Id'
            + '      , Name, Account_ID__c, Account__c, Amount_Foreign_Currency__c'
            + '      , Amount_Foreign_Currency_without_Symbol__c, Amount_Tax__c'
            + '      , Billing_Address_1__c, Billing_Address_2__c, Billing_Address_3__c'
            + '      , Billing_Addressee__c, Billing_Attention__c, Billing_City__c'
            + '      , Billing_Country_Code__c, Billing_Country__c, Billing_StateProvince__c'
            + '      , Billing_Zip__c, Created_From__c, Currency__c, Date__c, Deal_ID__c'
            + '      , Deal_Id_OSA__c, Document_Number__c, Due_DateReceive_By__c, End_Date__c'
            + '      , Exchange_Rate__c, Filtered__c, Formula_Text__c, Internal_ID__c'
            + '      , Invoice_Status__c, Invoice_Type__c, Memo__c, Multi_Year__c, Name__c'
            + '      , OA_Business_Unit__c, OA_Project_ID__c, OA_Project_Type__c'
            + '      , OSA_Contract_Number_from_Salesforce__c, OSA_TEXT_for_vlookup__c'
            + '      , PO__c, Period__c, ROR_Date__c, Reason__c, Replaced_Invoice__c'
            + '      , Rev_Rec_Special_Case__c, SFA_Cap__c, SFA_Uplift__c, Sales_Order_Type__c'
            + '      , Shipping_Address_1__c, Shipping_Address_2__c, Shipping_Address_3__c'
            + '      , Shipping_Addressee__c, Shipping_Attention__c, Shipping_City__c'
            + '      , Shipping_Country_Code__c, Shipping_Country__c, Shipping_StateProvince__c'
            + '      , Shipping_Zip__c, Start_Date__c, Status__c, Subsidiary__c, T_Name__c'
            + '      , T_OSAMatched__c, T_OSA_text_for_Vlookup__c, T_SourceFileName__c, Tax__c'
            + '      , Term_End_Date__c, Term_Start_Date__c, Termination_for_Convenience__c'
            + '      , Terms__c, To_Be_Emailed__c'
            + '   FROM T_Invoice_NewTemp__c'
            + '  WHERE (Filtered__c = null OR Filtered__c = \'\')';  

            if (recordIds != null && !recordIds.isEmpty()) {
                query += ' AND ID IN :recordIds';
            }
        return Database.getQueryLocator(query);        
    }

    global void execute(Database.BatchableContext bc, List<T_Invoice_NewTemp__c> tempInvoiceList){

        set<string> invalidSalesOrderTypes = new set<string>{
            'New Hardware', 'Marketing Event', 'Services Agreement�T&M'
        };

        set<String> osaContractNumbers = new set<String>();
        set<String> internalIds = new set<String>();
        set<String> oaProjectIds = new set<String>();

        List<T_Invoice_NewTemp__c> invoiceWithOsaNumberList = new List<T_Invoice_NewTemp__c>();
        List<T_Invoice_NewTemp__c> invoiceWithOaProjectIdList = new List<T_Invoice_NewTemp__c>();
        for (T_Invoice_NewTemp__c tempInvoice : tempInvoiceList) {
            
            //check if Sales order Type is valid else exclude them
            if (!invalidSalesOrderTypes.contains(tempInvoice.Sales_Order_Type__c)) {
                //collect all osa contract number
                if (tempInvoice.OSA_Contract_Number_from_Salesforce__c != null) {
                    osaContractNumbers.add(tempInvoice.OSA_Contract_Number_from_Salesforce__c);
                    invoiceWithOsaNumberList.add(tempInvoice);
                    if (tempInvoice.Internal_ID__c != null) {
                        internalIds.add(tempInvoice.Internal_ID__c);
                    }
                    
                //for those who dont have osa contract number check if they have OA project Id
                } else {
                    if (tempInvoice.OA_Project_ID__c != null) {
                        oaProjectIds.add(tempInvoice.OA_Project_ID__c);
                        invoiceWithOaProjectIdList.add(tempInvoice);
                    }
                }
            //with invalid Sales Order Type
            } else {
                tempInvoice.Filtered__c = 'False';
                tempInvoice.Reason__c = 'Invalid Sales Order Type';
            }
        }

        //collect all Entilement view records based on OSA Cotract numbers
        if (!osaContractNumbers.isEmpty()) {
            map<string,Dates> entitlementOsaIds = new map<string,Dates>();
            getOsaFromEntitlement(osaContractNumbers,entitlementOsaIds);

            //bring invoice line from QtC_Mig_Invoice_Lines_Temp_Table based on internalIds
            map<string,Dates> datesBasedOnInternalIdMap = new map<string,Dates>();
            set<string> hasExcludedProduct = new set<string>();
            getLinesBasedOnInternalId(internalIds,datesBasedOnInternalIdMap,hasExcludedProduct);
            
            system.debug('hasExcludedProduct--->'+hasExcludedProduct);
            processScenario2(invoiceWithOsaNumberList,entitlementOsaIds,datesBasedOnInternalIdMap,hasExcludedProduct);
            
        }

        processScenario3(oaProjectIds,invoiceWithOaProjectIdList);

        HandleCustomException.logDatabaseErrors(Database.update(tempInvoiceList,false));

    }

    global void finish(Database.BatchableContext bc){
       
    }

    public void processScenario2(List<T_Invoice_NewTemp__c> invoiceWithOsaNumberList,
        Map<string,Dates> entitlementOsaIds,
        Map<string,Dates> datesBasedOnInternalIdMap,
        set<string> hasExcludedProduct

    ) {
        for (T_Invoice_NewTemp__c tempInvoice : invoiceWithOsaNumberList) {
            //invoices with OSA number but OSA not found scenario 2.1
            if (string.isBlank(tempInvoice.Filtered__c) && !entitlementOsaIds.containsKey(tempInvoice.OSA_Contract_Number_from_Salesforce__c)) {
                tempInvoice.Filtered__c = 'False';
                tempInvoice.Reason__c = 'No matching OSA';
            } else {
                //OSA Found then check Dates
                Dates invoiceDateBasedOnLines = datesBasedOnInternalIdMap.get(tempInvoice.Internal_ID__c);
                Dates osaContractDates = entitlementOsaIds.get(tempInvoice.OSA_Contract_Number_from_Salesforce__c);
                Date invoiceStartDate = tempInvoice.Term_Start_Date__c != null? getDate(tempInvoice.Term_Start_Date__c) : 
                    (invoiceDateBasedOnLines != null? invoiceDateBasedOnLines.minDate : null);

                Date invoiceEndDate = tempInvoice.Term_Start_Date__c != null? getDate(tempInvoice.Term_Start_Date__c) : 
                    (invoiceDateBasedOnLines != null? invoiceDateBasedOnLines.maxDate : null);
                //scenario 2.2
                if (!(string.isBlank(tempInvoice.Filtered__c) 
                    && invoiceStartDate != null 
                    && invoiceEndDate != null 
                    && osaContractDates != null 
                    && osaContractDates.minDate != null 
                    && osaContractDates.maxDate != null
                    && invoiceStartDate >= osaContractDates.minDate 
                    && invoiceEndDate <= osaContractDates.maxDate)
                ) {
                    tempInvoice.Filtered__c = 'False';
                    tempInvoice.Reason__c = 'Mismatched Dates';
                } 

                //check if it has excluded product GE-00159, scenario 2.3
                if (string.isBlank(tempInvoice.Filtered__c) && hasExcludedProduct.contains(tempInvoice.Internal_ID__c)) {
                    tempInvoice.Filtered__c = 'False';
                    tempInvoice.Reason__c = 'Has GE-00159';
                }

                //if none of 2.1,2.2 and 2.3 then set to true
                if (string.isBlank(tempInvoice.Filtered__c)) {
                    tempInvoice.Filtered__c = 'True';
                }
            }
        }
    }

    public void processScenario3(set<string> oaProjectIds,list<T_Invoice_NewTemp__c> invoiceWithOaProjectIdList) {
        if (!oaProjectIds.isEmpty()) {
            set<string> serviceProjectOaIds = new set<string>();
            for(T_Services_Project__c servicesProject : [
                SELECT id
                     , OA_Project_Id__c
                  FROM T_Services_Project__c
                 WHERE OA_Project_Id__c IN :oaProjectIds
            ]) {
                serviceProjectOaIds.add(servicesProject.OA_Project_Id__c);
            }

            for (T_Invoice_NewTemp__c tempInvoice : invoiceWithOaProjectIdList) {
                if (string.isBlank(tempInvoice.Filtered__c) && !serviceProjectOaIds.contains(tempInvoice.OA_Project_ID__c)) {
                    tempInvoice.Filtered__c = 'False';
                    tempInvoice.Reason__c = 'Invalid OA project number';
                }

                if (string.isBlank(tempInvoice.Filtered__c)) {
                    tempInvoice.Filtered__c = 'True';
                }
            }
        }
    }
    public void getOsaFromEntitlement (set<string> osaContractNumbers,map<string,Dates> entitlementOsaIds) {
        for(OP4I_Entitlement_View__c entitlementView : [
            SELECT id
                    , OSA_Text__c
                    , Start_Date__c
                    , End_Date__c
                FROM OP4I_Entitlement_View__c
                WHERE OSA_Text__c IN :osaContractNumbers
        ]) {
            //find the min start date and max end date of the Entitlement view records and arrange it by OSA contract number.
            if (entitlementOsaIds.containsKey(entitlementView.OSA_Text__c)) {
                Dates dt = entitlementOsaIds.get(entitlementView.OSA_Text__c);
                if (entitlementView.Start_Date__c != null && (dt.minDate == null || dt.minDate > entitlementView.Start_Date__c)) {
                    dt.minDate = entitlementView.Start_Date__c;
                }

                if (entitlementView.End_Date__c != null && (dt.maxDate == null || dt.maxDate < entitlementView.End_Date__c)) {
                    dt.maxDate = entitlementView.End_Date__c;
                }
            } else {
                Dates dt = new Dates();
                dt.minDate = entitlementView.Start_Date__c;
                dt.maxDate = entitlementView.End_Date__c;
                entitlementOsaIds.put(entitlementView.OSA_Text__c,dt);
            }
            
        }
    }

    public void getLinesBasedOnInternalId(set<string>internalIds,
        map<string,Dates> datesBasedOnInternalIdMap,
        set<string> hasExcludedProduct
    ) {
        if (!internalIds.isEmpty()) {
            for (T_qtc_Active_Invoice_Line__c qtcActiveLines : [
                SELECT Id
                        , Internal_ID__c
                        , Contract_Item_Start_Date__c
                        , Contract_Item_End_Date__c
                        , Item__c
                    FROM T_qtc_Active_Invoice_Line__c
                    WHERE Internal_ID__c IN :internalIds
            ]) {
                //find the min Start date and Max End date based on internal ids and add it the map
                Date contractItemStartDate = getDate(qtcActiveLines.Contract_Item_Start_Date__c);
                Date contractItemEndDate = getDate(qtcActiveLines.Contract_Item_End_Date__c);
                if (datesBasedOnInternalIdMap.containsKey(qtcActiveLines.Internal_ID__c)) {
                    Dates dt = datesBasedOnInternalIdMap.get(qtcActiveLines.Internal_ID__c);
                    
                    if (contractItemStartDate != null && (dt.minDate == null || dt.minDate > contractItemStartDate)) {
                        dt.minDate = contractItemStartDate;
                    }

                    if (contractItemEndDate != null && (dt.maxDate == null || dt.maxDate < contractItemEndDate)) {
                        dt.maxDate = contractItemEndDate;
                    }
                } else {
                    Dates dt = new Dates();
                    dt.minDate = contractItemStartDate;
                    dt.maxDate = contractItemEndDate;
                    datesBasedOnInternalIdMap.put(qtcActiveLines.Internal_ID__c,dt);
                }

                //check if it has excluded product
                if (qtcActiveLines.Item__c == 'GE-00159') {
                    hasExcludedProduct.add(qtcActiveLines.Internal_ID__c);
                }
            }
        }
    }

    public static Date getDate(string dateString) {
        Pattern pattern = Pattern.compile('[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]');
        if (string.isNotBlank(dateString)) {
            Matcher matcher = pattern.matcher(dateString);
            if (matcher.matches()) {
                return Date.valueOf(dateString);
            }
        } 
        return null;
    }

    public class Dates {
        public Date minDate;
        public Date maxDate;
    }
}