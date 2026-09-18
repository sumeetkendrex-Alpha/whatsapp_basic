public with sharing class TemplateMessageController {

    @AuraEnabled(cacheable=true)
    public static TemplateWrapper getTemplateData(Id recordId) {
        WhatsAppMetaTemplate__c record = [
            SELECT Template_Body__c,
                   TemplateButtonType__c,
                   Template_Footer__c,
                   Template_Header__c,
                   Template_Name__c,
                   TemplateHeaderText__c,
                   TemplateHeaderHandler__c,
                   TemplateButtonPhone__c,
                   TemplateButtonURL__c,
                   TemplateButtonOfferCode__c,
                   TemplateButtonText__c,
                   SubCategory__c,
                   CorrectCategory__c,
                   TemplateJSON__c,
                   language__c
            FROM WhatsAppMetaTemplate__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        TemplateWrapper tw = new TemplateWrapper();
        tw.templateName = record.Template_Name__c;
        tw.headerType = record.Template_Header__c;
        tw.headerHandle = record.TemplateHeaderHandler__c;
        tw.headerText = record.TemplateHeaderText__c;
        tw.bodyText = record.Template_Body__c;
        tw.footerText = record.Template_Footer__c;

        tw.buttonType = record.TemplateButtonType__c;
        tw.buttonText = record.TemplateButtonText__c;
        tw.buttonPhone = record.TemplateButtonPhone__c;
        tw.buttonUrl = record.TemplateButtonURL__c;
        tw.buttonOfferCode = record.TemplateButtonOfferCode__c;

        tw.language = record.language__c;
        tw.category = record.CorrectCategory__c;
        tw.templateJSON = record.TemplateJSON__c;

        return tw;
    }

    @AuraEnabled
    public static void addJson(Id recordId, String jsonResponese) {
        system.debug('jsonResponese:'+jsonResponese);
        if (recordId != null && !String.isBlank(jsonResponese)) {
            update new WhatsAppMetaTemplate__c(
                Id = recordId,
                TemplateJSON__c = jsonResponese
            );
        }
    }

    public class TemplateWrapper {
        @AuraEnabled public String templateName;
        @AuraEnabled public String headerType;
        @AuraEnabled public String headerHandle;
        @AuraEnabled public String headerText;
        @AuraEnabled public String bodyText;
        @AuraEnabled public String footerText;

        @AuraEnabled public String buttonType;
        @AuraEnabled public String buttonText;
        @AuraEnabled public String buttonPhone;
        @AuraEnabled public String buttonUrl;
        @AuraEnabled public String buttonOfferCode;

        @AuraEnabled public String language;
        @AuraEnabled public String category;
        @AuraEnabled public String templateJSON;
    }
}