public class FlowsWhatsAppOutgoingMessage {
    
    @InvocableMethod(Label='Send whatsApp Message' Description='Return text message response')
    public static List<String> sendtextMessageflow(List<String> calloutString){
        List<String> callString = calloutString[0].split('@@');
        String sendTo = callString[0];
        String businessNumber = callString[1];
        String msgType = callString[3];
        String customerName = callString[4];
        String msgBody;
        if(callString[2] == 'crm_catalog'){
           msgBody = '{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+sendTo+'","type":"template","template":{"name":"'+callString[2]+'","language":{"code":"en"},"components":[{"type":"body"},{"type":"button","sub_type":"CATALOG","index":0}]}}';
        }else if(callString[2] == 'crm_support'){
            msgBody = '{"messaging_product":"whatsapp","to":"'+sendTo+'","type":"template","template":{"name":"crm_support","language":{"code":"en"},"components":[{"type":"button","sub_type":"flow","index":"0"}]}}';
        }
        
        String jsonBody = sendTo+'@@'+businessNumber+'@@'+msgBody+'@@'+msgType+'@@'+null+'@@'+null+'@@'+customerName;
        WhatsAppOutgoingMessage.sendMediaMessage(jsonBody);
        return null;
    }
      

    // General method to send a message based on type
    private static String sendMessage(String sendTo, String businessNumber, String jsonBody) {
        system.debug('Hello World');
       /* WhatsappMeta__mdt businessDetails = [SELECT Business_Number__c, PhoneNumber_Id__c, AccessToken__c 
                                             FROM WhatsappMeta__mdt 
                                             WHERE Business_Number__c != NULL 
                                             AND Business_Number__c =: businessNumber];

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://graph.facebook.com/v21.0/' + businessDetails.PhoneNumber_Id__c + '/messages?access_token=' + businessDetails.AccessToken__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() == 200) {
            System.debug('Message sent successfully: ' + res.getBody());
            return 'success';
        } else {
            System.debug('Failed to send message. Status code: ' + res.getStatusCode() + ', Body: ' + res.getBody());
            Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> error = (Map<String, Object>) parsedJson.get('error');
            Map<String, Object> errorData = (Map<String, Object>) error.get('error_data');
            System.debug('Error details: ' + errorData);
            return (String) errorData.get('details');
        } */
        return null;
    }

    @AuraEnabled
    public static String sendTextMessage(String sendTo, String businessNumber, String messageBody) {
        String jsonBody = '{"messaging_product":"whatsapp","recipient_type":"individual","to":"' + sendTo + '","type":"text","text":{"body":"' + messageBody + '"}}';
        return sendMessage(sendTo, businessNumber, jsonBody);
    }

    @AuraEnabled
    public static String sendAudioMessage(String sendTo, String businessNumber, String audioLink) {
        String jsonBody = '{"messaging_product":"whatsapp","recipient_type":"individual","to":"' + sendTo + '","type":"audio","audio":{"link":"' + audioLink + '"}}';
        return sendMessage(sendTo, businessNumber, jsonBody);
    }

    @AuraEnabled
    public static String sendVideoMessage(String sendTo, String businessNumber, String videoLink) {
        String jsonBody = '{"messaging_product":"whatsapp","recipient_type":"individual","to":"' + sendTo + '","type":"video","video":{"link":"' + videoLink + '"}}';
        return sendMessage(sendTo, businessNumber, jsonBody);
    }

    @AuraEnabled
    public static String sendImageMessage(String sendTo, String businessNumber, String imageLink) {
        String jsonBody = '{"messaging_product":"whatsapp","recipient_type":"individual","to":"' + sendTo + '","type":"image","image":{"link":"' + imageLink + '"}}';
        return sendMessage(sendTo, businessNumber, jsonBody);
    }

    @AuraEnabled
    public static String sendDocumentMessage(String sendTo, String businessNumber, String documentLink) {
        String jsonBody = '{"messaging_product":"whatsapp","recipient_type":"individual","to":"' + sendTo + '","type":"document","document":{"link":"' + documentLink + '"}}';
        return sendMessage(sendTo, businessNumber, jsonBody);
    }
}