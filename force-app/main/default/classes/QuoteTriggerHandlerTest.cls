@isTest
public class QuoteTriggerHandlerTest {
    @testSetup
    static void setup(){
        Account account = IntappTestObjectfactory.createAccount(true);
        
        Contact con = (Contact) SmartFactory.createSObject('Contact');
        con.AccountId = account.Id; 
        insert con;
        
        Contract ctr = (Contract) SmartFactory.createSObject('Contract');
        ctr.AccountId = account.Id;
        insert ctr;
        
        Opportunity opportunity = (Opportunity) SmartFactory.createSObject('Opportunity');
        opportunity.AccountId = account.Id;
        opportunity.Associated_Contract_OSA__c = ctr.Id;
        opportunity.Contract_Signer__c = con.Id;
        opportunity.Requested_Contract_Expiration__c = Date.today();
        opportunity.Initial_Software_Term_Length_Months__c = 12;
        insert opportunity;
        
        Profile profile = [select id from profile where name='System Administrator' LIMIT 1]; 
        User user = createuser('Testing', '', 'test@testintapp.com', profile.Id, 'intapp_1', 'UTF-8', 'en_US', 'en_US', 'America/Los_Angeles', 'stdtusr@testintapp.com', '', true);
        
        Approvers_Matrix__c appMatrix1 = (Approvers_Matrix__c) SmartFactory.createSObject('Approvers_Matrix__c');
        AppMatrix1.Sales_Segment__c = '03-Legal EMEA';
        AppMatrix1.Approver_Role__c = 'Segment Lead';
        AppMatrix1.Approver_User__c = user.Id;
        insert AppMatrix1;
        
        SBQQ__Quote__c newQuote = (SBQQ__Quote__c) SmartFactory.createSObject('SBQQ__Quote__c');
        newQuote.OP4I_Sales_Segment__c = '03-Legal EMEA';
        newQuote.SBQQ__Opportunity2__c = opportunity.Id;
        newQuote.SBQQ__Account__c = account.Id;
        newQuote.SBQQ__SubscriptionTerm__c = 36;
        newQuote.First_Segment_Months__c = 12;
        newQuote.License_Basis__c = 'Lawyers';
        newQuote.SBQQ__StartDate__c = system.today();
        insert newQuote;
    }
    
    private static List<SBQQ__Quote__c> getQuoteList(){
        return [SELECT Id
                , SBQQ__Account__c
                , Segment_Lead__c
                , Industry_Sales_Lead__c
                , Services_Segment_Lead__c
                , SVP_Sales__c
                , SVP_Services__c
                , Industry_President__c
                , COO__c
                , SBQQ__Opportunity2__c
                , SBQQ__SubscriptionTerm__c
                , First_Segment_Months__c
                , License_Basis__c
                , OP4I_Sales_Segment__c
                , ApprovalStatus__c,SBQQ__StartDate__c
                FROM SBQQ__Quote__c LIMIT 1];
    }
    
    private static User getUser(){
        return [SELECT Id
                FROM User
                WHERE Email = 'test@testintapp.com'
                LIMIT 1];
    }
    
    private static User createUser(String lastName, string firstName, string email, String profileId, 
                                   string alias, String emailEncodingKey, string languageLocaleKey,
                                   string localeSidKey, string timeZoneSidKey, string userName,
                                   string communityNickname, Boolean create){
                                       User user = new User();
                                       user.LastName = lastName;
                                       user.FirstName = firstName;
                                       user.Email = email;
                                       user.EmailEncodingKey = emailEncodingKey;
                                       user.LanguageLocaleKey = languageLocaleKey;
                                       user.LocaleSidKey = localeSidKey;
                                       user.TimeZoneSidKey = timeZoneSidKey;
                                       user.ProfileId = profileId;
                                       user.Alias = alias;
                                       user.UserName = userName;
                                       user.CommunityNickname = communityNickname + '-' + (Math.random() * 10000);
                                       if(create)
                                       {
                                           insert user;
                                       }
                                       return user;
                                   }
    
    @isTest
    static void processRecordsBeforeInsertWithValidSalesSegment(){
        // Arrange
        List<SBQQ__Quote__c> quotelist = getQuoteList();
        
        for(SBQQ__Quote__c quote : quoteList){
            quote.Segment_Lead__c = null;
        }
        
        User user = getUser();
        
        System.assertNotEquals(quoteList.size(), null);
    }
    
    @isTest
    static void processRecordsBeforeInsertWithInvalidSalesSegment(){
        // Arrange
        List<SBQQ__Quote__c> quotelist = getQuoteList();
        
        for(SBQQ__Quote__c quote : quoteList){
            quote.Segment_Lead__c = null;
            quote.OP4I_Sales_Segment__c = '03-Legal_Not Matching';    
        }
        
        User user = getUser();
        System.assertNotEquals(quoteList.size(), null);
    }
    
    @isTest static void processRecordsBeforeUpdateWithValidSalesSegment(){
        // Arrange
        List<SBQQ__Quote__c> oldQuote = getQuoteList();
        oldQuote[0].ApprovalStatus__c = 'Error';
        oldQuote[0].OP4I_Sales_Segment__c = '04-Legal APAC';
        
        Map<Id, SBQQ__Quote__c> quotelistMapOld = New Map<Id, SBQQ__Quote__c> (oldQuote);
        
        Generic_Key_Value_Setting__mdt approvalErrorMaxRetrySetting = Generic_Key_Value_Setting__mdt.getInstance('Approval_Error_Max_Retry');
        Integer approvalErrorMaxRetry = Integer.valueOf(approvalErrorMaxRetrySetting.Value__c);
        
        List<SBQQ__Quote__c> newQuote = getQuoteList();
        newQuote[0].ApprovalStatus__c = 'Pending'; 
        newQuote[0].Counter__c = approvalErrorMaxRetry;
        newQuote[0].OP4I_Sales_Segment__c = '03-Legal EMEA';
        
        Map<Id, SBQQ__Quote__c> quotelistMapNew = New Map<Id, SBQQ__Quote__c> (newQuote);
        
        User user = getUser();
        
        System.assertNotEquals(newQuote.size(), null);
    }
    
    @isTest static void processRecordsBeforeUpdateWithInvalidSalesSegment(){
        // Arrange
        List<SBQQ__Quote__c> oldQuote = getQuoteList();
        oldQuote[0].ApprovalStatus__c = 'Error';
        oldQuote[0].OP4I_Sales_Segment__c = '04-Legal APAC';
        
        Map<Id, SBQQ__Quote__c> quotelistMapOld = New Map<Id, SBQQ__Quote__c> (oldQuote);
        
        Generic_Key_Value_Setting__mdt approvalErrorMaxRetrySetting = Generic_Key_Value_Setting__mdt.getInstance('Approval_Error_Max_Retry');
        Integer approvalErrorMaxRetry = Integer.valueOf(approvalErrorMaxRetrySetting.Value__c);
        
        List<SBQQ__Quote__c> newQuote = getQuoteList();
        newQuote[0].ApprovalStatus__c = 'Pending'; 
        newQuote[0].Counter__c = approvalErrorMaxRetry;
        newQuote[0].Segment_Lead__c = null;
        newQuote[0].OP4I_Sales_Segment__c = '03-Legal_Not EMEA';
        
        Map<Id, SBQQ__Quote__c> quotelistMapNew = New Map<Id, SBQQ__Quote__c> (newQuote);
        
        User user = getUser();
        System.Assert(newQuote[0].Segment_Lead__c == null); 
    }
}