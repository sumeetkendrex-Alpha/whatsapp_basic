public class OrderItemTriggerHandler {
    
    /*
    public static void sendMessageToOwner2(List<OrderItem> newOrderItemList) {
        system.debug('OrderItem Trigger2');
        
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        String messageBody='';
        for (OrderItem orderItem : newOrderItemList) {
            if (orderItem.OrderId != null) {
                orderIds.add(orderItem.OrderId);
            }
        }
        
        List<Order> newOrderList = new List<Order>();
        if (!orderIds.isEmpty()) {
            newOrderList = [SELECT Id, AccountId, OrderNumber, TotalAmount FROM Order WHERE Id IN :orderIds];
        }
        
        for (Order ord : newOrderList) {
            if (ord.AccountId != null && ord.TotalAmount > 0) {
                accountIdSet.add(ord.AccountId);
            }
        }
        
        List<Account> accountList = [SELECT Id, Name, Phone FROM Account WHERE Id IN :accountIdSet];
        Map<Id, Account> accountMap = new Map<Id, Account>(accountList);
        Map<Id,OrderItem> orderItemMap = new Map<Id,OrderItem>([SELECT Id,OrderId,ProductName__c,Quantity,TotalPrice FROM OrderItem WHERE OrderId IN: orderIds]);
        for (Order ord : newOrderList) {
            if (ord.AccountId != null && accountMap.containsKey(ord.AccountId)) {
                Account acc = accountMap.get(ord.AccountId);
                for(Id ordItem : orderItemMap.keySet()){
                    if(orderItemMap.get(ordItem).OrderId == ord.Id){
                        messageBody += '• Product Name: ' + orderItemMap.get(ordItem).ProductName__c +'-';  
                        messageBody += 'Quantity: ' + orderItemMap.get(ordItem).Quantity + '-';      
                        messageBody += 'Total Price: ' + orderItemMap.get(ordItem).TotalPrice + ', ';
                    }
                }
                 
                String msgBody = '{"messaging_product":"whatsapp","to":"'+acc.Phone+'","type":"template","template":{"name":"crm_orderu_summry","language":{"code":"en"},"components":[{"type":"body","parameters":[{"type":"text","text":"'+acc.Name+'"},{"type":"text","text":"'+ord.OrderNumber+'"},{"type":"text","text":"'+messageBody+'"},{"type":"text","text":"'+ord.TotalAmount+'"},{"type":"text","text":"'+System.now()+'"}]}]}}';
                
                String calloutString = acc.Phone + '@@' + '918233354537' + '@@' + msgBody + '@@' + 'summeryTemplate' + '@@' + ord.OrderNumber + '@@' + ''+'@@'+acc.Name;
                system.debug('Callout String Order ==> ' + calloutString);
                WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
            }
        }
    } */
    
    public static void sendMessageToOwner2(List<OrderItem> newOrderItemList) {
    system.debug('OrderItem Trigger2');
    
    Set<Id> accountIdSet = new Set<Id>();
    Set<Id> orderIds = new Set<Id>();

    for (OrderItem orderItem : newOrderItemList) {
        if (orderItem.OrderId != null) {
            orderIds.add(orderItem.OrderId);
        }
    }
    system.debug('orderIds==>'+orderIds);
    List<Order> newOrderList = new List<Order>();
    if (!orderIds.isEmpty()) {
        newOrderList = [SELECT Id, AccountId, OrderNumber, TotalAmount FROM Order WHERE Id IN :orderIds];
    }
        system.debug('newOrderList==>'+newOrderList);

    for (Order ord : newOrderList) {

        if (ord.AccountId != null) {
            accountIdSet.add(ord.AccountId);
        }
    }
            system.debug('accountIdSet==>'+accountIdSet);

    
    List<Account> accountList = [SELECT Id, Name, Phone FROM Account WHERE Id IN :accountIdSet];
    Map<Id, Account> accountMap = new Map<Id, Account>(accountList);
    Map<Id, List<OrderItem>> orderIdToOrderItems = new Map<Id, List<OrderItem>>();
            system.debug('accountIdSet==>'+accountList);

    for (OrderItem oi : [SELECT Id, OrderId, ProductName__c, Quantity, TotalPrice FROM OrderItem WHERE OrderId IN :orderIds]) {
        if (!orderIdToOrderItems.containsKey(oi.OrderId)) {
            orderIdToOrderItems.put(oi.OrderId, new List<OrderItem>());
        }
        orderIdToOrderItems.get(oi.OrderId).add(oi);
    }

    for (Order ord : newOrderList) {
        if (ord.AccountId != null && accountMap.containsKey(ord.AccountId)) {
            Account acc = accountMap.get(ord.AccountId);
           
          
           String messageBody = 'Hello ' + acc.Name +' Thank you for placing your order'+ '\\n\\n';
             messageBody += 'Order Summary for Order #: ' + ord.OrderNumber + '\\n';

            if (orderIdToOrderItems.containsKey(ord.Id)) {
                for (OrderItem oi : orderIdToOrderItems.get(ord.Id)) {
                    messageBody += '• Product Name: ' + oi.ProductName__c + '\\n';
                    messageBody += '  Quantity: ' + oi.Quantity + '\\n';
                    messageBody += '  Total Price: ' + oi.TotalPrice + '\\n\\n';
                }
            }
            
                         messageBody += 'We have received it and will begin processing shortly.';


            System.debug(messageBody);
            
         //   String msgBody = 'Hello '+ msg.CustomerName__c + '\\n\\n Thank you for placing your order. We have received it and will begin processing shortly.';
                   String calloutString = acc.Phone + '@@' + '918233354537' + '@@' + messageBody + '@@' +'text' + '@@' + null + '@@' + null + '@@' + acc.Name;
                    WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
        }
    }
}

}