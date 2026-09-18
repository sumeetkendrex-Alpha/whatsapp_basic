public class wahtsAppMessageQueueablehandler {
   public static void sendMessageQueue(String callOutString) {
        system.debug('Queueablehandler calloutstring===>'+callOutString);
        List<String> callString = callOutString.split('@@');
        String sendTo = callString[0];
        String businessNumber = callString[1];
        String msgBody = callString[2];
        String msgType = callString[3];
        String contentVersionId = callString[4];
        String filename = callString[5];
        String customerName = callString[6];
        WhatsappMeta__mdt businessDetails;
        String phoneNumberId;
        String accessToken;
        system.debug('businessNumber===>'+businessNumber);
        List<WhatsappMeta__mdt>  businessDetailsList = [SELECT Business_Number__c,PhoneNumber_Id__c,AccessToken__c FROM WhatsappMeta__mdt LIMIT  1];
        system.debug('businessDetailsList===>'+businessDetailsList);   
        if(!businessDetailsList.isEmpty()){
            businessDetails = businessDetailsList[0]; 
        }
        
        system.debug('businessDetails===>'+businessDetails);
        System.debug('call==>'+callOutString);
        if(businessDetails!= null){
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
            else if(msgType == 'summeryTemplate'){
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
                    
                    
                    // Create and populate Salesforce record
                    WhatsApp_Message__c salesforceMessage = new WhatsApp_Message__c();
                    salesforceMessage.CustomerPhone__c = con != null ? con.wa_id : null;
                    salesforceMessage.CustomerName__c = customerName;
                    salesforceMessage.MessageID__c = message != null ? message.id : null;
                    
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
                           // WhatsappConversationController.refreshLwc();
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
                MessageLog__c log = New MessageLog__c();
                log.Description__c = callOutString+'-'+JsonBody;
                log.lineNumber__c=String.valueOf(res.getStatusCode());
                Insert log;
            }
        }
    }
    
}