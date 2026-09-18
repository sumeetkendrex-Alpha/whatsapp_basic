public class sendWhatsAppTemplateController {
    
    @AuraEnabled
    public static List<String> SendtoNewUser(List<Map<String, String>> recordlist, String templateName, String businessNumber, String templatetype) {
        System.debug('Received templateName: ' + templateName);
        System.debug('Received businessNumber: ' + businessNumber);
        System.debug('Received templatetype: ' + templatetype);
        System.debug('Received Records: ' + JSON.serialize(recordlist));
        
        Set<String> incomingPhones = new Set<String>();
        for (Map<String, String> rec : recordlist) {
            if (rec.containsKey('Phone') && String.isNotBlank(rec.get('Phone'))) {
                incomingPhones.add(rec.get('Phone'));
            }
        }
        
        Map<String, WhatsappUser__c> existingUsersMap = new Map<String, WhatsappUser__c>();
        List<WhatsappUser__c> userList = [
            SELECT Id, CustomerName__c, CustomerPhone__c, BusinessNumber__c, latestDateTime__c 
            FROM WhatsappUser__c 
            WHERE CustomerPhone__c IN :incomingPhones 
            AND BusinessNumber__c = :businessNumber
        ];
        for (WhatsappUser__c user : userList) {
            existingUsersMap.put(user.CustomerPhone__c, user);
        }
        
        List<WhatsappUser__c> newUserList = new List<WhatsappUser__c>();
        List<Map<String, Object>> finalRecordData = new List<Map<String, Object>>();
        
        for (Map<String, String> userRecord : recordlist) {
            String phone = userRecord.get('Phone');
            String name = userRecord.containsKey('Name') ? userRecord.get('Name') : null;
            
            if (!String.isBlank(phone)) {
                WhatsappUser__c user;
                if (existingUsersMap.containsKey(phone)) {
                    user = existingUsersMap.get(phone);
                    user.latestDateTime__c = System.today();
                } else {
                    user = new WhatsappUser__c(
                        CustomerName__c = name,
                        CustomerPhone__c = phone,
                        BusinessNumber__c = businessNumber,
                        latestDateTime__c = System.today()
                    );
                    newUserList.add(user);
                }
                
                Map<String, Object> combo = new Map<String, Object>();
                combo.put('record', user);
                combo.put('csvData', userRecord);
                finalRecordData.add(combo);
            }
        }
        
        if (!newUserList.isEmpty()) {
            insert newUserList;
        }
        
        List<WhatsAppMetaTemplate__c> templateList = [
            SELECT Id, Template_Name__c, TemplateJSON__c 
            FROM WhatsAppMetaTemplate__c 
            WHERE Template_Name__c = :templateName
            LIMIT 1
        ];
        
        return sendBulkTemplate(finalRecordData, templateList[0].TemplateJSON__c, templatetype, businessNumber);
    }
    
    
    @AuraEnabled
    public static List<String> sendBulkTemplate(List<Map<String, Object>> combinedRecords, String templateBody, String templateType, String businessNumber) {
        WhatsappMeta__mdt metaBusiness = [
            SELECT AccessToken__c, Business_Number__c 
            FROM WhatsappMeta__mdt 
            WHERE Business_Number__c = :businessNumber 
            LIMIT 1
        ];
        
        List<String> calloutStrings = new List<String>();
        
        Map<String, Object> parsedTemplate = (Map<String, Object>) JSON.deserializeUntyped(templateBody);
        String templateName = '';
        
        if (parsedTemplate.containsKey('template')) {
            Map<String, Object> templateMap = (Map<String, Object>) parsedTemplate.get('template');
            if (templateMap.containsKey('name')) {
                templateName = (String) templateMap.get('name');
            }
        }
        
        // ✅ Process each record
        for (Map<String, Object> combo : combinedRecords) {
            WhatsappUser__c record = (WhatsappUser__c) combo.get('record');
            Map<String, String> csvData = (Map<String, String>) combo.get('csvData');
            
            String phone = record.CustomerPhone__c;
            String name = record.CustomerName__c;
            
            // ✅ Create parameters dynamically from CSV columns except Name and Phone
            List<Map<String, Object>> parameters = new List<Map<String, Object>>();
            for (String key : csvData.keySet()) {
                if (key.equalsIgnoreCase('Name') || key.equalsIgnoreCase('Phone')) {
                    continue;
                }
                String val = csvData.get(key);
                if (String.isNotBlank(val)) {
                    parameters.add(new Map<String, Object>{
                        'type' => 'text',
                        'text' => val
                    });
                }
            }
            
            // ✅ Build base payload
            Map<String, Object> payload = new Map<String, Object>{
                'messaging_product' => 'whatsapp',
                'recipient_type' => 'individual',
                'to' => phone,
                'type' => 'template'
            };
            
            // ✅ Parse templateBody to preserve header if it exists
            Map<String, Object> parsedTemplateMap = (Map<String, Object>) JSON.deserializeUntyped(templateBody);
            Map<String, Object> templateMap = (Map<String, Object>) parsedTemplateMap.get('template');
            
            List<Object> components = new List<Object>();
            
            // ✅ Preserve header (if any)
            if (templateMap.containsKey('components')) {
                List<Object> templateComponents = (List<Object>) templateMap.get('components');
                for (Object compObj : templateComponents) {
                    Map<String, Object> comp = (Map<String, Object>) compObj;
                    if (comp.get('type') == 'header') {
                        components.add(comp);
                    }
                }
            }
            
            // ✅ Add dynamic body
            components.add(new Map<String, Object>{
                'type' => 'body',
                'parameters' => parameters
            });
            
            // ✅ Assemble final template
            Map<String, Object> finalTemplate = new Map<String, Object>{
                'name' => templateName,
                'language' => new Map<String, Object>{ 'code' => 'en' },
                'components' => components
            };
            
            payload.put('template', finalTemplate);
            
            // ✅ Serialize final JSON
            String jsonBody = JSON.serialize(payload);
            String callOutString = phone + '@@' + metaBusiness.Business_Number__c + '@@' + jsonBody + '@@template@@' + name;
            calloutStrings.add(callOutString);
        }
        
        return calloutStrings;
    }
    
}