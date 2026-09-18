public class ChatConversationController {
     @AuraEnabled
    public static List<WhatsappUser__c> getWhatsAppUser(String recordId, String businessNumber) {
        
        return [select Id,BusinessNumber__c, CustomerName__c, CustomerPhone__c, latestDateTime__c from WhatsappUser__c 
                 WHERE Id=:recordId AND BusinessNumber__c=:businessNumber];
    }
    @AuraEnabled
    public static List<WhatsApp_Message__c> getWhatsAppMessages(String recordId, String businessNumber) {
        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Record ID cannot be null or empty.');
        }
        System.debug('recordId==>'+recordId);
        System.debug('businessNumber==>'+businessNumber);
        String objectType = recordId.substring(0, 3); 
        String phoneNumber = null;
        
        if (Schema.SObjectType.Lead.getKeyPrefix() == objectType) {
            Lead leadRecord = [SELECT Phone FROM Lead WHERE Id = :recordId LIMIT 1];
            phoneNumber = leadRecord.Phone;
        } else if (Schema.SObjectType.Account.getKeyPrefix() == objectType) {
            Account accountRecord = [SELECT Phone FROM Account WHERE Id = :recordId LIMIT 1];
            phoneNumber = accountRecord.Phone;
        } else if (Schema.SObjectType.Contact.getKeyPrefix() == objectType) {
            Contact contactRecord = [SELECT Phone FROM Contact WHERE Id = :recordId LIMIT 1];
            phoneNumber = contactRecord.Phone;
        }else if (Schema.SObjectType.WhatsappUser__c.getKeyPrefix() == objectType) {
            WhatsappUser__c chatRecord = [SELECT CustomerPhone__c FROM WhatsappUser__c WHERE Id = :recordId LIMIT 1];
            phoneNumber = chatRecord.CustomerPhone__c;
        } else {
            throw new AuraHandledException('Invalid record type. Only Lead, Account, or Contact are supported.');
        }
        
        if (String.isBlank(phoneNumber)) {
            throw new AuraHandledException('No phone number associated with the provided record.');
        }

            List<WhatsApp_Message__c> listToReturn =  [
            SELECT Id,BusinessPhoneNumber__c, MessageSendType__c, MessageContent__c,MediaId__c, MessageSentTime__c, CustomerName__c, ViewedByAgent__c,
            CreatedDate, MessageType__c, MediaLink__c, CustomerPhone__c, TemplateButtonText__c, TemplateName__c,MessageStatus__c,ConversationExpiration__c,ConversationOrigin__c,PricingBillable__c,PricingCategory__c,PricingModel__c, 
            Reaction__c, Owner.Name
            FROM WhatsApp_Message__c
            WHERE CustomerPhone__c = :phoneNumber AND BusinessPhoneNumber__c=:businessNumber
            ORDER BY CreatedDate ASC
        ];
        
		List<WhatsApp_Message__c> listToUpdate = new List<WhatsApp_Message__c>();
        for(WhatsApp_Message__c wmsg : listToReturn){
            if(wmsg.MessageSendType__c == 'Inbound' && wmsg.ViewedByAgent__c == true){
                listToUpdate.add(wmsg);
            }
           // wmsg.ViewedByAgent__c = false;
        }
        
        if(!listToUpdate.isEmpty()){
            System.debug('listToUpdate==>'+listToUpdate);
            update listToUpdate;
            WhatsAppRequestController.refreshLwcCmpChatsWithoutNotify();
        }
        return listToReturn;
    }
    
      @AuraEnabled
    public static List<WhatsAppMessagingSession__c > getMessagingSessions (String recordId){
        system.debug('recordId for Session==>'+recordId);

       WhatsappUser__c wpUser =[select  Id, BusinessNumber__c, CustomerName__c, CustomerPhone__c, latestDateTime__c from WhatsappUser__c WHERE ID=:recordId];
        return[select Id, Status__c, CustomerName__c, CustomerPhone__c, BusinessPhoneNumber__c
               from WhatsAppMessagingSession__c WHERE CustomerPhone__c =:wpUser.CustomerPhone__c AND BusinessPhoneNumber__c=:wpUser.BusinessNumber__c
               ORDER BY CreatedDate DESC
               LIMIT 1];
    }
}