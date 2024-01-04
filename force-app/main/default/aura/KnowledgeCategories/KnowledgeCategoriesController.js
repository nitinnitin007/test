({
    doInit: function(cmp, event, helper){
        helper.retrieveCategoryItems(cmp);
    },

    clearCategoryFilters: function(cmp){
        var cmpEvent = cmp.getEvent('knowledgeCategoryResetInner');
        cmpEvent.fire();
        cmp.set('v.categoriesOpened', true);
    },

    handleCategoryClicked: function(cmp, event, helper){
        cmp.set('v.categoriesOpened', true);
    },

    updateCategoryItems: function(cmp, event, helper){
        var categoryItems = cmp.get('v.categoryItems'),
            filters = cmp.get('v.filters'),
            filterCategories = filters.category ? filters.category : [];

        for(var i=0;i<categoryItems.length;i+=1){
            if(categoryItems[i].Children && categoryItems[i].Children.length > 0){
                helper.updateCategoryChildItems(categoryItems[i].Children, filterCategories);
            }
        }

        cmp.set('v.categoryItems', categoryItems);
    },

    toggleCategories: function(cmp){
        var categoriesOpened = cmp.get('v.categoriesOpened');

        if(categoriesOpened){
            cmp.set('v.categoriesOpened', false);
        } else {
            cmp.set('v.categoriesOpened', true);
        }
    }
})