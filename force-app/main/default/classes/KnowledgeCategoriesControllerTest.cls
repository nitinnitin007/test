@IsTest
private class KnowledgeCategoriesControllerTest {
    static testmethod void testGetCategoryItems() {
        KnowledgeCategoryWrapper[] items = KnowledgeCategoriesController.getCategoryItems();
        System.assertNotEquals(null, items);
    }
}