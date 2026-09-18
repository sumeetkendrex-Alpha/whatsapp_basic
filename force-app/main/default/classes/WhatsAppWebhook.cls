/**
* @File Name : WhatsAppWebhook.cls
* @Description :
* @Author : $umeet Kendre
* @Last Modified By :$umeet Kendre
* @Last Modified On : November 10, 2024

*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 10 , 2024 |   | Initial Version
**/

@RestResource(urlMapping='/WhatsAppWebhook/*')
global without sharing class WhatsAppWebhook {
    @HttpGet // GET
    global static void doGet() {
        RestResponse response = RestContext.response;
        RestRequest request = RestContext.request;
        String WebhookToken = system.label.SecurityToken;
        if(request.params.get('hub.verify_token') == WebhookToken){
            response.responseBody = Blob.valueOf( request.params.get('hub.challenge') );
        }
    }
    
    @HttpPost // POST
    global static void doPost() {
        RestResponse response = RestContext.response;
        String responseString = RestContext.request.requestBody.toString();
        System.debug(' Response From WhatsApp \n  '+ responseString);
        String finalResponseString = responseString.replace('type', 'typex').replace('currency', 'currencyx');
        System.debug(' finalResponseString===> '+ finalResponseString);
       
        //Inserting Log for Testing Of JSON Formate...!
       MessageLog__c jsonLog = new MessageLog__c();
        jsonLog.Description__c = finalResponseString;
        insert jsonLog; 
        
        DateTime expirationDateTime = null;
        String OwnerId ='';
        
        WhatsAppMessageInbound parentMessage = (WhatsAppMessageInbound)JSON.deserialize( finalResponseString, WhatsAppMessageInbound.class);
        List<WhatsAppMessageInbound.entry> messageEntries = parentMessage.entry;
        if(messageEntries != null && messageEntries.size() > 0){
            WhatsAppMessageInbound.entry entryMessage = messageEntries.get(0);
            List<WhatsAppMessageInbound.changes> changeMessages = entryMessage.changes;
            if(changeMessages != null && changeMessages.size() > 0){
                WhatsAppMessageInbound.changes changeMessage = changeMessages.get(0);
                List<WhatsAppMessageInbound.contacts> contactList = changeMessage.value.contacts;
                List<WhatsAppMessageInbound.messages> messageList = changeMessage.value.messages;
                List<WhatsAppMessageInbound.statuses> statusList = changeMessage.value.statuses;
                system.debug('statusList'+statusList);
                WhatsAppMessageInbound.metadata metadata = changeMessage.value.metadata;
                
            MessageLog__c jsonLog2 = new MessageLog__c();
    jsonLog.Description__c = String.valueOf(statusList);
    insert jsonLog2;
                /* Create record into Salesforce */
                List<WhatsAppMessagingSession__c> whatsappMsgSessionList = new List<WhatsAppMessagingSession__c>();
                
                WhatsApp_Message__c salesforceMessage = new WhatsApp_Message__c();
                salesforceMessage.BusinessPhoneNumber__c = metadata != null ? metadata.display_phone_number : null;
                salesforceMessage.PhoneNumberId__c = metadata != null ? metadata.phone_number_id : null;
                if(contactList != null && contactList.size() > 0){
                    WhatsAppMessageInbound.contacts contact = contactList.get(0);
                    salesforceMessage.CustomerPhone__c = contact.wa_id;
                    if(contact.profile != null &&
   contact.profile.name != null){
    salesforceMessage.CustomerName__c = contact.profile.name;
}
                    if(contact.wa_id != null){
                        
                        if (metadata.display_phone_number != null && contact.wa_id != null ) {
                            List<WhatsappUser__c> chatUser = [SELECT Id,OwnerId,CustomerName__c, CustomerPhone__c, BusinessNumber__c,
                                                              (select Id, Status__c, StartTime__c, EndTIme__c, CustomerName__c, CustomerPhone__c, BusinessPhoneNumber__c  from WhatsApp_Messaging_Sessions__r where Status__c='Active' order by CreatedDate desc)
                                                              FROM WhatsappUser__c 
                                                              WHERE CustomerPhone__c = :contact.wa_id AND BusinessNumber__c =:metadata.display_phone_number];
                            
                            if (!chatUser.isEmpty()) {
                                for (WhatsappUser__c chat : chatUser) {
                                    if (chat.CustomerPhone__c == contact.wa_id && chat.BusinessNumber__c == metadata.display_phone_number) {
                                       OwnerId =chat.OwnerId;
                                       chat.latestDateTime__c = system.now();
if(contact.profile != null && contact.profile.name != null){
    chat.CustomerName__c = contact.profile.name;
}
                                    }
                                    if(chat.WhatsApp_Messaging_Sessions__r == null || chat.WhatsApp_Messaging_Sessions__r.isEmpty()) {
                                        WhatsAppMessagingSession__c  whatsappMsgSes = new WhatsAppMessagingSession__c();
                                        whatsappMsgSes.Status__c='Active';
                                        whatsappMsgSes.StartTime__c = Datetime.now();
										whatsappMsgSes.EndTime__c = (expirationDateTime != null) ? expirationDateTime : DateTime.now().addHours(22);
                                        whatsappMsgSes.CustomerName__c=chat.CustomerName__c;
                                        whatsappMsgSes.CustomerPhone__c=chat.CustomerPhone__c;
                                        whatsappMsgSes.BusinessPhoneNumber__c=chat.BusinessNumber__c;
                                        whatsappMsgSes.WhatsappUser__c=chat.Id;
                                        whatsappMsgSessionList.add(whatsappMsgSes);
                                    }else{
                                        whatsappMsgSessionList.add(chat.WhatsApp_Messaging_Sessions__r);
                                    }
                                }
                                update chatUser;
                            } else {
                                WhatsappUser__c newWpUser = new WhatsappUser__c(
                                    CustomerPhone__c = contact.wa_id,
                                    CustomerName__c = contact.profile.name,
                                    BusinessNumber__c = metadata.display_phone_number
                                );
                                insert newWpUser;
                                
                                
                                
                                WhatsAppMessagingSession__c  whatsappMsgSes = new WhatsAppMessagingSession__c();
                                whatsappMsgSes.Status__c='Active';
                                whatsappMsgSes.StartTime__c =System.today();
                                whatsappMsgSes.EndTIme__c=(expirationDateTime != null) ? expirationDateTime : DateTime.now().addHours(22);
                                whatsappMsgSes.CustomerName__c=newWpUser.CustomerName__c;
                                whatsappMsgSes.CustomerPhone__c=newWpUser.CustomerPhone__c;
                                whatsappMsgSes.BusinessPhoneNumber__c=newWpUser.BusinessNumber__c;
                                whatsappMsgSes.WhatsappUser__c=newWpUser.Id;
                                whatsappMsgSessionList.add(whatsappMsgSes);
                            }
                            if(!whatsappMsgSessionList.isEmpty()){
                                upsert whatsappMsgSessionList;
                            }
                        }
                    }
                    
                }
                
                System.debug('whatsappMsgSessionList = '+whatsappMsgSessionList);
                System.debug('whatsappMsgSessionList.size() = '+whatsappMsgSessionList.size());
                System.debug('statusList = '+statusList);
                if (statusList != null && !statusList.isEmpty()) {
                    WhatsAppMessageInbound.Statuses status = statusList.get(0);
                    system.debug('status.id==>'+status.id);
                    /*This Block will execute When status is failed */
                    if (status.status != null && status.status.toLowerCase() == 'failed' && status.errors != null && !status.errors.isEmpty()) {
                        WhatsAppMessageInbound.Errors error = status.errors[0];
                        MessageLog__c appLog = new MessageLog__c();
                        appLog.Description__c = 'Code: ' + error.code + ' | Message: ' + error.message;
                        insert appLog; 
                    }
                    
                    List<WhatsApp_Message__c> wpList = [
                        SELECT Id, MessageID__c, MessageStatus__c, WhatsApp_Messaging_Session__c
                        FROM WhatsApp_Message__c
                        WHERE MessageID__c = :status.id
                    ];
                    System.debug('wpList'+wpList);

                    if (!wpList.isEmpty()) {
                        WhatsApp_Message__c wpMessage = wpList[0];
                        wpMessage.MessageStatus__c = status.status != null ? status.status : wpMessage.MessageStatus__c;
                        update wpMessage;

                        /* Conversation/pricing data belongs to the messaging session, not the individual message */
                        if (wpMessage.WhatsApp_Messaging_Session__c != null) {
                            List<WhatsAppMessagingSession__c> existingSessions = [
                                SELECT Id, Status__c, CustomerName__c, CustomerPhone__c, BusinessPhoneNumber__c, WhatsappUser__c
                                FROM WhatsAppMessagingSession__c
                                WHERE Id = :wpMessage.WhatsApp_Messaging_Session__c
                                LIMIT 1
                            ];

                            if (!existingSessions.isEmpty()) {
                                WhatsAppMessagingSession__c existingSession = existingSessions[0];
                                Boolean isActive = existingSession.Status__c == 'Active';

                                WhatsAppMessagingSession__c session;
                                if (isActive) {
                                    /* Session still active: update it in place */
                                    session = new WhatsAppMessagingSession__c(Id = existingSession.Id);
                                } else {
                                    /* Session already ended: start a fresh one for this conversation */
                                    session = new WhatsAppMessagingSession__c();
                                    session.Status__c = 'Active';
                                    session.StartTime__c = Datetime.now();
                                    session.EndTIme__c = DateTime.now().addHours(22);
                                    session.CustomerName__c = existingSession.CustomerName__c;
                                    session.CustomerPhone__c = existingSession.CustomerPhone__c;
                                    session.BusinessPhoneNumber__c = existingSession.BusinessPhoneNumber__c;
                                    session.WhatsappUser__c = existingSession.WhatsappUser__c;
                                }

                                Boolean hasSessionUpdate = false;

                                if (status.Conversation != null) {
                                    if (status.Conversation.Id != null) {
                                        session.ConversationId__c = status.Conversation.Id;
                                        hasSessionUpdate = true;
                                    }
                                    if (status.Conversation.origin != null && status.Conversation.origin.typex != null) {
                                        session.ConversationOrigin__c = status.Conversation.origin.typex;
                                        hasSessionUpdate = true;
                                    }
                                    if (status.Conversation.expiration_timestamp != null) {
                                        Long unixTimestamp = Long.valueOf(status.Conversation.expiration_timestamp);
                                        expirationDateTime = DateTime.newInstance(1970, 1, 1, 0, 0, 0).addSeconds((Integer) unixTimestamp);
                                        session.EndTIme__c = expirationDateTime;
                                        hasSessionUpdate = true;
                                    }
                                }
                                if (status.Pricing != null) {
                                    if (status.Pricing.billable != null) {
                                        session.PricingBillable__c = status.Pricing.billable;
                                        hasSessionUpdate = true;
                                    }
                                    if (status.Pricing.pricing_model != null) {
                                        session.PricingModel__c = status.Pricing.pricing_model;
                                        hasSessionUpdate = true;
                                    }
                                    if (status.Pricing.category != null) {
                                        session.PricingCategory__c = status.Pricing.category;
                                        hasSessionUpdate = true;
                                    }
                                }

                                if (isActive) {
                                    if (hasSessionUpdate) {
                                        update session;
                                    }
                                } else {
                                    insert session;
                                }
                            }
                        }

                        WhatsappConversationController.refreshLwc(OwnerId);
                    }
                } else {
                    System.debug('statusList is null or empty');
                }
                
                System.debug('whatsappMsgSessionList Again= '+whatsappMsgSessionList);
                System.debug('whatsappMsgSessionList.size() Again= '+whatsappMsgSessionList.size());
                System.debug('messageList Again= '+messageList);
                
                
                if(messageList != null && messageList.size() > 0){
                    /* Simple Message */
                    WhatsAppMessageInbound.messages message = messageList.get(0);
                    salesforceMessage.MessageID__c = message.id;
                    if (!whatsappMsgSessionList.isEmpty()) {
                        salesforceMessage.WhatsApp_Messaging_Session__c = whatsappMsgSessionList[0].Id;
                    }
                    salesforceMessage.MessageType__c = message.typex;
                    salesforceMessage.MessageSentTime__c = String.isNotBlank(message.timestamp)
                        ? DateTime.newInstance(1970, 1, 1, 0, 0, 0).addSeconds(Integer.valueOf(message.timestamp))
                        : System.now();
                    salesforceMessage.MessageContent__c = message.text != null? message.text.body : null;
                    
                    if (message.typex == 'order') {
                        salesforceMessage.OrderDetail__c = finalResponseString;
                    } 
                    
                    if (message.typex == 'interactive') {
                        String responseJson = (message.interactive != null && message.interactive.nfm_reply != null) ? message.interactive.nfm_reply.response_json : null;
                        salesforceMessage.InteractiveDetail__c = responseJson;
                    }
                    /* If message is reaction */
                    salesforceMessage.Reaction__c = message.reaction != null ? message.reaction.emoji : null;
                    salesforceMessage.ParentMessageID__c = message.reaction != null ? message.reaction.message_id : null;
                    String phoneNumberIdForMedia = metadata != null ? metadata.phone_number_id : null;
                    if (message.image != null) {
                        salesforceMessage.MediaId__c = message.image.id;
                        salesforceMessage.MediaType__c = message.image.mime_typex;
                        salesforceMessage.MediaSHA256__c = message.image.sha256;
                        downloadMedia(message.image.id, phoneNumberIdForMedia,message.id);
                    } else if (message.video != null) {
                        salesforceMessage.MediaId__c = message.video.id;
                        salesforceMessage.MediaType__c = message.video.mime_typex;
                        salesforceMessage.MediaSHA256__c = message.video.sha256;
                        downloadMedia(message.video.id, phoneNumberIdForMedia,message.id);
                    } else if (message.sticker != null) {
                        salesforceMessage.MediaId__c = message.sticker.id;
                        salesforceMessage.MediaType__c = message.sticker.mime_typex;
                        salesforceMessage.MediaSHA256__c = message.sticker.sha256;
                        salesforceMessage.MediaAnimated__c = message.sticker.animated;
                    }else if(message.audio != null){
                        salesforceMessage.MediaId__c = message.audio.id;
                        salesforceMessage.MediaType__c = message.audio.mime_typex;
                        salesforceMessage.MediaSHA256__c = message.audio.sha256;
                        downloadMedia(message.audio.id, phoneNumberIdForMedia,message.id);
                    }else if(message.location != null){
                        salesforceMessage.Location__Latitude__s = message.location.latitude;
                        salesforceMessage.Location__Longitude__s  = message.location.longitude;
                    }
                    
                    /* If message is Template Button */
                    salesforceMessage.TemplateButtonPayload__c = message.button != null ? message.button.payload : null;
                    salesforceMessage.TemplateButtonText__c = message.button != null ? message.button.text : null;
                    /* If the message is reply to another message */
                    salesforceMessage.ParentMessageID__c = message.context != null ? message.context.id : null;
                    salesforceMessage.MessageSendType__c = 'Inbound';
                    try{
                        upsert salesforceMessage MessageID__c;
                        WhatsappConversationController.refreshLwc(OwnerId);
                    }catch(Exception e){
                        system.debug('Error Upsert==>'+e.getMessage()+'   : line '+e.getLineNumber());
                        
                        MessageLog__c appLog = New MessageLog__c();
                        appLog.Description__c = e.getMessage();
                        appLog.lineNumber__c = String.ValueOf(e.getLineNumber());
                        Insert appLog; 
                    }
                }
            }
        }
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('{success:true, event:"success"}');
    }
    
    @future(callout= true)
    public static void downloadMedia(String media_Id, String phoneNumberId,STring messageId) {
        System.debug('downloadMedia==>' + media_Id+'===>'+phoneNumberId+'===>'+messageId);
        
        try {
            // Fetch metadata for authorization
            List<WhatsappMeta__mdt> metadataList = [SELECT Id,Version__c, AccessToken__c FROM WhatsappMeta__mdt WHERE PhoneNumber_Id__c = :phoneNumberId LIMIT 1];
            if (metadataList.isEmpty()) {
                System.debug('No WhatsappMeta__mdt found for phoneNumberId: ' + phoneNumberId);
                return;
            }
            WhatsappMeta__mdt metadata = metadataList[0];
            system.debug('metadata'+metadata);
            // Step 1: Get the media download URL
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://graph.facebook.com/'+metadata.Version__c+'/'+media_Id+'?phone_number_id='+phoneNumberId);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + metadata.AccessToken__c);
            Http http = new Http();
            HTTPResponse res = http.send(req);
            
            if (res.getStatusCode() != 200) {
                System.debug('Error fetching media Status: ' + res.getStatus());
                System.debug('Error fetching medi Body: ' + res.getBody());
                
                return;
            }
            
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String downloadUrl = (String) body.get('url');
            String fileType = (String) body.get('mime_type');
            
            // Determine file name based on file type
            String fileName = 'file';
            if (fileType.startsWith('video/')) {
                fileName = 'video.mp4';
            } else if (fileType.startsWith('image/')) {
                fileName = 'image.jpeg';
            } else if (fileType.startsWith('application/')) {
                fileName = 'document.pdf';
            } else if (fileType.startsWith('audio/')) {
                fileName = 'audio.mp3';
            }
            
            // Step 2: Download the media and save it in Salesforce
            HttpRequest downloadReq = new HttpRequest();
            downloadReq.setEndpoint(downloadUrl);
            downloadReq.setMethod('GET');
            downloadReq.setHeader('Authorization', 'Bearer ' + metadata.AccessToken__c);
            HTTPResponse downloadRes = http.send(downloadReq);
            
            if (downloadRes.getStatusCode() == 200) {
                List<WhatsApp_Message__C> whatsappmessageList = [SELECT Id,MessageID__c from WhatsApp_Message__C WHERE MessageID__c=:messageId];
                if(!whatsappmessageList.isEmpty()){
                    Blob mediaFile = downloadRes.getBodyAsBlob();
                    
                    ContentVersion contentVersion = new ContentVersion();
                    contentVersion.VersionData = mediaFile;
                    contentVersion.Title = fileName;
                    contentVersion.PathOnClient = fileName;
                    contentVersion.firstPublishLocationId= whatsappmessageList[0].Id;
                    
                    System.debug('Media file saved successfully:Before==> ' + contentVersion);
                    
                    insert contentVersion;
                    System.debug('Media file saved successfully:After==> ' + contentVersion);
                    
                    String fileURLX = URL.getSalesforceBaseUrl().toExternalForm() + '/sfc/servlet.shepherd/version/download/' + contentVersion.Id;
                    String fileURL = fileURLX.ReplaceAll('site','salesforce');
                    System.debug('Media file saved successfully: ' + contentVersion.Id);
                    
                    
                    for(WhatsApp_Message__C wpObj:whatsappmessageList){
                        wpObj.MediaLink__c = fileURL;
                    }
                    update whatsappmessageList;
                }else{
                    system.debug('List is empty()');
                }
            } else {
                System.debug('Error downloading media file: ' + downloadRes.getStatus());
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            MessageLog__c appLog = new MessageLog__c();
            appLog.Description__c = 'downloadMedia Error: ' + e.getMessage();
            appLog.lineNumber__c = String.valueOf(e.getLineNumber());
            insert appLog;
        }
    }
}