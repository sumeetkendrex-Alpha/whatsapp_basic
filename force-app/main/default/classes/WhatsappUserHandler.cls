public class WhatsappUserHandler {
    
    public static void handleBeforeInsert(List<WhatsappUser__c> newRecords) {
        Set<String> customerPhones = new Set<String>();
        Set<String> uniqueKeysToCheck = new Set<String>();
        
        for (WhatsappUser__c record : newRecords) {
            if (record.CustomerPhone__c != null && record.BusinessNumber__c != null) {
                String key = record.CustomerPhone__c + '_' + record.BusinessNumber__c;
                uniqueKeysToCheck.add(key);
                customerPhones.add(record.CustomerPhone__c);
            }
        }
        
        List<WhatsappUser__c> existingRecords = [SELECT Id, CustomerPhone__c, BusinessNumber__c FROM WhatsappUser__c WHERE CustomerPhone__c IN :customerPhones];
        
        Set<String> existingKeys = new Set<String>();
        for (WhatsappUser__c existing : existingRecords) {
            if (existing.CustomerPhone__c != null && existing.BusinessNumber__c != null) {
                String key = existing.CustomerPhone__c + '_' + existing.BusinessNumber__c;
                existingKeys.add(key);
            }
        }
        
        for (WhatsappUser__c record : newRecords) {
            if (record.CustomerPhone__c != null && record.BusinessNumber__c != null) {
                String key = record.CustomerPhone__c + '_' + record.BusinessNumber__c;
                if (existingKeys.contains(key)) {
                    record.addError('This customer phone already exists for the same business. Duplicate not allowed.');
                }
            }
        }
    }
    
    
    
 /*   public static void handleSendMessage(List<WhatsappUser__c> newRecords) {
        system.debug('Test1===>');
        // Sets to hold unique phone numbers
        Set<String> customerPhones = new Set<String>();
        Set<String> businessNumbers = new Set<String>();
        
        // Unique key map: "customerPhone::businessNumber"
        Set<String> uniqueKeys = new Set<String>();
        Map<String, WhatsappUser__c> keyToUserMap = new Map<String, WhatsappUser__c>();
        
        for (WhatsappUser__c user : newRecords) {
            if (String.isNotBlank(user.CustomerPhone__c) && String.isNotBlank(user.BusinessNumber__c)) {
                String key = user.CustomerPhone__c + '::' + user.BusinessNumber__c;
                uniqueKeys.add(key);
                keyToUserMap.put(key, user);
                
                customerPhones.add(user.CustomerPhone__c);
                businessNumbers.add(user.BusinessNumber__c);
            }
        }
                system.debug('Test2===>');

        List<WhatsappUser__c> existingUsers = [SELECT Id, CustomerPhone__c, BusinessNumber__c FROM WhatsappUser__c 
                                               WHERE CustomerPhone__c IN :customerPhones AND BusinessNumber__c IN :businessNumbers];
        
        Set<String> existingUserKeys = new Set<String>();
        for (WhatsappUser__c user : existingUsers) {
            String key = user.CustomerPhone__c + '::' + user.BusinessNumber__c;
            existingUserKeys.add(key);
        }
        
        List<WhatsApp_Message__c> messages = [SELECT Id, CustomerPhone__c, BusinessPhoneNumber__c, MessageSendType__c
                                              FROM WhatsApp_Message__c
                                              WHERE CustomerPhone__c IN :customerPhones AND BusinessPhoneNumber__c IN :businessNumbers];
        
        Map<String, List<WhatsApp_Message__c>> keyToMessages = new Map<String, List<WhatsApp_Message__c>>();
        for (WhatsApp_Message__c msg : messages) {
            String key = msg.CustomerPhone__c + '::' + msg.BusinessPhoneNumber__c;
            if (!keyToMessages.containsKey(key)) {
                keyToMessages.put(key, new List<WhatsApp_Message__c>());
            }
            keyToMessages.get(key).add(msg);
        }
        
        for (String key : uniqueKeys) {
            Boolean userExists = existingUserKeys.contains(key);
            List<WhatsApp_Message__c> msgs = keyToMessages.get(key);
            Boolean hasInbound = false;
            
            if (msgs != null) {
                for (WhatsApp_Message__c m : msgs) {
                    if (m.MessageSendType__c == 'Inbound') {
                        hasInbound = true;
                        break;
                    }
                }
            }
            
            if (!userExists) {
                if (hasInbound) {
                    System.debug('Inbound message exists for new user: ' + key);
                    List<String> parts = key.split('::');
                    String customerPhone = parts.size() > 0 ? parts[0] : '';
                    String businessNumber = parts.size() > 1 ? parts[1] : '';
                    
                    WhatsappUser__c user = keyToUserMap.get(key);
                    String customerName = user != null ? user.CustomerName__c : '';
                    String msgBody = '{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+customerPhone+'","type":"template","template":{"name":"welcome_newcustomer","language":{"code":"en"},"components":[{"type":"body","parameters":[{"type":"text","text":"'+customerName+'"}]}]}}';
                    String calloutString = customerPhone + '@@' + businessNumber + '@@' + msgBody + '@@' +'WelcomeTemplate' + '@@' + null + '@@' + null + '@@' + customerName;
					System.debug('Callout String handler ==> ' + calloutString);
                    WhatsAppOutgoingMessage.sendMediaMessage(calloutString);  
                    
                } else {
                    System.debug('User created but no inbound messages: ' + key);
                }
            } else {
                if (msgs != null && !msgs.isEmpty()) {
                    System.debug('User already exists with WhatsApp messages: ' + key);
                }
            }
        }
    } */
    
    
}