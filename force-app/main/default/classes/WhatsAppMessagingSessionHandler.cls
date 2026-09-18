public class WhatsAppMessagingSessionHandler {
    public static void sendImages(Set<Id> ids) {
        List<WhatsAppMessagingSession__c> sessions = [SELECT Id, CustomerName__c, CustomerPhone__c, BusinessPhoneNumber__c FROM WhatsAppMessagingSession__c
                                                      WHERE Id IN :ids];
        Map<Id, WhatsAppMessagingSession__c> mapSession = new Map<Id, WhatsAppMessagingSession__c>(sessions);
        
        String msgBody = 'Links';
        
        for (Id sessionId : mapSession.keySet()) {
            WhatsAppMessagingSession__c session = mapSession.get(sessionId);
            if (session.CustomerPhone__c == null || session.BusinessPhoneNumber__c == null || session.CustomerName__c == null) {
                System.debug('Skipping session due to missing required fields: ' + sessionId);
                continue;
            }
            String calloutString = session.CustomerPhone__c + '@@' +session.BusinessPhoneNumber__c + '@@' +msgBody + '@@' +'image' + '@@' +null + '@@' +null + '@@' +session.CustomerName__c;
            System.debug('MessagingSession Handler Callout ==> ' + calloutString);
            WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
        }
    }
}