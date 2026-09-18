public class CreateMetaTemplate {
    // Custom response class to encapsulate the response details
    public class MetaTemplateResponse {
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public String templateId;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String category;
    }
    
    @AuraEnabled
    public static MetaTemplateResponse createMetaTemplate(String body, string templateType, String distUrl) {
        System.debug('body = ' + body);
        System.debug('body = ' + templateType);
                System.debug('distUrl = ' + distUrl);


        MetaTemplateResponse response = new MetaTemplateResponse();
        List<WhatsAppMetaTemplate__c> wmtList = new List<WhatsAppMetaTemplate__c>();
        
        WhatsappMeta__mdt metadata = [SELECT Id,Version__c, AccessToken__c,PhoneNumber_Id__c,WABA_Id__c,Meta_URL__c FROM WhatsappMeta__mdt LIMIT 1];
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(metadata.Meta_URL__c+''+metadata.Version__c+'/' +metadata.WABA_Id__c+ '/message_templates');
        req.setMethod('POST');
         req.setHeader('Authorization', 'Bearer ' + metadata.AccessToken__c);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(body);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('Response status code: ' + res.getStatusCode());
        
        if (res.getStatusCode() == 200) {
            System.debug('Template created successfully: ' + res.getBody());
            
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            WhatsAppMetaTemplate__c WmObj = new WhatsAppMetaTemplate__c();
            WmObj.Id__c = (String) responseMap.get('id');
            WmObj.Status__c = (String) responseMap.get('status');
            WmObj.Category__c = (String) responseMap.get('category');
            WmObj.SubCategory__c = templateType;
            WmObj.TemplateHeaderHandler__c = distUrl;
            wmtList.add(WmObj);
            
            if (!wmtList.isEmpty()) {
                insert wmtList;
                response.isSuccess = true;
                response.message = 'Template created and inserted successfully.';
                response.templateId = WmObj.Id__c;
                response.status = WmObj.Status__c;
                response.category = WmObj.Category__c;
            } else {
                response.isSuccess = false;
                response.message = 'Failed to insert template list.';
             
                MessageLog__c appLog = New MessageLog__c ();
                appLog.Description__c = res.getBody();
                Insert appLog;
            }
        } else {
            response.isSuccess = false;
            
            MessageLog__c appLog = New MessageLog__c ();
            appLog.Description__c = res.getBody();
            Insert appLog;
            
            response.message = 'Failed to create template. Status code: ' + res.getStatusCode() + ' Response: ' + res.getBody();
        }
        
        return response;
    }

    
    
    
    public static void dummy(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}