public with sharing class KnowledgeCategoriesController {

    @AuraEnabled
    public static KnowledgeCategoryWrapper[] getCategoryItems() {

        KnowledgeCategoryWrapper[] items = new List<KnowledgeCategoryWrapper>();
/*
        KnowledgeCategoryWrapper item;

        List<String> objType = new List<String>();
        objType.add('KnowledgeArticleVersion');

        List<DescribeDataCategoryGroupResult> category_groups = Schema.describeDataCategoryGroups(objType);
        List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();
        List<DescribeDataCategoryGroupStructureResult> category_struct_res;

        for(DescribeDataCategoryGroupResult group_res : category_groups){
            DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
            p.setSobject(group_res.getSobject());
            p.setDataCategoryGroupName(group_res.getName());
            pairs.add(p);
        }

        category_struct_res = Schema.describeDataCategoryGroupStructures(pairs, false);

        for(DescribeDataCategoryGroupStructureResult struct : category_struct_res){
            item = new KnowledgeCategoryWrapper();
            item.Name = struct.getName();
            item.Label = struct.getLabel();
            item.ArticleCount = 0;

            DataCategory[] top_categories = struct.getTopCategories();
            item.Children = KnowledgeCategoriesController.getAllCategories(top_categories[0], item.name);
            item.selected = false;

            items.add(item);
        }
*/
        return items;
    }

/*
    public static KnowledgeCategoryWrapper[] getAllCategories(DataCategory root_category, String group_name){
        KnowledgeCategoryWrapper[] items = new List<KnowledgeCategoryWrapper>();
        KnowledgeCategoryWrapper item;

        DataCategory[] children = root_category.getChildCategories();

        for(DataCategory ch : children){
            item = new KnowledgeCategoryWrapper();
            item.Name = group_name +'__c:'+ ch.getName() +'__c';
            item.Label = ch.getLabel();
            item.ArticleCount = 0;
            item.Children = KnowledgeCategoriesController.getAllCategories(ch, group_name);
            item.selected = false;

            items.add(item);
        }

        return items;
    }
*/
}