public class WhatsAppMessageTemplateHandler {
    public static void templateSend(List<WhatsApp_Message__c> newMessages) {
        List<WhatsApp_Message__c> oldList = [SELECT Id, MessageID__c, MessageType__c, MessageSendType__c, ParentMessageID__c
                                             FROM WhatsApp_Message__c
                                             WHERE MessageSendType__c = 'Outbound' ORDER BY CreatedDate DESC];
        
        Set<String> oldMessageIDs = new Set<String>();
        for (WhatsApp_Message__c oldMessage : oldList) {
            oldMessageIDs.add(oldMessage.MessageID__c);
        }
        
        for (WhatsApp_Message__c newMessage : newMessages) {
            if (oldMessageIDs.contains(newMessage.ParentMessageID__c)) {
                System.debug('New message is a child of an old message: ' + newMessage);
            } else {
                System.debug('New message is not a child of any old message: ' + newMessage);
            }
        }
        
        
        
    }
    
    public static void sendTemplate(Set<Id> msgIds) {
        List<WhatsApp_Message__c> NewList = [SELECT Id,BusinessPhoneNumber__c,CustomerName__c,TemplateButtonPayload__c,OrderNumber__c,TemplateButtonText__c,Account__c, MessageID__c,CustomerPhone__c, MessageType__c, MessageSendType__c, ParentMessageID__c,MessageContent__c
                                             FROM WhatsApp_Message__c
                                             WHERE Id =:msgIds ];
        
        For(WhatsApp_Message__c msg : NewList){
            if(msg.MessageContent__c =='Hi'||msg.MessageContent__c =='Hello'){
                if(msg.Account__c != null){
                    String calloutString = msg.CustomerPhone__c+'@@'+msg.BusinessPhoneNumber__c+'@@'+''+'@@'+'templateCatalog'+'@@'+'068dM000006KpVyQAK'+'@@'+null+'@@'+msg.CustomerName__c;
                    WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                    calloutString = msg.CustomerPhone__c+'@@'+msg.BusinessPhoneNumber__c+'@@'+'crm_support'+'@@'+'interactive'+'@@'+'068dM000006KpVyQAK'+'@@'+null+'@@'+msg.CustomerName__c;
                    WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                } else{
                    String calloutString = msg.CustomerPhone__c+'@@'+msg.BusinessPhoneNumber__c+'@@'+''+'@@'+'template'+'@@'+'068dM000006KpVyQAK'+'@@'+null+'@@'+msg.CustomerName__c;
                    WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                }
            }
        }
    }
    
    public static void updateOrderStatus(Set<Id> msgIds) {
        List<WhatsApp_Message__c> NewList = [SELECT Id,BusinessPhoneNumber__c,TemplateButtonPayload__c,OrderNumber__c,TemplateButtonText__c,Account__c, MessageID__c,CustomerPhone__c, MessageType__c, MessageSendType__c, ParentMessageID__c,MessageContent__c
                                             FROM WhatsApp_Message__c
                                             WHERE Id =:msgIds ];
        System.debug('NewList ==> '+NewList);
        List<String> ordersToUpdate = new List<String>();
        List<String> ordersToCancel = new List<String>();
        Set<String> parentIdSet = new Set<String>();
        Map<String,Whatsapp_Message__c> newMapWithParentId = new Map<String, Whatsapp_Message__c>();
        for(Whatsapp_Message__c msg : NewList){
            if(msg.ParentMessageID__c != null){
                parentIdSet.add(msg.ParentMessageID__c);
            }
        }
        System.debug('newMapWithParentId ==> '+newMapWithParentId);
        Map<Id,WhatsApp_Message__c> oldMap = new Map<Id,WhatsApp_Message__c>([SELECT Id,BusinessPhoneNumber__c,TemplateButtonPayload__c,OrderNumber__c,TemplateButtonText__c,Account__c, MessageID__c,CustomerPhone__c, MessageType__c, MessageSendType__c, ParentMessageID__c,MessageContent__c
                                             FROM WhatsApp_Message__c
                                             WHERE MessageID__c IN :parentIdSet ]);
        System.debug('oldMap ==> '+oldMap);
        for(WhatsApp_Message__c wMsg : oldMap.values()){
            newMapWithParentId.put(wMsg.MessageID__c, wMsg);
        }
         System.debug('newMapWithParentId ==>'+newMapWithParentId );
        For(WhatsApp_Message__c msg : NewList){
            if(msg.TemplateButtonPayload__c =='Confirm Order' && msg.TemplateButtonText__c == 'Confirm Order' && msg.ParentMessageID__c != null){
                             System.debug('Place Orde');

                if(newMapWithParentId.containsKey(msg.ParentMessageID__c)){
                                                 System.debug('Hey');
                                                 System.debug('Hey222==>'+newMapWithParentId.get(msg.ParentMessageID__c).OrderNumber__c);

                    ordersToUpdate.add(newMapWithParentId.get(msg.ParentMessageID__c).OrderNumber__c);
                    System.debug('newMapWithParentId.get(msg.ParentMessageID__c).OrderNumber__c1 ==> '+newMapWithParentId.get(msg.ParentMessageID__c).OrderNumber__c);
                }
            }else if(msg.TemplateButtonPayload__c =='Cancel Order' && msg.TemplateButtonText__c == 'Cancel Order' && msg.ParentMessageID__c != null){
             System.debug('msg.ParentMessageID__c==>'+msg.ParentMessageID__c);
                 if(newMapWithParentId.containsKey(msg.ParentMessageID__c)){
                  System.debug('Status==>'+true);
                    ordersToCancel.add(newMapWithParentId.get(msg.ParentMessageID__c).OrderNumber__c);
                     System.debug('newMapWithParentId.get(msg.ParentMessageID__c).OrderNumber__c ==> '+newMapWithParentId.get(msg.ParentMessageID__c).OrderNumber__c);
                }
            }
        }
        System.debug('ordersToUpdate ==> '+ordersToUpdate);
        System.debug('ordersToCancel ==> '+ordersToCancel);
        String msgBody;
        Account AccountNumber;
        if(!ordersToUpdate.isEmpty()){
        System.debug('ordersToUpdate==>'+ordersToUpdate);
            List<Order> ordersForUpdate = [SELECT Id,AccountId,Account.Phone,Account.Name, OrderNumber FROM Order WHERE OrderNumber IN: ordersToUpdate];
            System.debug('ordersForUpdate ==>'+ordersForUpdate );
            if(!ordersForUpdate.isEmpty()){
            System.debug('ordersForUpdate ==>'+ordersForUpdate );
                for(Order ord : ordersForUpdate){
                    ord.Status = 'Order Confirmed';
                    msgBody = '{"messaging_product":"whatsapp","to":"'+ord.account.Phone+'","type":"template","template":{"name":"crm_order_thankyou","language":{"code":"en"},"components":[{"type":"body","parameters":[{"type":"text","text":"'+ord.Account.Name+'"},{"type":"text","text":"'+ord.OrderNumber+'"}]}]}}';
					AccountNumber = ord.account;
                }
                
                update ordersForUpdate;
                
                String calloutString = AccountNumber.Phone + '@@' + '918233354537' + '@@' + msgBody + '@@' + 'summeryTemplate' + '@@' + null + '@@' + ''+'@@'+AccountNumber.Name;
                system.debug('Callout String Order ==> ' + calloutString);
                WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
            }
        }
        
        if (!ordersToCancel.isEmpty()) {
    System.debug('ordersToCancel ==>' + ordersToCancel);
    
    List<Order> ordersForUpdate = [SELECT Id, AccountId,Account.Phone,Account.Name, OrderNumber, Status FROM Order WHERE OrderNumber IN :ordersToCancel];
    System.debug('ordersForUpdate ==>' + ordersForUpdate);
    
    if (!ordersForUpdate.isEmpty()) {
        for (Order ord : ordersForUpdate) {
            ord.Status = 'Draft';
            msgBody = '{"messaging_product":"whatsapp","to":"'+ord.account.Phone+'","type":"template","template":{"name":"crm_order_cancel","language":{"code":"en"},"components":[{"type":"body","parameters":[{"type":"text","text":"'+ord.Account.Name+'"},{"type":"text","text":"'+ord.OrderNumber+'"},{"type":"text","text":"CRM Landing Software PVT. LTD."}]}]}}';
			AccountNumber = ord.account;
        }
        update ordersForUpdate;
        
        List<OrderItem> relatedOrderItems = [SELECT Id FROM OrderItem WHERE OrderId IN :ordersForUpdate];
        if (!relatedOrderItems.isEmpty()) {
            delete relatedOrderItems;
        }
        
        delete ordersForUpdate;
        String calloutString = AccountNumber.Phone + '@@' + '918233354537' + '@@' + msgBody + '@@' + 'summeryTemplate' + '@@' + null + '@@' + ''+'@@'+AccountNumber.Name;
                system.debug('Callout String Order ==> ' + calloutString);
                WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
    }
}

        
    }

    
    
}