trigger WhatsAppUserTrigger on WhatsappUser__c (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        WhatsappUserHandler.handleBeforeInsert(Trigger.new);
        
       //WhatsappUserHandler.handleSendMessage(Trigger.new);
        
    }
}