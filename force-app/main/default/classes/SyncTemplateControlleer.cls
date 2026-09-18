public class SyncTemplateControlleer {
    
    @AuraEnabled
    public static String syncTemplate(String recordId) {
        WhatsAppMetaTemplate__c template = [SELECT Id, Id__c FROM WhatsAppMetaTemplate__c WHERE Id = :recordId LIMIT 1];
        String result = FetchTemplate(template.Id__c);
        return result;
    }

    public static String FetchTemplate(String templateId) {
        List<WhatsAppMetaTemplate__c> messages = new List<WhatsAppMetaTemplate__c>();

        try {
            List<WhatsappMeta__mdt> businessList = [SELECT Id, Version__c, AccessToken__c, PhoneNumber_Id__c, WABA_Id__c, Business_Number__c FROM WhatsappMeta__mdt LIMIT 1];
            
            if (businessList.isEmpty()) {
                return 'Error: No WhatsApp business metadata found.';
            }
 
            WhatsappMeta__mdt business = businessList[0];
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://graph.facebook.com/' + business.Version__c + '/' + templateId);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + business.AccessToken__c);

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() == 200) {
                String responseBody = res.getBody();
                System.debug('API Response: ' + responseBody);

                WhatsAppTemplate template = (WhatsAppTemplate) JSON.deserialize(responseBody, WhatsAppTemplate.class);

                WhatsAppMetaTemplate__c newTemplate = new WhatsAppMetaTemplate__c();
                newTemplate.Id__c = template.id;
                newTemplate.Category__c = template.category;
                newTemplate.Template_Name__c = template.name;
                newTemplate.Status__c = template.status;
                //newTemplate.SubCategory__c = template.sub_category;
                newTemplate.CorrectCategory__c = template.correct_category;
                newTemplate.Language__c= template.language;

                if (template.components != null) {
                    for (WhatsAppTemplate.Component comp : template.components) {
                        if (comp.type == 'HEADER') {
                            newTemplate.Template_Header__c = comp.format;
                            if (comp.example != null && comp.example.header_handle != null && !comp.example.header_handle.isEmpty()) {
                               // newTemplate.TemplateHeaderHandler__c = comp.example.header_handle[0];
                            }
                            newTemplate.TemplateHeaderText__c = comp.text;
                        } else if (comp.type == 'BODY') {
                            newTemplate.Template_Body__c = comp.text;
                        } else if (comp.type == 'FOOTER') {
                            newTemplate.Template_Footer__c = comp.text;
                        } else if (comp.type == 'BUTTONS' && comp.buttons != null) {
                            List<String> buttonTypes = new List<String>();
                            List<String> buttonTexts = new List<String>();
                            List<String> offerCodes = new List<String>();
                            List<String> phones = new List<String>();
                            List<String> urls = new List<String>();

                            for (WhatsAppTemplate.Button btn : comp.buttons) {
                                buttonTypes.add(btn.type);
                                buttonTexts.add(btn.text);

                                if (btn.type == 'COPY_CODE' && btn.example != null && !btn.example.isEmpty()) {
                                    offerCodes.addAll(btn.example);
                                } else if (btn.type == 'PHONE_NUMBER' && btn.phone_number != null) {
                                    phones.add(btn.phone_number);
                                } else if (btn.type == 'URL' && btn.url != null) {
                                    urls.add(btn.url);
                                }
                            }

                            newTemplate.TemplateButtonType__c = String.join(buttonTypes, ',');
                            newTemplate.TemplateButtonText__c = String.join(buttonTexts, ',');
                            newTemplate.TemplateButtonOfferCode__c = String.join(offerCodes, ',');
                            newTemplate.TemplateButtonPhone__c = String.join(phones, ',');
                            newTemplate.TemplateButtonURL__c = String.join(urls, ',');
                        }
                    }
                }
                messages.add(newTemplate);

            } else {
                return 'API Error: ' + res.getStatusCode() + ' - ' + res.getStatus() +'-'+ res.getBody();
            }
        } catch (Exception e) {
            return 'Exception: ' + e.getMessage();
        }
        if (!messages.isEmpty()) {
            upsert messages Id__c;
            return 'Template synced successfully.';
        } else {
            return 'No data to sync.';
        }
    }
}