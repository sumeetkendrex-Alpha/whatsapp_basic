/**
* @File Name : WhatsAppOutgoingMessage.cls
* @Description :
* @Author : $umeet Kendre
* @Last Modified By :
* @Last Modified On : December 10, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 10, 2024 |   | Initial Version
**/
public class WhatsAppOutgoingMessage {
    @Auraenabled
    public static String sendTextMessage(String callOutString) {
        
        List<String> callString = callOutString.split('@@');
        String sendTo = callString[0];
        String businessNumber = callString[1];
        String msgBody = callString[2];
        String msgType = callString[3];
        String customerName = callString[4];
        system.debug('callOutString'+callOutString);
        WhatsappMeta__mdt businessDetails = [SELECT Business_Number__c,PhoneNumber_Id__c,AccessToken__c FROM WhatsappMeta__mdt WHERE Business_Number__c != NULL AND Business_Number__c =:businessNumber];
        String OwnerUserId='';
        System.debug('call==>'+callOutString);
        String JsonBody;
        if(msgType == 'text'){
            JsonBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+sendTo+'","type":"'+msgType+'","text":{"body":"'+msgBody+'"}}';
        }else if(msgType == 'template'){
            JsonBody = msgBody;
            system.debug('Json Tempalte==>'+JsonBody);
        }else if(msgType=='image'){
            JsonBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+sendTo+'","type":"'+msgType+'","image":{"link":"'+msgBody+'"}}';
        }else if(msgType == 'video'){
            JsonBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+sendTo+'","type":"'+msgType+'","video":{"link":"'+msgBody+'"}}';
        }else if(msgType == 'audio'){
            JsonBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+sendTo+'","type":"'+msgType+'","audio":{"link":"'+msgBody+'"}}';
        }else if(msgType == 'document'){
            JsonBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+sendTo+'","type":"'+msgType+'","document":{"link":"'+msgBody+'"}}';
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://graph.facebook.com/v21.0/' + businessDetails.PhoneNumber_Id__c +'/messages?access_token=' + businessDetails.AccessToken__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JsonBody);
        
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            System.debug('Template==>'+res.getBody());
            
            WhatsAppMessageOutbound parentMessage = (WhatsAppMessageOutbound) JSON.deserialize(res.getBody(), WhatsAppMessageOutbound.class);
            WhatsAppMessageOutbound jsonRequestMessage = (WhatsAppMessageOutbound) JSON.deserialize(JsonBody, WhatsAppMessageOutbound.class);
            system.debug('jsonRequestMessage==>'+jsonRequestMessage);
            system.debug('parentMessage==>'+parentMessage);
            
            if (parentMessage != null ) {
                
                WhatsAppMessageOutbound.entry entry = parentMessage.entry !=null ? parentMessage.entry[0] :null;
                WhatsAppMessageOutbound.changes change = entry !=null ? entry.changes[0] :null;         
                WhatsAppMessageOutbound.value value = change != null ? change.value:null;
                WhatsAppMessageOutbound.statuses status = value != null ? value.statuses[0]: Null;
                WhatsAppMessageOutbound.metadata metadata = value != null ? value.metadata:NUll;
                
                WhatsAppMessageOutbound.conversation conversation = status != null ? status.conversation: Null;
                WhatsAppMessageOutbound.origin origin = conversation != null ? conversation.origin:Null;
                WhatsAppMessageOutbound.pricing pricing = status != nUll ? status.pricing:Null;
                
                // Extract data from deserialized object
                WhatsAppMessageOutbound.contacts con = parentMessage.contacts.get(0);
                WhatsAppMessageOutbound.messages message = parentMessage.messages.get(0);
                
                WhatsAppMessagingSession__c session = getOrCreateSession(sendTo, businessDetails.Business_Number__c, customerName);
                List<WhatsappUser__c> ownerLookup = [SELECT OwnerId FROM WhatsappUser__c WHERE Id = :session.WhatsappUser__c LIMIT 1];
                if (!ownerLookup.isEmpty()) {
                    OwnerUserId = ownerLookup[0].OwnerId;
                }

                // Create and populate Salesforce record
                WhatsApp_Message__c salesforceMessage = new WhatsApp_Message__c();
                salesforceMessage.CustomerPhone__c = con != null ? con.wa_id : null;
                salesforceMessage.MessageID__c = message != null ? message.id : null;
                salesforceMessage.CustomerName__c = customerName;
                salesforceMessage.WhatsApp_Messaging_Session__c = session.Id;
                salesforceMessage.MessageStatus__c = message != null ? message.message_status : null;
                salesforceMessage.ConversationId__c = conversation != null ? Conversation.Id : null;
                // salesforceMessage.ConversationExpiration__c =conversation != null ? Conversation.expiration_timestamp: null;
                salesforceMessage.ConversationOrigin__c =  conversation != null ? Conversation.origin.typex : null;
                salesforceMessage.PricingBillable__c = Pricing!= null ? Pricing.billable:false;
                salesforceMessage.PricingModel__c = Pricing != null ? Pricing.pricing_model:null;
                salesforceMessage.PricingCategory__c = Pricing!= null ? Pricing.category:null;
                
                
                salesforceMessage.BusinessPhoneNumber__c = businessDetails!=null ? businessDetails.Business_Number__c: null;
                //salesforceMessage.CustomerName__c = wpMessage!=null ? wpMessage.CustomerName__c: null;
                salesforceMessage.MessageSendType__c = 'Outbound';
                salesforceMessage.MessageSentTime__c = System.now();
                salesforceMessage.MessageType__c = jsonRequestMessage != null ? jsonRequestMessage.type : null;
                //salesforceMessage.SupportAgent__c = user!=null ? user.Name: null;
                
                if( jsonRequestMessage.type == 'text'){
                    salesforceMessage.MessageContent__c = jsonRequestMessage != null ? jsonRequestMessage.text.body : null;
                }else if(jsonRequestMessage.type == 'template'){
                    salesforceMessage.TemplateName__c = jsonRequestMessage != null ? jsonRequestMessage.template.name : null;
                    salesforceMessage.TemplateLanguage__c = jsonRequestMessage != null ? jsonRequestMessage.template.language.code : null;
                }else if(jsonRequestMessage.type == 'image'){
                    salesforceMessage.MediaLink__c = jsonRequestMessage != null? jsonRequestMessage.image.link : null;
                    
                }else if(jsonRequestMessage.type == 'video'){
                    salesforceMessage.MediaLink__c = jsonRequestMessage != null? jsonRequestMessage.video.link : null;
                    
                }else if(jsonRequestMessage.type == 'audio'){
                    salesforceMessage.MediaLink__c = jsonRequestMessage != null? jsonRequestMessage.audio.link : null;
                
                }else if(jsonRequestMessage.type == 'document'){
                    salesforceMessage.MediaLink__c = jsonRequestMessage != null? jsonRequestMessage.document.link : null;
                }
                
                
                
                if (salesforceMessage.CustomerPhone__c != null && salesforceMessage.MessageID__c != null) {
                    try{
                        System.debug('salesforceMessage1====> '+salesforceMessage);
                        
                        upsert salesforceMessage MessageID__c;
                         System.debug('salesforceMessage2====> '+salesforceMessage);
                        WhatsappConversationController.refreshLwc(OwnerUserId);
                        return 'success';
                        
                    }catch(DmlException e ){
                        System.debug('error====> '+e.getMessage()+'   : line '+e.getLineNumber());
                        return e.getMessage();
                    }
                } else {
                    System.debug('Missing critical data for WhatsApp_Message__c record.');
                    return 'Missing critical data for WhatsApp_Message__c record.';
                }
            } 
        } else {
            System.debug('Failed to send message. Status code: ' + res.getStatusCode() + ', Body: ' + res.getBody());
            Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());  
            System.debug('parsedJson==>'+parsedJson);
            Map<String, Object> error = (Map<String, Object>) parsedJson.get('error');
            Map<String, Object> errorData = (Map<String, Object>) error.get('error_data');
            System.debug('errorData==>'+errorData);
            return (String) errorData.get('details');
        }
        
        return '';
    }
    
    @AuraEnabled
    public static String sendMediaFile(String fileName, String base64Data, String bussinessPhoneNumber, String Phone , String fileType, String customerName) {
        System.debug('File Name:===> ' + fileName);
        System.debug('Base64 Data: ' + base64Data);
        System.debug('File Type: ' + fileType);
        // Create ContentVersion record
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName;
        contentVersion.PathOnClient = fileName;
        contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);
        insert contentVersion;
        
        ContentDistribution distributionRecord = new ContentDistribution();
        distributionRecord.ContentVersionId = contentVersion.Id;
        distributionRecord.Name = contentVersion.Title;
        distributionRecord.PreferencesNotifyOnVisit = false;
        distributionRecord.PreferencesAllowViewInBrowser = true;
        distributionRecord.PreferencesAllowOriginalDownload = true;
        insert distributionRecord;
        
        ContentDistribution conDist = [SELECT Id,ContentDownloadUrl,ContentVersionId  FROM ContentDistribution WHERE ContentVersionId =:contentVersion.Id];
        System.debug('conDist=> ' + conDist);
        String callOutString = Phone +'@@'+ bussinessPhoneNumber+'@@'+conDist.ContentDownloadUrl+'@@'+fileType+'@@'+contentVersion.Id+'@@'+fileName+'@@'+customerName;
        sendMediaMessage(callOutString);
        return contentVersion.Id;
        
    }
    
    @future(callout=True)
    public static void sendMediaMessage(String callOutString) {
        
        List<String> callString = callOutString.split('@@');
        String sendTo = callString[0];
        String businessNumber = callString[1];
        String msgBody = callString[2];
        String msgType = callString[3];
        String contentVersionId = callString[4];
        String filename = callString[5];
        String customerName = callString[6];
        system.debug('callOutString'+callOutString);
        WhatsappMeta__mdt businessDetails;
        String phoneNumberId;
        String accessToken;
        String OwnerUserId='';

        if(filename=='bulkTemplate'){
            List<String> whatsappMetaDetails = msgBody.split('##');
            phoneNumberId = whatsappMetaDetails[0];
            accessToken = whatsappMetaDetails[1];
        }else{
            businessDetails = [SELECT Business_Number__c,PhoneNumber_Id__c,AccessToken__c FROM WhatsappMeta__mdt WHERE Business_Number__c != NULL AND Business_Number__c =:businessNumber];
        }
        
        System.debug('call==>'+callOutString);
        String JsonBody;
        if(msgType == 'text'){
            JsonBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+sendTo+'","type":"text","text":{"body":"'+msgBody+'"}}';
        }else if(msgType == 'templateCatalog'){
            JsonBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+sendTo+'","type":"template","template":{"name":"crm_catalog","language":{"code":"en"},"components":[{"type":"body"},{"type":"button","sub_type":"CATALOG","index":0}]}}';
        }else if(msgType=='image'){
            JsonBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+sendTo+'","type":"'+msgType+'","image":{"link":"'+msgBody+'"}}';
        }else if(msgType == 'video'){
            JsonBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+sendTo+'","type":"'+msgType+'","video":{"link":"'+msgBody+'"}}';
        }else if(msgType == 'audio'){
            JsonBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+sendTo+'","type":"'+msgType+'","audio":{"link":"'+msgBody+'"}}';
        }else if(msgType == 'document'){
            JsonBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+sendTo+'","type":"'+msgType+'","document":{"link":"'+msgBody+'","caption":"'+filename+'" }}';
        }else if(msgType == 'interactive'){
            JsonBody ='{"messaging_product":"whatsapp","to":"'+sendTo+'","type":"template","template":{"name":"crm_support","language":{"code":"en"},"components":[{"type":"button","sub_type":"flow","index":"0"}]}}';
        }else if(msgType == 'template'){
            JsonBody ='{"messaging_product":"whatsapp","to":"'+sendTo+'","type":"'+msgType+'","template":{"name":"'+contentVersionId+'","language":{"code":"en"}}}';
        }else if(msgType == 'templateFlow'){
            JsonBody = msgBody;
        }
        else if(msgType == 'WelcomeTemplate'){
            JsonBody = msgBody;
        }
        
        
        HttpRequest req = new HttpRequest();
        if(filename=='bulkTemplate'){
            req.setEndpoint('https://graph.facebook.com/v21.0/' + phoneNumberId +'/messages?access_token=' + accessToken);
        }else{
            req.setEndpoint('https://graph.facebook.com/v21.0/' + businessDetails.PhoneNumber_Id__c +'/messages?access_token=' + businessDetails.AccessToken__c);
        }
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        System.debug('JsonBody==>'+JsonBody);
        
        req.setBody(JsonBody);
        
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            System.debug('Template==>'+res.getBody());
            
            WhatsAppMessageOutbound parentMessage = (WhatsAppMessageOutbound) JSON.deserialize(res.getBody(), WhatsAppMessageOutbound.class);
            WhatsAppMessageOutbound jsonRequestMessage = (WhatsAppMessageOutbound) JSON.deserialize(JsonBody, WhatsAppMessageOutbound.class);
            system.debug('jsonRequestMessage==>'+jsonRequestMessage);
            system.debug('parentMessage==>'+parentMessage);
            
            if (parentMessage != null ) {
                
                WhatsAppMessageOutbound.entry entry = parentMessage.entry !=null ? parentMessage.entry[0] :null;
                WhatsAppMessageOutbound.changes change = entry !=null ? entry.changes[0] :null;         
                WhatsAppMessageOutbound.value value = change != null ? change.value:null;
                WhatsAppMessageOutbound.statuses status = value != null ? value.statuses[0]: Null;
                WhatsAppMessageOutbound.metadata metadata = value != null ? value.metadata:NUll;
                
                WhatsAppMessageOutbound.conversation conversation = status != null ? status.conversation: Null;
                WhatsAppMessageOutbound.origin origin = conversation != null ? conversation.origin:Null;
                WhatsAppMessageOutbound.pricing pricing = status != nUll ? status.pricing:Null;
                
                // Extract data from deserialized object
                WhatsAppMessageOutbound.contacts con = parentMessage.contacts.get(0);
                WhatsAppMessageOutbound.messages message = parentMessage.messages.get(0);
                 WhatsAppMessagingSession__c session = getOrCreateSession(sendTo, businessDetails.Business_Number__c, customerName);
                List<WhatsappUser__c> ownerLookup = [SELECT OwnerId FROM WhatsappUser__c WHERE Id = :session.WhatsappUser__c LIMIT 1];
                if (!ownerLookup.isEmpty()) {
                    OwnerUserId = ownerLookup[0].OwnerId;
                }

                
                // Create and populate Salesforce record
                WhatsApp_Message__c salesforceMessage = new WhatsApp_Message__c();
                salesforceMessage.CustomerPhone__c = con != null ? con.wa_id : null;
                salesforceMessage.CustomerName__c = customerName;
                salesforceMessage.MessageID__c = message != null ? message.id : null;
                salesforceMessage.WhatsApp_Messaging_Session__c = session.Id;

                salesforceMessage.MessageStatus__c = message != null ? message.message_status : null;
                salesforceMessage.ConversationId__c = conversation != null ? Conversation.Id : null;
                // salesforceMessage.ConversationExpiration__c =conversation != null ? Conversation.expiration_timestamp: null;
                salesforceMessage.ConversationOrigin__c =  conversation != null ? Conversation.origin.typex : null;
                salesforceMessage.PricingBillable__c = Pricing!= null ? Pricing.billable:false;
                salesforceMessage.PricingModel__c = Pricing != null ? Pricing.pricing_model:null;
                salesforceMessage.PricingCategory__c = Pricing!= null ? Pricing.category:null;
                
                
                salesforceMessage.BusinessPhoneNumber__c = businessDetails!=null ? businessDetails.Business_Number__c: null;
                //salesforceMessage.CustomerName__c = wpMessage!=null ? wpMessage.CustomerName__c: null;
                salesforceMessage.MessageSendType__c = 'Outbound';
                salesforceMessage.MessageSentTime__c = System.now();
                salesforceMessage.MessageType__c = jsonRequestMessage != null ? jsonRequestMessage.type : null;
                if(msgType == 'summeryTemplate'){
                    salesforceMessage.OrderNumber__c = contentVersionId;
                }
                
                 if(filename =='NewCase'){
                    salesforceMessage.TemplateButtonPayload__c ='NewCase';
                     system.debug(' New Customer==>'+ salesforceMessage.MessageContent__c);
                }
                  if(filename =='caseNumber'){
                    salesforceMessage.TemplateButtonPayload__c ='caseNumber';
                     system.debug(' New Customer==>'+ salesforceMessage.MessageContent__c);
                }
                //salesforceMessage.SupportAgent__c = user!=null ? user.Name: null;
                
                if( jsonRequestMessage.type == 'text'){
                    salesforceMessage.MessageContent__c = jsonRequestMessage != null ? jsonRequestMessage.text.body : null;
                }else if(jsonRequestMessage.type == 'template'){
                    salesforceMessage.TemplateName__c = jsonRequestMessage != null ? jsonRequestMessage.template.name : null;
                    salesforceMessage.TemplateLanguage__c = jsonRequestMessage != null ? jsonRequestMessage.template.language.code : null;
                    
                }else if(jsonRequestMessage.type == 'image'){
                    salesforceMessage.MediaLink__c = jsonRequestMessage != null? jsonRequestMessage.image.link : null;
                    
                }else if(jsonRequestMessage.type == 'video'){
                    salesforceMessage.MediaLink__c = jsonRequestMessage != null? jsonRequestMessage.video.link : null;
                    
                }else if(jsonRequestMessage.type == 'audio'){
                    salesforceMessage.MediaLink__c = jsonRequestMessage != null? jsonRequestMessage.audio.link : null;
                }
                else if(jsonRequestMessage.type == 'document'){
                    salesforceMessage.MediaLink__c = jsonRequestMessage != null? jsonRequestMessage.document.link : null;
                }
                
                
                
                if (salesforceMessage.CustomerPhone__c != null && salesforceMessage.MessageID__c != null) {
                    try{
                        System.debug('salesforceMessage1====> '+salesforceMessage);
                        salesforceMessage.MediaId__c = contentVersionId;
                        upsert salesforceMessage MessageID__c;
                        WhatsappConversationController.refreshLwc(OwnerUserId);
                        System.debug('salesforceMessage2====> '+salesforceMessage);
                        if(contentVersionId != null){
                            List<ContentVersion> newContentVersionList = [SELECT Id,FirstPublishLocationId,ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId LIMIT 1];
                            if(!newContentVersionList.isEmpty()){
                                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                                contentDocumentLink.ContentDocumentId = newContentVersionList[0].ContentDocumentId; 
                                contentDocumentLink.LinkedEntityId = salesforceMessage.Id;             
                                contentDocumentLink.ShareType = 'V'; // Viewer access            
                                contentDocumentLink.Visibility = 'AllUsers'; 
                                insert contentDocumentLink;
                            }
                        }
                    }catch(DmlException e ){
                        System.debug('error====> '+e.getMessage()+'   : line '+e.getLineNumber());
                    }
                } else {
                    System.debug('Missing critical data for WhatsApp_Message__c record.');
                }
            } 
        } else {
            System.debug('Failed to send message. Status code: ' + res.getStatusCode() + ', Body: ' + res.getBody());

        }
    }

    /**
     * Returns the customer's most recent WhatsAppMessagingSession__c (whatever
     * its status) so an outbound send reuses it instead of creating a new one.
     * Only inserts a new session/user when this customer has never chatted before.
     */
    private static WhatsAppMessagingSession__c getOrCreateSession(String customerPhone, String businessPhoneNumber, String customerName) {
        List<WhatsappUser__c> users = [
            SELECT Id, OwnerId, CustomerName__c, CustomerPhone__c, BusinessNumber__c
            FROM WhatsappUser__c
            WHERE CustomerPhone__c = :customerPhone AND BusinessNumber__c = :businessPhoneNumber
            LIMIT 1
        ];

        WhatsappUser__c chatUser;
        if (!users.isEmpty()) {
            chatUser = users[0];
        } else {
            chatUser = new WhatsappUser__c(
                CustomerPhone__c = customerPhone,
                CustomerName__c = customerName,
                BusinessNumber__c = businessPhoneNumber
            );
            insert chatUser;
        }

        List<WhatsAppMessagingSession__c> recentSessions = [
            SELECT Id, Status__c, CustomerName__c, CustomerPhone__c, BusinessPhoneNumber__c, WhatsappUser__c
            FROM WhatsAppMessagingSession__c
            WHERE WhatsappUser__c = :chatUser.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!recentSessions.isEmpty()) {
            return recentSessions[0];
        }

        WhatsAppMessagingSession__c newSession = new WhatsAppMessagingSession__c();
        newSession.Status__c = 'Ended';
        newSession.StartTime__c = Datetime.now();
        newSession.EndTIme__c = Datetime.now();
        newSession.CustomerName__c = chatUser.CustomerName__c;
        newSession.CustomerPhone__c = chatUser.CustomerPhone__c;
        newSession.BusinessPhoneNumber__c = chatUser.BusinessNumber__c;
        newSession.WhatsappUser__c = chatUser.Id;
        insert newSession;
        return newSession;
    }

}