public class TemplateBodyDmlQueueable implements Queueable {
    private List<WhatsAppMetaTemplate__c> messages;

    public TemplateBodyDmlQueueable(List<WhatsAppMetaTemplate__c> messages) {
        this.messages = messages;
    }

    public void execute(QueueableContext context) {
        for (WhatsAppMetaTemplate__c message : messages) {
            List<WhatsAppMetaTemplate__c> existingTemplates = [SELECT Id FROM WhatsAppMetaTemplate__c WHERE Id__c = :message.Id__c];

            if (!existingTemplates.isEmpty()) {
                WhatsAppMetaTemplate__c existingTemplate = existingTemplates[0];
                existingTemplate.Template_Name__c = message.Template_Name__c;
                existingTemplate.Template_Body__c = message.Template_Body__c;
                existingTemplate.Status__c = message.Status__c;
                existingTemplate.Template_Footer__c = message.Template_Footer__c;
                existingTemplate.Template_Header__c = message.Template_Header__c;
                existingTemplate.TemplateHeaderHandler__c = message.TemplateHeaderHandler__c;
                existingTemplate.TemplateHeaderText__c = message.TemplateHeaderText__c;
                //existingTemplate.SubCategory__c = message.SubCategory__c;
                existingTemplate.CorrectCategory__c = message.CorrectCategory__c;
                existingTemplate.TemplateButtonType__c = message.TemplateButtonType__c;
                existingTemplate.TemplateButtonText__c = message.TemplateButtonText__c;
                existingTemplate.TemplateButtonOfferCode__c = message.TemplateButtonOfferCode__c;
                existingTemplate.TemplateButtonPhone__c = message.TemplateButtonPhone__c;
                existingTemplate.TemplateButtonURL__c = message.TemplateButtonURL__c;
                update existingTemplate;
            } else {
                insert message;
            }
        }
    }
}