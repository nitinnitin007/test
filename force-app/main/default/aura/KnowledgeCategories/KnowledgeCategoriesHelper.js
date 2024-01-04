({

    retrieveCategoryItems: function (cmp) {
        var action = cmp.get('c.getCategoryItems');

        //cmp.set('v.listItems', []);

        action.setCallback(this, function(response){
            var state = response.getState(),
                resVal = response.getReturnValue();

            if (state === 'SUCCESS') {
                cmp.set('v.categoryItems', resVal);
            }
        });
        $A.enqueueAction(action);
    },

    updateCategoryChildItems: function(childItems, filterCategories){

        for(var i=0;i<childItems.length;i+=1){
            if(this.inArray(filterCategories, childItems[i].Name)){
                childItems[i].selected = true;
            } else {
                childItems[i].selected = false;
            }

            if(childItems[i].Children && childItems[i].Children.length > 0){
                this.updateCategoryChildItems(childItems[i].Children, filterCategories);
            }
        }
    },

    inArray: function(arr, val) {
        return arr.some(function(arrVal) {
            return val === arrVal;
        });
    }
})