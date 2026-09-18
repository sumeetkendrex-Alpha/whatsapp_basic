public without sharing class WhatsAppMessageTriggerHandler {
    public static void SendWelcomeMessage(List<WhatsApp_Message__c> newMessages) {
        Set<String> customerPhones = new Set<String>();
        Set<String> businessPhones = new Set<String>();
        for (WhatsApp_Message__c msg : newMessages) {
            if (msg.CustomerPhone__c != null && msg.BusinessPhoneNumber__c != null && msg.MessageSendType__c=='Inbound'
                && (msg.MessageContent__c=='Hi'|| msg.MessageContent__c=='Hello')) {
                    customerPhones.add(msg.CustomerPhone__c);
                    businessPhones.add(msg.BusinessPhoneNumber__c);
                } /*else if(msg.CustomerPhone__c != null && msg.BusinessPhoneNumber__c != null && msg.MessageSendType__c=='Inbound'
                         && msg.MessageType__c=='order'){
                             String msgBody = 'Hello '+ msg.CustomerName__c + '\\n\\n Thank you for placing your order. We have received it and will begin processing shortly.';
                             String calloutString = msg.CustomerPhone__c + '@@' + msg.BusinessPhoneNumber__c + '@@' + msgBody + '@@' +'text' + '@@' + null + '@@' + null + '@@' + msg.CustomerName__c;
                             WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                         }*/
        }
        
        Map<String, WhatsappUser__c> userMap = new Map<String, WhatsappUser__c>();
        for (WhatsappUser__c user : [SELECT Id, BusinessNumber__c, CustomerPhone__c, CustomerName__c FROM WhatsappUser__c 
                                     WHERE CustomerPhone__c IN :customerPhones AND BusinessNumber__c IN :businessPhones]) {
                                         String key = user.CustomerPhone__c + '-' + user.BusinessNumber__c;
                                         userMap.put(key, user);
                                     }
        
        for (WhatsApp_Message__c msg : newMessages) {
            String key = msg.CustomerPhone__c + '-' + msg.BusinessPhoneNumber__c;
            if (userMap.containsKey(key)) {
                List<WhatsAppMessagingSession__c> sessions = [SELECT Id FROM WhatsAppMessagingSession__c WHERE CustomerPhone__c = :msg.CustomerPhone__c
                                                              AND BusinessPhoneNumber__c = :msg.BusinessPhoneNumber__c];
                
                if (sessions.size() > 1) {
                    System.debug('More than one session found for: ' + key);
                    List<String> parts = key.split('-');
                    String customerPhone = parts.size() > 0 ? parts[0] : '';
                    String businessNumber = parts.size() > 1 ? parts[1] : '';
                    
                    WhatsappUser__c user = userMap.get(key);
                    String customerName = user != null ? user.CustomerName__c : '';
                    // String msgBody = '{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+customerPhone+'","type":"template","template":{"name":"welcome_back","language":{"code":"en"},"components":[]}}';
                    String msgBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+customerPhone+'","type":"template","template":{"name":"balaji_catalog","language":{"code":"en"},"components":[{"type":"body"},{"type":"button","sub_type":"CATALOG","index":0}]}}';
                    
                    String calloutString = customerPhone + '@@' + businessNumber + '@@' + msgBody + '@@' +'WelcomeTemplate' + '@@' + null + '@@' + null + '@@' + customerName;
                    System.debug('Callout String handler ==> ' + calloutString);
                    WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                } else if (sessions.size() == 1) {
                    System.debug('One session found for: ' + key);
                    List<String> parts = key.split('-');
                    String customerPhone = parts.size() > 0 ? parts[0] : '';
                    String businessNumber = parts.size() > 1 ? parts[1] : '';
                    
                    WhatsappUser__c user = userMap.get(key);
                    String customerName = user != null ? user.CustomerName__c : '';
                    // String msgBody = '{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+customerPhone+'","type":"template","template":{"name":"welcome_newcustomer","language":{"code":"en"},"components":[{"type":"body","parameters":[{"type":"text","text":"'+customerName+'"}]}]}}';
                    String msgBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+customerPhone+'","type":"template","template":{"name":"balaji_catalog","language":{"code":"en"},"components":[{"type":"body"},{"type":"button","sub_type":"CATALOG","index":0}]}}';
                    String calloutString = customerPhone + '@@' + businessNumber + '@@' + msgBody + '@@' +'WelcomeTemplate' + '@@' + null + '@@' + null + '@@' + customerName;
                    System.debug('Callout String handler ==> ' + calloutString);
                    WhatsAppOutgoingMessage.sendMediaMessage(calloutString); 
                } else {
                    System.debug('No session found for: ' + key);
                }
            } else {
                System.debug('No matching WhatsappUser__c found for: ' + key);
            }
        }
    }
    
    public static void SendWelcomeMessage(Set<Id> msgIdsbatch) {
        List<WhatsApp_Message__c> newMessages = [Select ID,MessageID__c,MessageContent__c,CustomerName__c,CustomerPhone__c,BusinessPhoneNumber__c, MessageSendType__c from WhatsApp_Message__c WHERE Id=:msgIdsbatch];
        Set<String> customerPhones = new Set<String>();
        Set<String> businessPhones = new Set<String>();
        Set<String> customerName = new Set<String>();
        
        for (WhatsApp_Message__c msg : newMessages) {
            if (msg.CustomerPhone__c != null && msg.BusinessPhoneNumber__c != null && msg.MessageSendType__c=='Inbound') {
                customerPhones.add(msg.CustomerPhone__c);
                businessPhones.add(msg.BusinessPhoneNumber__c);
                customerName.add(msg.CustomerName__c);
            }
        }
        
        List<WhatsApp_Message__c> oldMessages = [Select ID,CustomerPhone__c,BusinessPhoneNumber__c, MessageSendType__c from WhatsApp_Message__c WHERE
                                                 CustomerPhone__c=:customerPhones AND BusinessPhoneNumber__c=:businessPhones AND MessageSendType__c='Outbound'];
        system.debug('oldMessages===>'+oldMessages);
        if(!oldMessages.isEmpty()){
            system.debug('He is purana Customer===>');
        } else{
            system.debug(' New Customer===>'+System.Label.Library_Name);
            String Libranyname =System.Label.Library_Name;
            system.debug(' New Libranyname===>'+Libranyname);
            
            List<ContentWorkspace> workspaceList = [SELECT Id,Name FROM ContentWorkspace WHERE Name =:Libranyname LIMIT 1];
            system.debug('workspaceList===>'+workspaceList);
            if (!workspaceList.isEmpty()) {
                Id workspaceId = workspaceList[0].Id;
                List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :workspaceId];
                system.debug('docLinks===>'+docLinks);
                Set<Id> docIds = new Set<Id>();
                for (ContentDocumentLink link : docLinks) {
                    docIds.add(link.ContentDocumentId);
                }
                system.debug('docIds===>'+docIds);
                if (!docIds.isEmpty()) {
                    List<ContentVersion> versionList = [SELECT Id, ContentDocumentId, FileExtension FROM ContentVersion WHERE ContentDocumentId IN :docIds 
                                                        AND FileExtension IN ('JPG', 'PNG', 'JPEG', 'GIF') ORDER BY LastModifiedDate DESC];
                    system.debug('versionList===>'+versionList);
                    
                    Set<Id> contentVersionIds = new Set<Id>();
                    for (ContentVersion version : versionList) {
                        contentVersionIds.add(version.Id);
                    }
                    
                    if (!contentVersionIds.isEmpty()) {
                        List<String> urls = new List<String>();
                        for (ContentDistribution cd : [SELECT ContentVersionId, ContentDownloadUrl FROM ContentDistribution 
                                                       WHERE ContentVersionId IN :contentVersionIds]) {
                                                           urls.add(cd.ContentDownloadUrl);
                                                       }
                        
                        if (!urls.isEmpty()) {
                            List<String> callOutStrings = new List<String>();
                            for (String url : urls) {
                                String callOutString = customerPhones + '@@' + businessPhones + '@@' + url + '@@image@@' + null + '@@' + null + '@@' + customerName;
                                callOutStrings.add(callOutString);
                            }
                            system.debug('callOutStrings===>'+callOutStrings);
                            system.debug('callOutStrings===>'+callOutStrings.size());
                            
                            
                            // System.enqueueJob(new WhatsAppMessageQueueable(callOutStrings));
                            
                            SendWhatsAppMessageBatch batch = new SendWhatsAppMessageBatch(callOutStrings);
                            Database.executeBatch(batch, 1);
                        }
                    }
                }
            }
        }
        
        
    }
    /*
public static void SendWelcomeMessage(List<WhatsApp_Message__c> newMessages) {


for (WhatsApp_Message__c msg : newMessages) {
if (msg.MessageContent__c != null && msg.MessageSendType__c == 'Inbound') {
String customerPhone = msg.CustomerPhone__c;
String businessNumber = msg.BusinessPhoneNumber__c;
String customerName = msg.CustomerName__c;
if (msg.MessageContent__c=='Hi') {
String msgBody = '{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+ customerPhone + '","type":"template","template":{"name":"welcome_vadilal","language":{"code":"en"},"components":[{"type":"body"}]}}';
String calloutString = customerPhone + '@@' + businessNumber + '@@' + msgBody+ '@@' + 'WelcomeTemplate' + '@@' + null + '@@' + null + '@@' + customerName;
WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
}else if (msg.MessageContent__c!= null) {
List<WhatsApp_Message__c> oldMessage = [Select Id,MessageSendType__c from WhatsApp_Message__c Where 
TemplateName__c ='d_raise_comaplin' AND
MessageSendType__c='Outbound' AND BusinessPhoneNumber__c=: businessNumber AND CustomerPhone__c=: customerPhone
];
List<WhatsappUser__c> wplist = [Select Id,tags_data__c from WhatsappUser__c WHERE CustomerPhone__c=:customerPhone AND BusinessNumber__c =:businessNumber AND
tags_data__c ='NewCase' LIMIT 1];
if(!oldMessage.isEmpty()){
Case cs = New Case();
cs.Subject =msg.MessageContent__c;
cs.Status = 'New';
cs.Origin ='Phone';
Insert cs;
if(cs != null){
wplist[0].tags_data__c ='';
Update wplist;
String msgBody = '{"messaging_product":"whatsapp","recipient_type":"individual","to":"'
+ customerPhone + '","type":"template","template":{"name":"d_thank_you","language":{"code":"en"},"components":[{"type":"body"}]}}';
String calloutString = customerPhone + '@@' + businessNumber + '@@' + msgBody+ '@@' + 'WelcomeTemplate' + '@@' + null + '@@' + null + '@@' + customerName;
WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
}

}

}


if (msg.TemplateButtonPayload__c=='Raise a Complaint') {
List<WhatsappUser__c> wplist = [Select Id,tags_data__c from WhatsappUser__c WHERE CustomerPhone__c=:customerPhone AND BusinessNumber__c =:businessNumber LIMIT 1];
wplist[0].tags_data__c ='NewCase';
update wplist;
String  msgBody = '{"messaging_product":"whatsapp","recipient_type":"individual","to":"'
+ customerPhone + '","type":"template","template":{"name":"d_raise_comaplin","language":{"code":"en"},"components":[{"type":"body"}]}}';
String calloutString = customerPhone + '@@' + businessNumber + '@@' + msgBody+ '@@' + 'WelcomeTemplate' + '@@' + null + '@@' + null + '@@' + customerName;
WhatsAppOutgoingMessage.sendMediaMessage(calloutString);

}


}
}
}

*/
    
    public static void latestMessageId(List<WhatsApp_Message__c> newMessages) {
        Map<String ,String> newMap = New Map<String , String>();
        for(WhatsApp_Message__c message : newMessages){
            newMap.put(message.CustomerPhone__c, message.BusinessPhoneNumber__c);
        }
        
        if(!newMap.isEmpty()){
            List< WhatsappUser__c> whatsaAPPuser =[SELECT Id, Name,latestDateTime__c,CustomerName__c,CustomerPhone__c ,BusinessNumber__c FROM WhatsappUser__c 
                                                   WHERE CustomerPhone__c IN:newMap.keyset() AND BusinessNumber__c=:newMap.values()]; 
            if(!whatsaAPPuser.isEmpty()){
                for(WhatsappUser__c user : whatsaAPPuser){
                    user.latestDateTime__c=system.now();
                }
            }
            update whatsaAPPuser;
        }
    } 
    
    public static void findRealtedRecord(List<WhatsApp_Message__c> newMessages) {
        
        Set<String> phoneNumbers = new Set<String>();
        for (WhatsApp_Message__c message : newMessages) {
            if (String.isNotBlank(message.CustomerPhone__c)) {
                phoneNumbers.add(message.CustomerPhone__c);
            }
        }
        Map<String, Id> phoneToAccountIdMap = new Map<String, Id>();
        Map<String, Id> phoneToContactIdMap = new Map<String, Id>();
        Map<String, Id> phoneToLeadIdMap = new Map<String, Id>();
        Map<String, Id> phoneToWhatsAppMap = nEw Map<String, Id>();
        for (Account acc : [SELECT Id, Phone FROM Account WHERE Phone IN :phoneNumbers]) {
            phoneToAccountIdMap.put(acc.Phone, acc.Id);
        }
        
        for (Contact con : [SELECT Id, Phone FROM Contact WHERE Phone IN :phoneNumbers]) {
            phoneToContactIdMap.put(con.Phone, con.Id);
        }
        
        for (Lead lead : [SELECT Id, Phone FROM Lead WHERE Phone IN :phoneNumbers]) {
            phoneToLeadIdMap.put(lead.Phone, lead.Id);
        }
        
        for(WhatsappUser__c whatsAppChat :[SELECT Id ,CustomerPhone__c  FROM WhatsappUser__c WHERE CustomerPhone__c IN:phoneNumbers]){
            phoneToWhatsAppMap.put(whatsAppChat.CustomerPhone__c, whatsAppChat.Id);
            
        }
        
        List<WhatsApp_Message__c> messagesToUpdate = new List<WhatsApp_Message__c>();
        List<Lead> leadsToInsert = new List<Lead>();
        
        for (WhatsApp_Message__c message : newMessages) {
            String phone = message.CustomerPhone__c;
            String name = message.CustomerName__c;
            
            if (phoneToAccountIdMap.containsKey(phone)) {
                message.Account__c = phoneToAccountIdMap.get(phone);
            }
            
            if (phoneToContactIdMap.containsKey(phone)) {
                message.Contact__c = phoneToContactIdMap.get(phone);
            }
            
            if (phoneToLeadIdMap.containsKey(phone)) {
                message.Lead__c = phoneToLeadIdMap.get(phone);
            }
            if (phoneToWhatsAppMap.containsKey(phone)) {
                message.WhatsappUser__c = phoneToWhatsAppMap.get(phone);
            }
            /*   if (!phoneToAccountIdMap.containsKey(phone) && !phoneToContactIdMap.containsKey(phone) && !phoneToLeadIdMap.containsKey(phone)) {
Lead newLead = new Lead();
newLead.LastName = name;
newLead.Company = 'Unknown';
newLead.Phone = phone;
newLead.LeadSource = 'WhatsApp';
leadsToInsert.add(newLead);

}
messagesToUpdate.add(message);
}
if (!leadsToInsert.isEmpty()) {
insert leadsToInsert;
} */
        }
    }
    
    @future(callout=true)
    public static void fetchTemplateDetail(Set<Id> newMsgId) {
        WhatsappMeta__mdt metaBusiness = [SELECT Id, AccessToken__c, Business_Number__c, PhoneNumber_Id__c, WABA_Id__c, Version__c FROM WhatsappMeta__mdt LIMIT 1];
        
        List<WhatsApp_Message__c> messagesList = [SELECT Id, TemplateName__c FROM WhatsApp_Message__c WHERE Id IN :newMsgId];
        List<WhatsApp_Message__c> updatedMessages = new List<WhatsApp_Message__c>();
        
        for (WhatsApp_Message__c message : messagesList) {
            if (String.isNotBlank(message.TemplateName__c)) {
                String url = 'https://graph.facebook.com/' + metaBusiness.Version__c + '/' + metaBusiness.WABA_Id__c + '/message_templates?name=' + message.TemplateName__c;
                
                HttpRequest secondReq = new HttpRequest();
                secondReq.setEndpoint(url);
                secondReq.setMethod('GET');
                secondReq.setHeader('Authorization', 'Bearer ' + metaBusiness.AccessToken__c);
                
                HttpResponse secondRes = new Http().send(secondReq);
                
                if (secondRes.getStatusCode() == 200) {
                    Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(secondRes.getBody());
                    List<Object> dataList = (List<Object>) jsonResponse.get('data');
                    
                    if (!dataList.isEmpty()) {
                        Map<String, Object> templateData = (Map<String, Object>) dataList[0];
                        List<Object> components = (List<Object>) templateData.get('components');
                        
                        String bodyText = '';
                        String footerText = '';
                        String headerUrl = '';
                        List<String> buttonTexts = new List<String>();
                        
                        for (Object comp : components) {
                            Map<String, Object> compMap = (Map<String, Object>) comp;
                            String type = (String) compMap.get('type');
                            
                            if (type == 'BODY' && compMap.containsKey('text')) {
                                bodyText = (String) compMap.get('text');
                            } else if (type == 'FOOTER' && compMap.containsKey('text')) {
                                footerText = (String) compMap.get('text');
                            } else if (type == 'HEADER' && compMap.containsKey('format')) {
                                String format = (String) compMap.get('format');
                                if ((format == 'IMAGE' || format == 'VIDEO' || format == 'DOCUMENT' || format == 'AUDIO')&& compMap.containsKey('example')) {
                                    Map<String, Object> example = (Map<String, Object>) compMap.get('example');
                                    List<Object> handleList = (List<Object>) example.get('header_handle');
                                    if (!handleList.isEmpty()) {
                                        headerUrl = (String) handleList[0];
                                    }
                                }
                            }
                            
                            if (compMap.containsKey('buttons')) {
                                List<Object> buttons = (List<Object>) compMap.get('buttons');
                                for (Object btn : buttons) {
                                    Map<String, Object> btnMap = (Map<String, Object>) btn;
                                    if (btnMap.containsKey('text')) {
                                        buttonTexts.add((String) btnMap.get('text'));
                                    }
                                }
                            }
                        }
                        
                        // Store values in custom object
                        //message.MediaLink__c = headerUrl;
                        message.MessageContent__c = bodyText;
                        // message.FooterText__c = footerText;
                        message.TemplateButtonText__c = String.join(buttonTexts, ';');
                        //  message.TemplateJson__c = secondRes.getBody(); 
                        
                        updatedMessages.add(message);
                    }
                } else {
                    
                    System.debug('Error response: ' + secondRes.getStatus() + ' - ' + secondRes.getBody());
                }
            }
        }
        
        if (!updatedMessages.isEmpty()) {
            try {
                update updatedMessages;
            } catch (Exception e) {
                System.debug('Update failed: ' + e.getMessage());
            }
        }
    }
    
    @future(callout=true)
    public static void sendTypingIndicator(Set<Id> messageIds) {
        WhatsappMeta__mdt metaBusiness = [SELECT Id, AccessToken__c, Business_Number__c, PhoneNumber_Id__c, WABA_Id__c, Version__c FROM WhatsappMeta__mdt LIMIT 1];
        List<WhatsApp_Message__c> messages = [SELECT Id, MessageID__c FROM WhatsApp_Message__c WHERE Id IN :messageIds];
        
        for (WhatsApp_Message__c msg : messages) {
            if (String.isNotBlank(msg.MessageID__c)) {
                try {
                    Http http = new Http();
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint('https://graph.facebook.com/' + metaBusiness.Version__c + '/' + metaBusiness.PhoneNumber_Id__c + '/messages');
                    request.setMethod('POST');
                    request.setHeader('Content-Type', 'application/json');
                    request.setHeader('Authorization', 'Bearer ' + metaBusiness.AccessToken__c);
                    
                    Map<String, Object> payload = new Map<String, Object>{'messaging_product' => 'whatsapp','status' => 'read',
                        'message_id' => msg.MessageID__c,
                        'typing_indicator' => new Map<String, String>{ 'type' => 'text' }};
                            
                            String body = JSON.serialize(payload);
                    request.setBody(body);
                    
                    HttpResponse response = http.send(request);
                    
                    if (response.getStatusCode() != 200) {
                        System.debug('Failed to send typing indicator. Response: ' + response.getBody());
                    } else {
                        System.debug('Typing indicator sent successfully.');
                    }
                } catch (Exception e) {
                    System.debug('Exception while sending typing indicator: ' + e.getMessage());
                }
            }
        }
    }
}