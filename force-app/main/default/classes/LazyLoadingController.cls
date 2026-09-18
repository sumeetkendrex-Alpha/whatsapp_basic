public with sharing class LazyLoadingController {
    
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String objectName, Integer limitSize, Integer offset) {
        
        String query = 'SELECT Id, Name, Phone FROM '+objectName+' ORDER BY CreatedDate LIMIT :limitSize OFFSET :offset';
        // Execute the query and return the results
        System.debug('Database.query(query)==>'+Database.query(query));
        return Database.query(query);
    }
    @AuraEnabled
    public static String sendBulkTemplate(List<String> selectedRecordIds, String objectName, String templateName, String templateType) {
        System.debug('Method Called');
        System.debug('selectedRecordIds==>'+selectedRecordIds);
        System.debug('templateType==>'+templateType);
        
        WhatsappMeta__mdt metaBusiness = [SELECT Id, AccessToken__c, Business_Number__c, PhoneNumber_Id__c, WABA_Id__c, Version__c FROM WhatsappMeta__mdt LIMIT 1];
        /*
User currentUser = [SELECT Id, WhatsAppNumber__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
System.debug('currentUser ==>'+currentUser);

WhatsappMeta__mdt wMeta = [SELECT Id, AccessToken__c, PhoneNumber_Id__c FROM WhatsappMeta__mdt WHERE Business_Number__c = :currentUser.WhatsAppNumber__c LIMIT 1];

System.debug('wMeta==>'+wMeta);
*/
        String metaDetails = metaBusiness.Business_Number__c + '##' + metaBusiness.AccessToken__c;
        System.debug('metaDetails==>'+metaDetails);
        
        // Query records with the required fields
        List<SObject> records = Database.query('SELECT Phone, Name FROM ' + objectName + ' WHERE Id IN :selectedRecordIds');
        System.debug('records==>'+records);
        
        for (SObject record : records) {
            String phone = (String) record.get('Phone');
            String name = (String) record.get('Name');
            System.debug('phone==>'+phone);
            System.debug('name==>'+name);
            if (templateType == 'Catalog') {
                System.debug('templateType==>'+templateType);
                String callOutString = phone + '@@' + metaBusiness.Business_Number__c + '@@' + metaDetails + '@@' + 'templateCatalog' + '@@'+null+'@@' + 'bulkTemplate' + '@@' + name;
                System.debug('callOutString==>'+callOutString);
                WhatsAppOutgoingMessage.sendMediaMessage(callOutString);
            }else if (templateType == 'Custom') {
                System.debug('templateType==>'+templateType);
                String callOutString = phone + '@@' + metaBusiness.Business_Number__c + '@@' + metaDetails + '@@' + 'template' + '@@'+templateName+'@@' + 'bulkTemplate' + '@@' + name;
                System.debug('callOutString==>'+callOutString);
                WhatsAppOutgoingMessage.sendMediaMessage(callOutString);
            }else if (templateType == 'Order Details') {
                System.debug('templateType==>'+templateType);
                String callOutString = phone + '@@' + metaBusiness.Business_Number__c + '@@' + metaDetails + '@@' + 'summeryTemplate' + '@@'+null+'@@' + 'bulkTemplate' + '@@' + name;
                System.debug('callOutString==>'+callOutString);
                WhatsAppOutgoingMessage.sendMediaMessage(callOutString);
            }else if(templateType=='Flows'){
                String calloutString = phone+'@@'+metaBusiness.Business_Number__c+'@@'+metaDetails+'@@'+'interactive'+'@@'+null+'@@'+'bulkTemplate'+'@@'+name;
                WhatsAppOutgoingMessage.sendMediaMessage(callOutString);
            }else if(templateType=='Promotion'){
              //  String msgBody = '{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+phone+'","type":"template","template":{"name":"account_creation_confirmation","language":{"code":"en_US"},"components":[{"type":"header","parameters":[{"type":"image","image":{"link":"https://believe6-dev-ed.develop.file.force.com/sfc/dist/version/download/?oid=00DQy00000IxeLk&ids=068Qy00000BuS3J&d=%2Fa%2FQy0000008zr7%2F2FaolmJXYt5KRm_txen0LWyEk_k3IaT5yZS6MtRP5Sc&asPdf=false"}}]},{"type":"body","parameters":[{"type":"text","text":"'+name+'"}]}]}}';
              String msgBody ='{"messaging_product":"whatsapp","recipient_type":"individual","to":"'+phone+'","type":"template","template":{"name":"crmvisitfeedback","language":{"code":"en"},"components":[{"type":"header","parameters":[{"type":"image","image":{"link":"https://believe6-dev-ed.develop.file.force.com/sfc/dist/version/download/?oid=00DQy00000IxeLk&ids=068Qy00000BuS3J&d=%2Fa%2FQy0000008zr7%2F2FaolmJXYt5KRm_txen0LWyEk_k3IaT5yZS6MtRP5Sc&asPdf=false"}}]},{"type":"body","parameters":[{"type":"text","text":"'+name+'"}]},{"type":"button","sub_type":"FLOW","index":0}]}}';
                String calloutString = phone+'@@'+'918233354537'+'@@'+msgBody+'@@'+'Promotion'+'@@'+null+'@@'+'null'+'@@'+name;
              WhatsAppOutgoingMessage.sendMediaMessage(callOutString);   
            }
        }
        
        return 'Success';
    }
    
}