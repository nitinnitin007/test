public with sharing class ArticlesController {

	public List <KnowledgeArticleVersion> getArticles() {
		Set<ID> Ids = new Set<ID>();
		for(KnowledgeArticleViewStat a : [SELECT ParentId FROM KnowledgeArticleViewStat ORDER BY ViewCount DESC NULLS LAST LIMIT 100]){
			Ids.add(a.ParentId);
		}

		return [	Select k.Id, k.UrlName, k.ArticleType, k.Title, k.KnowledgeArticleId 
							From KnowledgeArticleVersion k 
							Where (KnowledgeArticleId IN : Ids AND PublishStatus = 'Online')
							Limit 10];
	}
}