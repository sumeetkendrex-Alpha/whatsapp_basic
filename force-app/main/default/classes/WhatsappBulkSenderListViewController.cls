public class WhatsappBulkSenderListViewController {
      @AuraEnabled
    public static WhatsAppMetaTemplate__c getTemplateById(Id templateId) {
        system.debug('templateId=>'+templateId);
        WhatsAppMetaTemplate__c templateList = [SELECT Id, Template_Name__c, TemplateJSON__c FROM WhatsAppMetaTemplate__c WHERE Id = :templateId LIMIT 1];
                system.debug('templateList=>'+templateList);

        return templateList;
    }

    @AuraEnabled
    public static List<WhatsappUser__c> getUsers() {
        return [
            SELECT Id, BusinessNumber__c, CustomerPhone__c, CustomerName__c 
            FROM WhatsappUser__c LIMIT 4900
        ];
    }
}