public with sharing class ProductDocsController {
  public String recordLimit{get;set;}
  
  public List<Supported_Environment__kav> getSupportedEnvironments () {
  	//get most recent product of each category
  	Set<String> cat = new Set<String> ();
  	Set<Date> createdDates = new Set<Date> (); 
  	
  	for (AggregateResult ar : [Select product__c, Max(CreatedDate) cDate 
									  	         From Supported_Environment__kav 
									  	         Where publishStatus='Online' 
									             And language='en_US'
									             group by product__c
									             ]) {
  		cat.add(String.valueOf(ar.get('product__c')));
  		createdDates.add(Date.valueOf(ar.get('cDate')));
  	}
  	
  	return [Select Id, r.VersionNumber, r.UrlName, r.Title, r.SourceId, KnowledgeArticleId, 
  	               r.Related_Articles__c, r.PublishStatus, r.Product__c, r.Description__c, r.ArticleNumber 
            From Supported_Environment__kav r 
            Where publishStatus='Online' 
            And language='en_US'
            And product__c in :cat
            And CreatedDate in :createdDates
            Order by CreatedDate desc
            Limit 5];
  }
  
  public List<Release_Note__kav> getReleaseNotes () {
  	//get most recent product of each category
  	Set<String> cat = new Set<String> ();
  	Set<Date> createdDates = new Set<Date> (); 
  	
  	for (AggregateResult ar : [Select product__c, Max(CreatedDate) cDate 
									  	         From Release_Note__kav 
									  	         Where publishStatus='Online' 
									             And language='en_US'
									             group by product__c
									             ]) {
  		cat.add(String.valueOf(ar.get('product__c')));
  		createdDates.add(Date.valueOf(ar.get('cDate')));
  	}
  	
  	return [Select Id, r.Version__c, r.VersionNumber, r.UrlName, r.Title, r.SourceId, KnowledgeArticleId, 
  	               r.Related_Articles__c, r.PublishStatus, r.Product__c, r.Description__c, r.ArticleNumber 
            From Release_Note__kav r 
            Where publishStatus='Online' 
            And language='en_US'
            And product__c in :cat
            And CreatedDate in :createdDates
            Order by CreatedDate desc
            Limit 5];
  }
  
  private static testMethod void testProductController() {
  	
  	Supported_Environment__kav article = new Supported_Environment__kav ();
  	article.title = 'Test Article';
  	article.UrlName = 'Test-Article';
  	article.Language = 'en_US';
  	article.Product__c = 'abc';
  	//article.PublishStatus = 'Online';
  	insert article; 
  	
  	ProductDocsController ctrl = new ProductDocsController();
  	ctrl.recordLimit = '50';
  	ctrl.getSupportedEnvironments();
  	
  	Release_Note__kav article1 = new Release_Note__kav ();
  	article1.title = 'Test Article';
  	article1.UrlName = 'Test-Article-Rel';
  	article1.Language = 'en_US';
  	article1.Product__c = 'abc';
  	//article1.PublishStatus = 'Online';
  	insert article1;
  	ctrl.getReleaseNotes();
  }
  
  
}