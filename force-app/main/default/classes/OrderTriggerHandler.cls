/**
 * @description       : Trigger Handler class for OrderTrigger 
 * @author            : Snehalkumar Choudhary
**/
public class OrderTriggerHandler {
    public static set<Id> publishedOrderIds = new set<Id>();
    /** Method which excutes when an order is updated. Currently sends activated orders and order line items to IntegrationUtility class **/   
    public Static void orderAfterUpdate(list<Order> orderNewList,Map<Id,Order> orderOldMap){
        processNetsuite(orderNewList,orderOldMap);
        processEvents(orderNewList,orderOldMap,true);
    } 

    public static void processNetsuite(list<Order> orderNewList,Map<Id,Order> orderOldMap) {
        list<Order> ordersToProcessList = new list<Order>();
        for (Order order : orderNewList) {
            Order orderOld = orderOldMap != null && orderOldMap.containsKey(order.Id)? orderOldMap.get(order.Id) : new Order();
            if(order.SBQQ__Quote__r.SBQQ__Type__c != 'Migration Quote'){
                if(order.ContractNumber__c != orderOld.ContractNumber__c && order.status == 'Activated' && order.ContractNumber__c != null ) {               
                      ordersToProcessList.add(order);
                }
            }
        }

        if (!ordersToProcessList.isEmpty() && ordersToProcessList.size() > 0) {
            IntegrationHandler.createSignedCustomerFromOrder(ordersToProcessList);
        }

    }

    public static void processEvents(list<Order> orderNewList,Map<Id,Order> orderOldMap,Boolean sendLines) {
        List<Order> orderEligibleList = new List<Order>();
        List<OrderItem> orderItemList = new List<OrderItem>();
        set<Id> setOfOrderIds = new Set<Id>();
        if(!orderNewList.isEmpty()) {
            orderEligibleList = eligibleOrders(orderNewList,orderOldMap);      
            if(!orderEligibleList.isEmpty()) {
                IntegrationUtility.publishsObjectRecords(orderEligibleList,'Order');
                if (sendLines) {
                    Schema.SObjectType targetObjType = Schema.getGlobalDescribe().get('OrderItem');
                    Map<String, Schema.SObjectField> fieldMap = targetObjType.getDescribe().fields.getMap();
                    List<String> fields = new List<String>(fieldMap.keyset());
                    String query =
                        ' SELECT ' +
                        String.join( fields, ',' ) +
                        ' FROM ' +
                        'OrderItem' +
                        ' WHERE ' +
                        ' OrderId IN :orderEligibleList';

                        query = query.remove('{');
                        query = query.remove('}');

                    orderItemList = Database.query(query);        
                    if(!orderItemList.IsEmpty()) {
                        IntegrationUtility.publishsObjectRecords(orderItemList,'OrderItem');
                    }   
                }     
            }
        }
    }
  
    public static List<Order> eligibleOrders(List<Order> orderList,Map<Id,Order> orderOldMap){
        List<Order> orderEligibleList = new List<Order>();
        List<Order> orderUpdatedList = new List<Order>();
        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                             .get('Migration_Opportunity').getRecordTypeId();
         set<Id> setOfOrder = new set<id>();
         for(Order order : orderList)
         {
           setOfOrder.add(order.id);     
         }
        String strQuery = createQuery(setOfOrder);
        List<Order> lstOfOrders = Database.query(strQuery);
        for(Order orderObj : lstOfOrders){
          if(orderObj.Opportunity.RecordTypeId != oppRecordTypeId){
            orderUpdatedList.add(orderObj);  
          }     
        }
        if(!orderUpdatedList.isEmpty()) {
            List<Field_Tracking__mdt> fieldTrackingList = [
                SELECT Field_Api_Name__c
                    , Object_Name__c   
                FROM Field_Tracking__mdt
                WHERE Object_Name__c = 'Order'
            ];
            for(Order orderObj : orderUpdatedList) {
                Order orderOld = orderOldMap != null && orderOldMap.containsKey(orderObj.Id)? orderOldMap.get(orderObj.Id) : new Order();
                if(!publishedOrderIds.contains(orderObj.Id) && orderObj.status == 'Activated' && orderObj.ContractNumber__c!=null 
                    && IntegrationUtility.isChanged(orderObj,orderOld,fieldTrackingList)) {
                    orderEligibleList.add(orderObj);
                    publishedOrderIds.add(orderObj.Id);
                }       
            }    
        } 
        return orderEligibleList; 
    }
    public static string createQuery(set<Id> setOfOrder)
    {
      set<String> fieldNames = new set<String>();
      Schema.SObjectType targetObjType = Schema.getGlobalDescribe().get('Order');
      Map<String, Schema.SObjectField> fieldMap = targetObjType.getDescribe().fields.getMap();
      fieldNames = fieldMap.keyset();
      List<String> fields = new List<String>(fieldNames);
      String query =  ' SELECT ' +
                              String.join( fields, ',' ) + 
                              ',Opportunity.RecordTypeId ' +
                          ' FROM ' +
                              'Order' +
                          ' WHERE ' +
                              ' Id IN: setOfOrder';
                         
      String strQuery1 = query.remove('{');
      String strQuery2 = strQuery1.remove('}'); 
      return strQuery2;
    }  
}