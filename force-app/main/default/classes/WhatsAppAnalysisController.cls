public with sharing class WhatsAppAnalysisController {
    
    @AuraEnabled(cacheable=true)
    public static String getTemplateInsights(String templateName) {
        try {
            WhatsAppMetaTemplate__c template = [SELECT Id, Id__c, Template_Name__c FROM WhatsAppMetaTemplate__c WHERE Template_Name__c = :templateName LIMIT 1];
            return String.isNotBlank(template.Id__c) ? template.Id__c : 'Template ID not found';
        } catch (Exception e) {
            return 'Template Not Found';
        }
    }

    
    @AuraEnabled
    public static WhatsappWrapper getData(Date startDate, Date endDate) {
        system.debug('startDate==>'+startDate);
        
        WhatsappWrapper whatsAppRecord = new WhatsappWrapper();
        List<WhatsApp_Message__c> whatsAppList = new List<WhatsApp_Message__c>();
        Map<String, List<WhatsApp_Message__c>> phoneToMessages = new Map<String, List<WhatsApp_Message__c>>();
        Map<String, TemplateRecord> templateMap = new Map<String, TemplateRecord>();
        
        Integer templateTotal = 0;
        Integer templateSent = 0;
        Integer templateFailed = 0;
        
        Integer serviceCount = 0;
        Integer marketingCount = 0;
        Integer utilityCount = 0;
        Integer authenticationCount = 0;
        Integer authIntlCount = 0;
        
        if (startDate != null && endDate != null) {
            DateTime startDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            DateTime endDateTime = DateTime.newInstance(endDate, Time.newInstance(23, 59, 59, 999));
            
            whatsAppList = [
                SELECT Id, CustomerPhone__c, MessageType__c, TemplateName__c,
                ConversationOrigin__c, MessageStatus__c, CreatedDate
                FROM WhatsApp_Message__c
                WHERE CreatedDate >= :startDateTime AND CreatedDate <= :endDateTime Order by CreatedDate desc
            ];
            whatsAppRecord.messages = whatsAppList;
            Integer ind = 0;
            for (WhatsApp_Message__c msg : whatsAppList) {
                system.debug('templateName==>'+msg.TemplateName__c);
                
                // Group by phone
                if (!phoneToMessages.containsKey(msg.CustomerPhone__c)) {
                    phoneToMessages.put(msg.CustomerPhone__c, new List<WhatsApp_Message__c>());
                }
                phoneToMessages.get(msg.CustomerPhone__c).add(msg);
                
                // Template Aggregation
                if (msg.MessageType__c == 'template') {
                    templateTotal++;
                    if (msg.MessageStatus__c == 'failed') {
                        templateFailed++;
                    } else {
                        templateSent++;
                    }
                    
                    String origin = msg.ConversationOrigin__c != null ? msg.ConversationOrigin__c.toLowerCase() : '';
                    system.debug('origin==>'+origin);
                    
                    if (origin == 'service') serviceCount++;
                    else if (origin == 'marketing') marketingCount++;
                    else if (origin == 'utility') utilityCount++;
                    else if (origin == 'authentication') authenticationCount++;
                    else if (origin == 'authentication - international') authIntlCount++;
                    
                    String templateName = msg.TemplateName__c != null ? msg.TemplateName__c.toLowerCase() : '';
                                        system.debug('templateName2==>'+templateName);

                    if (!templateMap.containsKey(templateName)) {
                        ind++;
                        TemplateRecord tr = new TemplateRecord();
                        tr.name = templateName;
                        tr.sent = 0;
                        tr.failed = 0;
                        tr.index = ind;
                        templateMap.put(templateName, tr);
                    }
                    
                    if (msg.MessageStatus__c == 'failed') {
                        templateMap.get(templateName).failed++;
                    } else {
                        templateMap.get(templateName).sent++;
                    }
                }
            }
            ind = 0;
            // Fill Template List
            whatsAppRecord.templateList = new List<TemplateRecord>(templateMap.values());
            
            // Fetch User Records
            List<WhatsappUser__c> userList = [
                SELECT Id, CustomerName__c, CustomerPhone__c
                FROM WhatsappUser__c
                WHERE CustomerPhone__c IN :phoneToMessages.keySet() Order by Createddate desc
            ];
            
            for (WhatsappUser__c user : userList) {
                Integer sent = 0;
                Integer failed = 0;
                Integer read = 0;
                ind++;
                for (WhatsApp_Message__c msg : phoneToMessages.get(user.CustomerPhone__c)) {
                    if (msg.MessageStatus__c == 'failed') {
                        failed++;
                    } else {
                        sent++;
                    }
                    if (msg.MessageStatus__c == 'read') {
                        read++;       
                    }

                    
                }
                
                UserStats stats = new UserStats();
                stats.name = user.CustomerName__c;
                stats.phone = user.CustomerPhone__c;
                stats.sent = sent;
                stats.notDelivered = failed;
                stats.index = ind;
                stats.readMessages = read;
                
                whatsAppRecord.userStats.add(stats);
            }
        }
        
        // Template stats summary
        whatsAppRecord.templateStats = new TemplateStats();
        whatsAppRecord.templateStats.total = templateTotal;
        whatsAppRecord.templateStats.sent = templateSent;
        whatsAppRecord.templateStats.failed = templateFailed;
        whatsAppRecord.templateStats.service = serviceCount;
        whatsAppRecord.templateStats.marketing = marketingCount;
        whatsAppRecord.templateStats.utility = utilityCount;
        whatsAppRecord.templateStats.authentication = authenticationCount;
        whatsAppRecord.templateStats.authInternational = authIntlCount;
        
        return whatsAppRecord;
    }
    
    
    
    
    public class WhatsappWrapper {
        @AuraEnabled public List<WhatsApp_Message__c> messages;
        @AuraEnabled public List<UserStats> userStats = new List<UserStats>();
        @AuraEnabled public TemplateStats templateStats;
        @AuraEnabled public List<TemplateRecord> templateList = new List<TemplateRecord>();
    }
    
    public class UserStats {
        @AuraEnabled public String name;
        @AuraEnabled public String phone;
        @AuraEnabled public Integer sent;
        @AuraEnabled public Integer notDelivered;
        @AuraEnabled public Integer index;
        @AuraEnabled public Integer readMessages;
    }
    
    public class TemplateStats {
        @AuraEnabled public Integer total;
        @AuraEnabled public Integer sent;
        @AuraEnabled public Integer failed;
        @AuraEnabled public Integer service;
        @AuraEnabled public Integer marketing;
        @AuraEnabled public Integer utility;
        @AuraEnabled public Integer authentication;
        @AuraEnabled public Integer authInternational;
    }
    
    public class TemplateRecord {
        @AuraEnabled public String name;
        @AuraEnabled public Integer sent;
        @AuraEnabled public Integer failed;
        @AuraEnabled public Integer index;
    }
}