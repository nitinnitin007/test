public with sharing class OrderProductTriggerHandler {
    public Static void orderProductAfterUpdate(list<OrderItem> orderProductNewList,Map<Id,OrderItem> orderProductOldMap){
        processEvents(orderProductNewList,orderProductOldMap);
    }

    public static void processEvents(list<OrderItem> orderProductNewList,Map<Id,OrderItem> orderProductOldMap) {
        List<Field_Tracking__mdt> fieldTrackingList = [
            SELECT Field_Api_Name__c
                , Object_Name__c   
            FROM Field_Tracking__mdt
            WHERE Object_Name__c = 'OrderItem'
        ];

        list<OrderItem> orderItemsToProcess = new list<OrderItem>();
        set<Id> orderIds = new set<Id>();
        for (OrderItem orderItem : orderProductNewList) {
            OrderItem orderItemOld = orderProductOldMap != null && orderProductOldMap.containsKey(orderItem.Id)?
            orderProductOldMap.get(orderItem.Id) : new OrderItem();
            if (IntegrationUtility.isChanged(orderItem,orderItemOld,fieldTrackingList)) {
                orderIds.add(orderItem.orderId);
            }
        }

        if (!orderIds.isEmpty()) {
            Schema.SObjectType targetObjType = Schema.getGlobalDescribe().get('Order');
            Map<String, Schema.SObjectField> fieldMap = targetObjType.getDescribe().fields.getMap();
            List<String> fields = new List<String>(fieldMap.keyset());
            String query =
                ' SELECT ' +
                String.join(fields, ',' ) +
                ' FROM ' +
                ' Order' +
                ' WHERE Id IN: orderIds';
            
            query = query.remove('{');
            query = query.remove('}');

            List<Order> orderList = Database.query(query);
            if (!orderList.isEmpty()) {
                OrderTriggerHandler.processEvents(orderList,null,true);
            }
        }
    }
}