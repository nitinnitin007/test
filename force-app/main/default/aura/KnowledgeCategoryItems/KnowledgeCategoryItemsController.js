({
    filterByCategory: function(cmp, event){
        var targetEl = event.currentTarget,
            categoryClicked = targetEl.dataset.id,
            cmpEvent = cmp.getEvent('knowledgeCategoryClickedInner');

        cmpEvent.setParam("categoryName", categoryClicked);
        cmpEvent.fire();
    }
})