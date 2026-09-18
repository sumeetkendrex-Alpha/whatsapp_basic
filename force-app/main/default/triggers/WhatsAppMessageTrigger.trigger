trigger WhatsAppMessageTrigger on WhatsApp_Message__c (before insert,after insert,before Update,after Update) {
    
    if(Trigger.isBefore && TRigger.isInsert){
        WhatsAppMessageTriggerHandler.findRealtedRecord(Trigger.new);
        
        //WhatsAppMessageTriggerHandler.SendWelcomeMessage(Trigger.New);
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        system.debug('Triggerd in after Insert');
        Set<Id> msgIdsbatch = new Set<Id>();
        Set<Id> msgIdOrder = new Set<Id>();//Order Ke liye
        
        for (WhatsApp_Message__c msg : Trigger.New) {
            if (msg.MessageSendType__c == 'Inbound') {
                msgIdsbatch.add(msg.Id);
            }
            
            if(msg.MessageSendType__c == 'Inbound' && msg.MessageType__c=='order' && msg.OrderDetail__c != null){
                msgIdOrder.add(msg.Id);
            }
        }
        if(!msgIdsbatch.isEmpty()){
            //ChampranWhatsapp.SendWelcomeMessage(msgIdsbatch);
                       Vadilal.handleMessage(msgIdsbatch);

            //  WhatsAppMessageTriggerHandler.SendWelcomeMessage(msgIdsbatch);
            
        }
        if(!msgIdOrder.isEmpty()){
         WhatsAppMessageTriggerHandlerOrder.CreateOrder(msgIdOrder);
            
        }
        
        
        WhatsAppMessageTriggerHandler.latestMessageId(Trigger.New);
        
        Set<Id> msgIds = new Set<Id>();
        for (WhatsApp_Message__c msg : Trigger.New) {
            if (msg.MessageSendType__c == 'Outbound' && msg.MessageType__c == 'template' && msg.TemplateName__c != null) {
                msgIds.add(msg.Id);
            }
        }
        
        if (!msgIds.isEmpty()) {
            System.enqueueJob(new FetchTemplateDetailQueueable(msgIds));
        }
        
        
    }
    
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        Set<Id> newIds = new Set<Id>();
        for (WhatsApp_Message__c msg : Trigger.New) {
            if (msg.MessageSendType__c == 'Inbound' && msg.MessageID__c != null && msg.ViewedByAgent__c == true) {
                newIds.add(msg.Id);
            }
        }
        // WhatsAppMessageTriggerHandler.sendTypingIndicator(newIds);
    }
    
}