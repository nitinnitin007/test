@isTest
public class CreateContractFromQuoteControllerTest { 
    @testSetup
    static void setupTestData(){
        Account acc = (Account) SmartFactory.createSObject('Account');
		acc.Industry = 'Test Industry';
		acc.BillingCountry = 'Test';
        acc.OP4I_Sales_Segment__c = '03-Legal EMEA';
        insert acc;

		Contact con = (Contact) SmartFactory.createSObject('Contact');
		con.AccountId = acc.Id;
		insert con;

		Opportunity opp = (Opportunity) SmartFactory.createSObject('Opportunity');
		opp.AccountId = acc.Id;
		opp.Contract_Signer__c = con.Id;
		opp.Requested_Contract_Expiration__c = Date.today();
		opp.Initial_Software_Term_Length_Months__c = 12;
		insert opp;
        
       /* Approvers_Matrix__c AppMatrix1 = (Approvers_Matrix__c) SmartFactory.createSObject('Approvers_Matrix__c');
        AppMatrix1.Sales_Segment__c ='03-Legal EMEA';
        AppMatrix1.Approver_Role__c ='Segment Lead';
        AppMatrix1.Approver_User__c =userinfo.getUserId();
        insert AppMatrix1; */
     
		SBQQ__Quote__c newQuote = (SBQQ__Quote__c) SmartFactory.createSObject('SBQQ__Quote__c');
		newQuote.SBQQ__Opportunity2__c = opp.Id;
		newQuote.SBQQ__Account__c = acc.Id;
        newQuote.SBQQ__SubscriptionTerm__c =36;
        newQuote.First_Segment_Months__c = 12;
		newQuote.License_Basis__c = 'Lawyers';
        insert newQuote;
    }
    @isTest 
    static void TestCreateContractFromQuote_NewContract() {
        // Arrange
        List<SBQQ__Quote__c> quoteList = [Select id
                                          ,Name 
                                          From SBQQ__Quote__c];
        
        PageReference pageRef = Page.CreateContractFromQuote; 
		pageRef.getParameters().put('id', quoteList[0].Id);
		Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc;
     	CreateContractFromQuoteController createContract = New CreateContractFromQuoteController(sc); 
        
        // Act
		Test.startTest();
        createContract.createContractOnQuote();
        createContract.goBack();
        Test.stopTest(); 
        
		// Assert
        system.Assert(createContract.isError == false);
     }

    @isTest 
    static void TestCreateContractFromQuote_ExstingContract() {
        // Arrange
        List<SBQQ__Quote__c> quoteList = [Select id
                                          ,Name
                                          ,SBQQ__Account__c
                                          ,SBQQ__Opportunity2__c
                                          ,SBQQ__MasterContract__c
                                          From SBQQ__Quote__c];
        
        if (quoteList[0].SBQQ__MasterContract__c == null){
            Contract contract = new Contract(SBQQ__Quote__c = quoteList[0].Id, AccountId = quoteList[0].SBQQ__Account__c, SBQQ__Opportunity__c = quoteList[0].SBQQ__Opportunity2__c);
            insert contract;
            quoteList[0].SBQQ__MasterContract__c = contract.Id;
            update quoteList[0];
        }
        
        PageReference pageRef = Page.CreateContractFromQuote; 
        pageRef.getParameters().put('id', quoteList[0].Id);
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc;
        CreateContractFromQuoteController createContract = New CreateContractFromQuoteController(sc); 
        
        // Act
        Test.startTest();
        createContract.createContractOnQuote();
        Test.stopTest(); 
        
		// Assert
        system.Assert(createContract.isError == false);        
    }
	@isTest 
    static void TestCreateContractFromQuoteException() {
        // Arrange
        PageReference pageRef = Page.CreateContractFromQuote; 
		pageRef.getParameters().put('id', null);
		Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc;
     	CreateContractFromQuoteController createContract = New CreateContractFromQuoteController(sc);
        
        //Act
        Test.startTest();
        createContract.createContractOnQuote();
        Test.stopTest(); 

		// Assert
        system.Assert(createContract.isError == true);        
    }
}