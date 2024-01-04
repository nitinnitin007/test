/**** @Name :T_SourceInvoiceMove
***** @Created By : KPMG
***** @Created On : Nov 11th, 2023
***** @Description : Update the records with flag for main load - Based on OSA contract
******/
//Database.executeBatch(new T_SourceInvoiceMove('Invoice'),200); ---- On Demand
//Database.executeBatch(new T_SourceInvoiceMove('InvoiceLines'),200); ---- On Demand
//Database.executeBatch(new T_SourceInvoiceMove('Payment'),200); ---- On Demand
//Database.executeBatch(new T_SourceInvoiceMove('PaymentAlloc'),200); ---- On Demand
//Database.executeBatch(new T_SourceInvoiceMove('CreditNote'),200); ---- On Demand
//Database.executeBatch(new T_SourceInvoiceMove('CMLines'),200); ---- On Demand
//Database.executeBatch(new T_SourceInvoiceMove('CMAlloc'),200); ---- On Demand
public class T_SourceInvoiceMove implements Database.Batchable<sObject>,Database.Stateful {
    public String tempFileName;
    public T_SourceInvoiceMove(String fileName){
        this.tempFileName = fileName;
    }
    //Collecting all Active Osa from Temp Table
    public database.querylocator start(Database.BatchableContext bc)
    {
        String query = 'SELECT Id,ContractNumber__c FROM T_OSA__c';
        return Database.getQueryLocator(query);
    }
    //Passing all the active OSA's in execute method
    public void execute(Database.BatchableContext bc,List<T_OSA__c> osas)
    {
        if(this.tempFileName == 'Invoice')
        {
        //Update flag in Invoices
        updateInvoice(osas);  
        } else  if(this.tempFileName == 'InvoiceLines'){
        //Update flag in InvoiceLines
        updateInvoiceLines(osas);   
        } else  if(this.tempFileName == 'Payment'){
        //Update flag in Payments
        updatePayment(osas);   
        } else  if(this.tempFileName == 'PaymentAlloc'){
        //Update flag in Payment Allocations
        updatePaymentAlloc(osas);   
        } else  if(this.tempFileName == 'CreditNote'){
        //Update flag in Credit Note
        updateCreditNote(osas);  
        } else  if(this.tempFileName == 'CMLines'){
        //Update flag in Credit Note Lines
        updateCMLines(osas);
        } else  if(this.tempFileName == 'CMAlloc'){
        //Update flag in Credit Note Allocations
        updateCMAlloc(osas);
        }   
    }
    //Check Order
    //CM Note
    public static void updateCreditNote(List<T_OSA__c> osas)
    {
        Map<String,List<T_qtc_Active_Credit_Memo_Lines_Header__c>> isoToInvoiceMap = new Map<String,List<T_qtc_Active_Credit_Memo_Lines_Header__c>>();
        List<T_qtc_Active_Credit_Memo_Lines_Header__c> forUpdate = new List<T_qtc_Active_Credit_Memo_Lines_Header__c>();
        Set<String> osaNumbers = new Set<String>();
        for(T_OSA__c i : osas)
        {
            osaNumbers.add(i.ContractNumber__c);
        }
        //Qurying CMLines Records
        List<T_qtc_Active_Credit_Memo_Lines_Header__c> matchingCM =[SELECT Id, OSA_TEXT_for_vlookup__c, Billing_StateProvince__c, 
                                                                    Billing_Addressee__c, Shipping_Addressee__c, 
                                                                    Shipping_Attention__c, Shipping_Address_2__c,
                                                                    Billing_Attention__c, Account_ID__c, 
                                                                    Amount_Foreign_Currency__c, Item_Rate__c, 
                                                                    Billing_Address__c, Shipping_Country_Code__c,
                                                                    Billing_Address_1__c, POCheck_Number__c, Shipping_Address__c, 
                                                                    Price_Level__c, Credit_Memo_Reasons__c, Shipping_Address_1__c, 
                                                                    of_Months__c, Support_Level__c, Subsidiary_no_hierarchy__c,
                                                                    Reference_ID_Bundle__c, VAT_Code__c, Shipping_StateProvince__c,
                                                                    Shipping_Zip__c, OSA_Contract_Number_RA__c, Tax_Item__c,
                                                                    Currency__c, Memo_1__c, Billing_Country__c, Name__c, 
                                                                    Billing_City__c, Memo__c, Shipping_City__c, Product_Line__c,
                                                                    Item__c, Internal_ID__c, Period__c, 
                                                                    Item_Rate_without_Currency_Symbol__c, Billing_Zip__c, 
                                                                    Shipping_Country__c, OSA_Contract_Number_from_Salesforce__c, 
                                                                    Status__c, Document_Number__c, Type__c, Quantity__c, 
                                                                    Line_ID__c, Billing_Address_2__c, Billing_Country_Code__c,
                                                                    Created_From__c, Amount_without_currency_symbol__c,
                                                                    Order_Type__c, Sales_Order_Type__c, Date__c, 
                                                                    Rev_Rec_End_Date__c, Rev_Rec_Start_Date__c,T_OSAMatched__c
                                                                    FROM T_qtc_Active_Credit_Memo_Lines_Header__c
                                                                    WHERE  
                                                                    OSA_Contract_Number_from_Salesforce__c in :osaNumbers];
        //Get the Matched Credit Memo Lines
        //System.debug('matchingInvoices:'+matchingCM.size());
        for(T_qtc_Active_Credit_Memo_Lines_Header__c i : matchingCM){
            i.T_OSAMatched__c = true;
            forUpdate.add(i);
        }
        if(forUpdate.size()>0)
            Database.update(forUpdate);
    }
    //CM Lines
    public static void updateCMLines(List<T_OSA__c> osas)
    {
        Map<String,List<T_qtc_Active_Credit_Memo_Tax_Line__c>> isoToInvoiceMap = new Map<String,List<T_qtc_Active_Credit_Memo_Tax_Line__c>>();
        List<T_qtc_Active_Credit_Memo_Tax_Line__c> forUpdate = new List<T_qtc_Active_Credit_Memo_Tax_Line__c>();
        Set<String> osaNumbers = new Set<String>();
        for(T_OSA__c i : osas)
        {
            osaNumbers.add(i.ContractNumber__c);
        }
        //Collecting CMLines record
        List<T_qtc_Active_Credit_Memo_Tax_Line__c> matchingCMLines =[SELECT Id,Internal_ID__c, Document_Number__c, 
                                                                     Type__c, Name__c, Currency__c, 
                                                                     Subsidiary_no_hierarchy__c, Date__c, 
                                                                     Created_From__c, Period__c, PO_Check_Number__c, 
                                                                     Memo__c, OSA_Contract_Number_from_Salesforce__c, 
                                                                     OSA_TEXT_for_vlookup__c, Credit_Memo_Reasons__c, 
                                                                     Line_ID__c, Item__c, Quantity__c, of_Months__c, 
                                                                     Price_Level__c, Item_Rate__c, 
                                                                     Item_Rate_without_Symbol__c, 
                                                                     Amount_Foreign_Currency__c, 
                                                                     Foreign_Amount_without_Symbol__c, Tax_Item__c, 
                                                                     Support_Level__c, OSA_Contract_Number_RA__c,
                                                                     Reference_ID_Bundle__c, Rev_Rec_Start_Date__c, 
                                                                     Rev_Rec_End_Date__c, Product_Line__c, 
                                                                     Order_Type__c, Sales_Order_Type__c, VAT_Code__c,T_OSAMatched__c 
                                                                     FROM T_qtc_Active_Credit_Memo_Tax_Line__c
                                                                     WHERE  
                                                                     OSA_Contract_Number_from_Salesforce__c in :osaNumbers];
        //Get the Matched Credit Memo Tax Line
        //System.debug('matchingInvoices:'+matchingCMLines.size());
        for(T_qtc_Active_Credit_Memo_Tax_Line__c i : matchingCMLines){
            i.T_OSAMatched__c = true;
            forUpdate.add(i);
        }
        if(forUpdate.size()>0)
            Database.update(forUpdate);
    }
    //CM Alloc
    public static void updateCMAlloc(List<T_OSA__c> osas)
    {
        Map<String,List<T_qtc_Active_Credit_Memo_Allocation__c>> isoToInvoiceMap = new Map<String,List<T_qtc_Active_Credit_Memo_Allocation__c>>();
        List<T_qtc_Active_Credit_Memo_Allocation__c> forUpdate = new List<T_qtc_Active_Credit_Memo_Allocation__c>();
        Set<String> osaNumbers = new Set<String>();
        for(T_OSA__c i : osas)
        {
            osaNumbers.add(i.ContractNumber__c);
        }
        //COllecting CMAlloc Records
        List<T_qtc_Active_Credit_Memo_Allocation__c> matchingPaymentAlloc =[SELECT Id, Name, Type__c, 
                                                                            Applied_To_Internal_ID__c, Applied_To_Link__c,
                                                                            Applied_To_Doc_Number__c, Internal_ID__c, 
                                                                            OSA_Contract_Number_from_Salesforce__c, 
                                                                            Document_Number__c, Formula_Text__c, Date__c, 
                                                                            Applied_To_Amt__c, 
                                                                            Applied_to_Amt_without_Symbol__c,T_OSAMatched__c
                                                                            FROM
                                                                            T_qtc_Active_Credit_Memo_Allocation__c
                                                                            WHERE  
                                                                            OSA_Contract_Number_from_Salesforce__c in :osaNumbers];
        //Get the Matched Credit Memo Alloc
        //System.debug('matchingInvoices:'+matchingPaymentAlloc.size());
        for(T_qtc_Active_Credit_Memo_Allocation__c i : matchingPaymentAlloc){
            i.T_OSAMatched__c = true;
            forUpdate.add(i);
        }
        if(forUpdate.size()>0)
            Database.update(forUpdate);
    }
    //Payment Alloc
    public static void updatePaymentAlloc(List<T_OSA__c> osas)
    {
        Map<String,List<T_qtc_ActiveCustomer_Payment_Alloc_Detai__c>> isoToInvoiceMap = new Map<String,List<T_qtc_ActiveCustomer_Payment_Alloc_Detai__c>>();
        List<T_qtc_ActiveCustomer_Payment_Alloc_Detai__c> forUpdate = new List<T_qtc_ActiveCustomer_Payment_Alloc_Detai__c>();
        Set<String> osaNumbers = new Set<String>();
        for(T_OSA__c i : osas)
        {
            osaNumbers.add(i.ContractNumber__c);
        }
        //Collecting Payment Alloc Records
        List<T_qtc_ActiveCustomer_Payment_Alloc_Detai__c> matchingPaymentAlloc =[SELECT Id, Date__c, Document_Number__c, Internal_ID__c, 
                                                                                 Formula_Text__c, Invoice_Internal_ID__c, Applied_Amount__c,
                                                                                 Applied_Amount_without_Symbol__c, Applied_To_Trans__c, 
                                                                                 Applied_To_Link_Type__c,Payment_Number__c, OSA__c ,T_OSAMatched__c
                                                                                 FROM T_qtc_ActiveCustomer_Payment_Alloc_Detai__c
                                                                                 WHERE  
                                                                                 OSA__c in :osaNumbers];
        //Get the Matched Payment Alloc
        //System.debug('matchingInvoices:'+matchingPaymentAlloc.size());
        for(T_qtc_ActiveCustomer_Payment_Alloc_Detai__c i : matchingPaymentAlloc){
            i.T_OSAMatched__c = true;
            forUpdate.add(i);
        }
        if(forUpdate.size()>0)
            Database.update(forUpdate);
    }
    //Payment
    public static void updatePayment(List<T_OSA__c> osas)
    {
        Map<String,List<T_qtc_Active_Invoice_Line__c>> isoToInvoiceMap = new Map<String,List<T_qtc_Active_Invoice_Line__c>>();
        List<T_qtc_Active_Payment_Customer_Detail__c> forUpdate = new List<T_qtc_Active_Payment_Customer_Detail__c>();
        Set<String> osaNumbers = new Set<String>();
        for(T_OSA__c i : osas)
        {
            osaNumbers.add(i.ContractNumber__c);
        }
        //Collecting Payment Records
        List<T_qtc_Active_Payment_Customer_Detail__c> matchingPayment =[SELECT Id, Name, Bank_Fee__c, Internal_ID__c, 
                                                                        OSA_Contract_Number_from_Salesforce__c, Amount_Foreign_Currency_without_Symbol__c, 
                                                                        External_ID__c, Formula_Text__c, Status__c, Subsidiary_no_hierarchy__c, 
                                                                        Document_Number__c, Amount_Foreign_Currency__c, Currency__c, Exchange_Rate__c, 
                                                                        Memo__c, Date__c, Name__c, Account__c, Period__c, Type__c , T_OSAMatched__c
                                                                        FROM T_qtc_Active_Payment_Customer_Detail__c
                                                                        WHERE  
                                                                        OSA_Contract_Number_from_Salesforce__c in :osaNumbers];
        //Get the Matched Payment Customer Detail
        //System.debug('matchingInvoices:'+matchingPayment.size());
        for(T_qtc_Active_Payment_Customer_Detail__c i : matchingPayment){
            i.T_OSAMatched__c = true;
            forUpdate.add(i);
        }
        if(forUpdate.size()>0)
            Database.update(forUpdate);
    }
    //Invoice Line
    public static void updateInvoiceLines(List<T_OSA__c> osas)
    {
        Map<String,List<T_qtc_Active_Invoice_Line__c>> isoToInvoiceMap = new Map<String,List<T_qtc_Active_Invoice_Line__c>>();
        List<T_qtc_Active_Invoice_Line__c> forUpdate = new List<T_qtc_Active_Invoice_Line__c>();
        Set<String> osaNumbers = new Set<String>();
        for(T_OSA__c i : osas)
        {
            osaNumbers.add(i.ContractNumber__c);
        }
        //Collecting Inv Line Records
        List<T_qtc_Active_Invoice_Line__c> matchingInvLines =[SELECT Id, Name,Internal_ID__c, Document_Number__c, Line_ID__c, 
                                                              Line_Sequence_Number__c, Item__c, Quantity__c, of_Months__c, 
                                                              Price_Level__c, Item_Rate__c, Item_Rate_Amount_without_Symbol__c,
                                                              Amount_Foreign_Currency__c, Amount_Foreign_Currency_without_Symbol__c,
                                                              Tax_Item__c, Support_Level__c, OSA_Contract_Number_from_Salesforce__c,
                                                              OSA_Contract_Number_RA__c, Rev_Rec_Start_Date__c, Rev_Rec_End_Date__c,
                                                              Order_Type__c, Contract_Item_Start_Date__c, Contract_Item_End_Date__c,
                                                              Tax_Amount__c, Tax__c, ProServe_Software__c,T_OSAMatched__c
                                                              FROM T_qtc_Active_Invoice_Line__c
                                                              WHERE  
                                                              OSA_Contract_Number_from_Salesforce__c in :osaNumbers];
        //Get the Matched invoice lines
        //System.debug('matchingInvoices:'+matchingInvLines.size());
        for(T_qtc_Active_Invoice_Line__c i : matchingInvLines){
            i.T_OSAMatched__c = true;
            forUpdate.add(i);
        }
        if(forUpdate.size()>0)
            Database.update(forUpdate);
    }
    //Invoice
    public static void updateInvoice(List<T_OSA__c> osas)
    {
        Map<String,List<T_Invoice_NewTemp__c>> isoToInvoiceMap = new Map<String,List<T_Invoice_NewTemp__c>>();
        List<T_Invoice_NewTemp__c> forUpdate = new List<T_Invoice_NewTemp__c>();
        Set<String> osaNumbers = new Set<String>();
        for(T_OSA__c i : osas)
        {//T_Invoice__c,Internal_ID__c
            osaNumbers.add(i.ContractNumber__c);
            
        }
        //Collecting Invoice Records
        List<T_Invoice_NewTemp__c> matchingInvoices =[SELECT Id, T_OSAMatched__c ,Name,Rev_Rec_Special_Case__c, Shipping_Address_2__c, Shipping_Attention__c, ROR_Date__c,
                                                      Replaced_Invoice__c, Deal_ID__c, Shipping_Country__c, Account__c, Billing_Attention__c, Billing_Address_2__c,
                                                      Document_Number__c, Start_Date__c, Currency__c, Amount_Tax__c, Billing_StateProvince__c, Internal_ID__c,
                                                      Terms__c, OA_Project_ID__c, Shipping_Address_1__c, Due_DateReceive_By__c, Term_Start_Date__c,
                                                      Termination_for_Convenience__c, Billing_Addressee__c, End_Date__c, OA_Project_Type__c, Tax__c, Term_End_Date__c,
                                                      Billing_Country_Code__c, Invoice_Status__c, Name__c, Memo__c, Multi_Year__c, SFA_Cap__c,
                                                      Billing_Address_3__c, Shipping_Zip__c, Amount_Foreign_Currency__c, Account_ID__c, 
                                                      Amount_Foreign_Currency_without_Symbol__c, Billing_Country__c, Exchange_Rate__c, Date__c, Billing_Zip__c, PO__c,
                                                      OSA_Contract_Number_from_Salesforce__c, Shipping_Address_3__c, Billing_City__c, To_Be_Emailed__c, 
                                                      Shipping_StateProvince__c, Sales_Order_Type__c, Formula_Text__c, Period__c, Billing_Address_1__c, 
                                                      SFA_Uplift__c, OA_Business_Unit__c, Shipping_City__c, Shipping_Addressee__c, Created_From__c, Invoice_Type__c, 
                                                      Subsidiary__c, Status__c, Shipping_Country_Code__c, T_Name__c FROM T_Invoice_NewTemp__c WHERE  
                                                      OSA_Contract_Number_from_Salesforce__c in :osaNumbers];
        //Get the Matched invoices
        System.debug('matchingInvoices:'+matchingInvoices.size());
        for(T_Invoice_NewTemp__c i : matchingInvoices){
            i.T_OSAMatched__c = true;
            forUpdate.add(i);
        }
        
        if(forUpdate.size()>0)
            Database.update(forUpdate);
    }
    public void finish(Database.BatchableContext bc){
    }
}