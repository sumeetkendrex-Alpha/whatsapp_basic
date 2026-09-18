global class WhatsappMessageSessionBatchable implements Database.Batchable<sObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, BusinessPhoneNumber__c, CustomerPhone__c, Status__c, EndTIme__c ' +
            'FROM WhatsAppMessagingSession__c ' +
            'WHERE Status__c = \'Active\'';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<WhatsAppMessagingSession__c> scope) {
        System.debug('Batch execute called with scope size: ' + scope.size());
        
        List<WhatsAppMessagingSession__c> sessionsToUpdate = new List<WhatsAppMessagingSession__c>();
        
        for (WhatsAppMessagingSession__c session : scope) {
            if (session.BusinessPhoneNumber__c != null && 
                session.CustomerPhone__c != null && 
                session.Status__c == 'Active' && 
                (session.EndTIme__c == null || session.EndTIme__c <= System.now())) {
                    
                    session.Status__c = 'Ended';
                    sessionsToUpdate.add(session);
                }
            
        }
        
        if (!sessionsToUpdate.isEmpty()) {
            update sessionsToUpdate;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('Batch job finished.');
    }
}