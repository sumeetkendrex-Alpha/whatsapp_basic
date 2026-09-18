/**
* @File Name : WhatsappConversationController.cls
* @Description :
* @Author : $umeet Kendre
* @Last Modified By :
* @Last Modified On : December 10, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 10, 2024 |   | Initial Version
**/

public without sharing class WhatsappConversationController {
    @AuraEnabled
    public static List<WhatsappMeta__mdt> getBusinessContacts() {
        // Query the current user with necessary fields
        User currentUser = [SELECT Id, WhatsAppNumber__c, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        // Define the list to store business contacts
        List<WhatsappMeta__mdt> businessContactList;
        
        // Check the user's profile and fetch data accordingly
        if (currentUser.WhatsAppNumber__c != null) {
            businessContactList = [
                SELECT Business_Number__c, MasterLabel
                FROM WhatsappMeta__mdt
                WHERE Business_Number__c != NULL 
                AND Business_Number__c = :currentUser.WhatsAppNumber__c AND Is_Active__c = True
            ];
        }else{
            businessContactList = [
                SELECT Business_Number__c, MasterLabel
                FROM WhatsappMeta__mdt
                WHERE Business_Number__c != NULL AND Is_Active__c = True
            ];
        }
        // Return the fetched business contacts
        return businessContactList;
    }
    @AuraEnabled
    public static List<WhatsAppMessagingSession__c > getMessagingSessions (String PhoneNumber, String bussinessPhoneNumber){
        system.debug('PhoneNumber==>'+PhoneNumber);
        system.debug('bussinessPhoneNumbe==>'+bussinessPhoneNumber);
        
        return[select Id, Status__c, CustomerName__c, CustomerPhone__c, BusinessPhoneNumber__c
               from WhatsAppMessagingSession__c WHERE CustomerPhone__c =:PhoneNumber AND BusinessPhoneNumber__c=:bussinessPhoneNumber
               ORDER BY CreatedDate DESC
               LIMIT 1];
    }
    
    
    @AuraEnabled
    public static List<WhatsApp_Message__c>getAgetview(String PhoneNumber, String bussinessPhoneNumber){
        List<WhatsApp_Message__c> MessagList = [SELECT Id ,ViewedByAgent__c,CustomerPhone__c,BusinessPhoneNumber__c 
                                                FROM WhatsApp_Message__c WHERE BusinessPhoneNumber__c =:bussinessPhoneNumber AND
                                                CustomerPhone__c =: PhoneNumber ];
        for(WhatsApp_Message__c messges:MessagList){
            messges.ViewedByAgent__c= true;
        }
        update MessagList;
        return MessagList;
    }
    
    /*  @AuraEnabled
public static List<WhatsappUser__c> getAllConversationByContact(String businessPhoneNumber , Integer contactLimit , Integer contactOffset) {
System.debug('businessPhoneNumber==>'+businessPhoneNumber);
System.debug('contactLimit==>'+contactLimit);
System.debug('contactOffset==>'+contactOffset);

List<WhatsappUser__c> whatsAppUser = [Select Id,CustomerName__c,CustomerPhone__c,BusinessNumber__c,latestDateTime__c  from WhatsappUser__c WHERE  BusinessNumber__c = :businessPhoneNumber ORDER BY latestDateTime__c  DESC LIMIT :contactLimit OFFSET :contactOffset];
return whatsAppUser;
}    

@AuraEnabled
public static List<WhatsApp_Message__c>getAgetviewCount(String businessPhoneNumber){
system.debug('Agent bussinessPhoneNumber==>'+businessPhoneNumber);
List<WhatsApp_Message__c> MessagList = [SELECT Id ,ViewedByAgent__c,CustomerName__c,MessageSendType__c,CustomerPhone__c,BusinessPhoneNumber__c 
FROM WhatsApp_Message__c WHERE MessageSendType__c ='Inbound' AND ViewedByAgent__c =false AND BusinessPhoneNumber__c =:businessPhoneNumber
ORDER BY CreatedDate DESC];
return MessagList;
}*/
    
    @AuraEnabled
    public static List<WhatsappUserWrapper> getAllConversationByContact(String businessPhoneNumber, Integer contactLimit, Integer contactOffset) {
        List<WhatsappUser__c> whatsAppUsers = [SELECT Id, CustomerName__c, CustomerPhone__c, BusinessNumber__c, latestDateTime__c
                                               FROM WhatsappUser__c WHERE BusinessNumber__c = :businessPhoneNumber ORDER BY latestDateTime__c DESC 
                                               LIMIT :contactLimit OFFSET :contactOffset];
        
        Set<String> customerPhones = new Set<String>();
        for (WhatsappUser__c user : whatsAppUsers) {
            customerPhones.add(user.CustomerPhone__c);
        }
        
        Map<String, Integer> unreadCounts = new Map<String, Integer>();
        
        if (!customerPhones.isEmpty()) {
            AggregateResult[] messageCounts = [SELECT CustomerPhone__c phone, COUNT(Id) unreadCount FROM WhatsApp_Message__c WHERE MessageSendType__c = 'Inbound' 
                                               AND ViewedByAgent__c = false AND BusinessPhoneNumber__c = :businessPhoneNumber AND CustomerPhone__c IN :customerPhones
                                               GROUP BY CustomerPhone__c];
            
            for (AggregateResult ar : messageCounts) {
                unreadCounts.put((String)ar.get('phone'), (Integer)ar.get('unreadCount'));
            }
        }
        List<WhatsappUserWrapper> results = new List<WhatsappUserWrapper>();
        for (WhatsappUser__c user : whatsAppUsers) {
            results.add(new WhatsappUserWrapper(
                user,
                unreadCounts.get(user.CustomerPhone__c) != null ? unreadCounts.get(user.CustomerPhone__c) : 0
            ));
        }
        
        return results;
    }
    
    public class WhatsappUserWrapper {
        @AuraEnabled public WhatsappUser__c user;
        @AuraEnabled public Integer unreadCount;
        
        public WhatsappUserWrapper(WhatsappUser__c user, Integer unreadCount) {
            this.user = user;
            this.unreadCount = unreadCount;
        }
    }
    
    
    
    
    
    
    @AuraEnabled
    public static String createNewWhatsapp(String businessPhoneNumber, String customerName, String customerPhone) {
        // Step 1: Fetch grouped data (CustomerPhone__c, MAX(CustomerName__c))
        If(businessPhoneNumber!=null && customerName != null && customerPhone != null){
            try {
                WhatsappUser__c newUser = new WhatsappUser__c(
                    BusinessNumber__c = businessPhoneNumber,
                    CustomerName__c = customerName,
                    CustomerPhone__c = customerPhone,
                    latestDateTime__c = system.TOday()
                );
                insert newUser;
                
                WhatsAppMessagingSession__c session = New WhatsAppMessagingSession__c ();
                session.BusinessPhoneNumber__c = businessPhoneNumber;
                session.CustomerName__c = customerName;
                session.CustomerPhone__c = customerPhone;
                session.StartTime__c = system.today();
                session.EndTIme__c = system.today();
                session.Status__c='Ended';
                session.WhatsappUser__c = newUser.Id;
                Insert session;
                
                List<String> result = new List<String>();
                result.add('Success');
                result.add(newUser.Id);
                result.add(newUser.CustomerName__c);
                result.add(newUser.CustomerPhone__c);
                
                return JSON.serialize(result);
            }catch(Exception e){
                String fullMessage = e.getMessage();
                if (fullMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                    // Extract the part after the error code
                    Integer startIndex = fullMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION,'.length();
                    Integer endIndex = fullMessage.indexOf(':', startIndex);
                    String cleanMessage = fullMessage.substring(startIndex, endIndex).trim();
                    return cleanMessage;
                }
                return fullMessage;
                
            }
            
        }else{
            
            return 'Provide Complete Details';
        }
        
    }
    
    @AuraEnabled
    public static string getTaskRecordId(){
        try {
            return [SELECT Id FROM Task LIMIT 1].Id;
        } catch (Exception e) {
            return e.getMessage();
        } 
    }
    
    /*  @AuraEnabled
public static string createEndChatRecord(String subject, String status, String priority, String businessPhoneNumber, String Phone){
System.debug('businessPhoneNumber ==> '+businessPhoneNumber);
System.debug('Phone ==> '+Phone);
try {
WhatsApp_Message__c waMsg = new WhatsApp_Message__c(
BusinessPhoneNumber__c = businessPhoneNumber,
CustomerPhone__c = Phone,
MessageType__c = 'end chat',
MessageSendType__c = 'End Chat',
MessageSentTime__c = System.now()
);

insert waMsg;

if(waMsg != null){
WhatsappUser__c  wca = [SELECT Id FROM WhatsappUser__c WHERE CustomerPhone__c =: Phone AND BusinessNumber__c =:businessPhoneNumber LIMIT 1];
Task newTask = new Task(
Subject = subject,
ActivityDate = System.today(),
WhatId = wca.Id,
OwnerId = UserInfo.getUserId(),
Status = status,
Priority = priority
);

insert newTask;
// wca.ChatStatus__c = false;
update wca;
return 'Success';
}else{
return 'error while creating task...';
}

} catch (Exception e) {
return e.getMessage();
} 
} */
    @AuraEnabled
    public static String createEndChatRecord(String businessPhoneNumber, String customerPhone) {
        try {
            List<WhatsAppMessagingSession__c> sessionList = [SELECT Id, Status__c FROM WhatsAppMessagingSession__c WHERE Status__c = 'Active' 
                                                             AND BusinessPhoneNumber__c = :businessPhoneNumber AND CustomerPhone__c = :customerPhone];
            
            if (sessionList.isEmpty()) {
                return 'Error: No active session found for these phone numbers';
            }
            
            for (WhatsAppMessagingSession__c session : sessionList) {
                session.Status__c = 'Ended';
            }
            
            update sessionList;
            return 'Success: Ended ' + sessionList.size() + ' chat session(s)';
            
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<WhatsApp_Message__c> getAllConversationDetailByPhone(String businessPhoneNumber, String Phone) {
        
        List<WhatsApp_Message__c> listOfWaMsg =  [select id,ConversationExpiration__c,ConversationOrigin__c,PricingModel__c,PricingCategory__c,PricingBillable__c,CustomerPhone__c,BusinessPhoneNumber__c ,ViewedByAgent__c
                                                  from WhatsApp_Message__c WHERE CustomerPhone__c = :Phone AND BusinessPhoneNumber__c =: businessPhoneNumber ORDER BY CreatedDate DESC LIMIT 1];
        
        return listOfWaMsg;
    }
    
    @AuraEnabled(cacheable=true)
    public static WhatsappUser__c getChatDetails(String businessPhoneNumber, String Phone) {
        return [select Id,CustomerPhone__c
                from WhatsappUser__c WHERE CustomerPhone__c = :Phone AND BusinessNumber__c =: businessPhoneNumber ORDER BY CreatedDate DESC LIMIT 1];
        
    }
    
    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getAllConversationBySearchQuery(String searchQuery, String businessPhoneNumber) {
        // Step 1: Fetch grouped data (CustomerPhone__c, MAX(CustomerName__c))
        String searchKey = '%' + searchQuery + '%';
        return [
            SELECT CustomerPhone__c, MAX(CustomerName__c) MaxName, MAX(CreatedDate) LatestDate
            FROM WhatsApp_Message__c
            WHERE (CustomerPhone__c LIKE :searchKey OR CustomerName__c LIKE :searchKey) AND  BusinessPhoneNumber__c = :businessPhoneNumber
            GROUP BY CustomerPhone__c
        ];
        
    }
    
    @AuraEnabled
    public static List<WhatsApp_Message__c> getWhatsAppMessages(String PhoneNumber, String bussinessPhoneNumber) {
        List<WhatsApp_Message__c> listToReturn =  [
            SELECT Id,ParentMessageID__c ,MessageID__c,Location__Latitude__s,Location__Longitude__s,BusinessPhoneNumber__c, MessageSendType__c, MessageContent__c,MediaId__c, MessageSentTime__c, CustomerName__c, ViewedByAgent__c,
            CreatedDate, MessageType__c, MediaLink__c, CustomerPhone__c, TemplateButtonText__c, TemplateName__c,MessageStatus__c,ConversationExpiration__c,ConversationOrigin__c,PricingBillable__c,PricingCategory__c,PricingModel__c, 
            Reaction__c,TemplateHeaderType__c,TemplateHeaderURL__c, Owner.Name
            FROM WhatsApp_Message__c
            WHERE CustomerPhone__c = :PhoneNumber AND BusinessPhoneNumber__c=:bussinessPhoneNumber
            ORDER BY CreatedDate ASC
        ];
        List<WhatsApp_Message__c> listToUpdate = new List<WhatsApp_Message__c>();
        for(WhatsApp_Message__c wmsg : listToReturn){
            if(wmsg.MessageSendType__c == 'Inbound' && wmsg.ViewedByAgent__c == true){
                listToUpdate.add(wmsg);
            }
            //wmsg.ViewedByAgent__c = false;
        }
        
        if(!listToUpdate.isEmpty()){
            System.debug('listToUpdate==>'+listToUpdate);
            update listToUpdate;
            WhatsAppRequestController.refreshLwcCmpChatsWithoutNotify();
        }
        
        return listToReturn;
    }
    
    @AuraEnabled
    public static List<String> getTaskPicklistValues(String objectName, String fieldName) {
        List<String> picklistValues = new List<String>();
        
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        
        Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();
        
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            picklistValues.add(entry.getLabel());
        }
        
        return picklistValues;
    }
    
    @AuraEnabled
    public static List<WhatsAppMetaTemplate__c> getTemplatepicklistRecord(String category) {
        system.debug('category===>'+category);
        //return [SELECT MasterLabel,DeveloperName FROM MetaTemplates__mdt WHERE Template_Type__c =: templateType];
        return [select Id , SubCategory__c,Template_Name__c,Category__c
                from WhatsAppMetaTemplate__c WHERE SubCategory__c != null AND Template_Name__c != null AND Category__c =:category];
    }
    @AuraEnabled
    public static String getTemplateJSON(String templateName) {
        system.debug('templateName===>'+templateName);
        WhatsAppMetaTemplate__c template =  [select Id , Template_Name__c,TemplateJSON__c from WhatsAppMetaTemplate__c 
                                             WHere Template_Name__c=:templateName LIMIT 1];
        system.debug('template===>'+template);
        return template.TemplateJSON__c;
    }
    
    @AuraEnabled
    public static String sendMediaFile(String fileName, String base64Data, String bussinessPhoneNumber, String Phone , String fileType,String customerName) {
        System.debug('File Name:===> ' + fileName);
        System.debug('Base64 Data: ' + base64Data);
        System.debug('File Type: ' + fileType);
        
        // Create ContentVersion record
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName;
        contentVersion.PathOnClient = fileName;
        contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);
        insert contentVersion;
        
        ContentDistribution distributionRecord = new ContentDistribution();
        distributionRecord.ContentVersionId = contentVersion.Id;
        distributionRecord.Name = contentVersion.Title;
        distributionRecord.PreferencesNotifyOnVisit = false;
        distributionRecord.PreferencesAllowViewInBrowser = true;
        distributionRecord.PreferencesAllowOriginalDownload = true;
        insert distributionRecord;
        
        ContentDistribution conDist = [SELECT Id,ContentDownloadUrl  FROM ContentDistribution WHERE Id=:distributionRecord.Id];
        String callOutString = Phone +'@@'+ bussinessPhoneNumber+'@@'+conDist.ContentDownloadUrl+'@@'+fileType+'@@'+contentVersion.Id+'@@'+customerName;
        return contentVersion.Id;
        
    }
    
    
    
    @AuraEnabled
    public static void refreshLwc(String OwnerUserId){
        System.debug('Event called');
        WhatsappRefresher__e eventBusObj = new WhatsappRefresher__e();
        eventBusObj.OwnerId_UserId__c = OwnerUserId;
        EventBus.publish(eventBusObj);
        System.debug('Event called2'+ EventBus.publish(eventBusObj));
        
    }
    
    // create Task Code
    
    @AuraEnabled
    public static String createTask(Id whatId, String subject, String status, Date dueDate) {
        System.debug('WhatId: ' + whatId);
        System.debug('Subject: ' + subject);
        System.debug('Status: ' + status);
        System.debug('DueDate: ' + dueDate);
        
        // Validation
        if (String.isEmpty(subject)) {
            return 'Error: Subject is required.';
        }
        if (String.isEmpty(status)) {
            return 'Error: Status is required.';
        }
        if (whatId == null) {
            return 'Error: Related record ID (whatId) is required.';
        }
        
        try {
            Task t = new Task();
            t.OwnerId = UserInfo.getUserId();    // Assigned to current user
            t.Status = status;
            t.Subject = subject;
            t.Priority = 'Normal';
            t.ActivityDate = dueDate;            // Due Date
            t.WhatId = whatId;                   // Related to whatsappuser__c
            //t.WhoId																		
            
            insert t;
            
            return 'Success';
        } catch (Exception e) {
            System.debug('Error while creating task: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }
    
    
    
    
    @AuraEnabled(cacheable=true)
    public static List<Task> userTaskData(String userId) {
        
        List<Task> taskList = new List<Task>();
        
        
        if (String.isEmpty(userId)) {
            System.debug('userId is null or empty. Returning empty task list.');
            return taskList;
        }
        
        try {
            System.debug('Fetching tasks for WhatId (whatsappuser__c) = ' + userId);
            
            taskList = [
                SELECT Id, CreatedDate, Description, Subject, Owner.Name
                FROM Task
                WHERE WhatId = :userId
                ORDER BY CreatedDate DESC
            ];
            
            System.debug('Tasks fetched: ' + taskList.size());
        } catch (Exception e) {
            System.debug(' Error fetching tasks: ' + e.getMessage());
        }
        
        return taskList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getSavedTags(String userId) {
        System.debug('userId====>' + userId);
        if (String.isBlank(userId)) return new List<String>();
        
        WhatsappUser__c user = [SELECT Id, Tags_Data__c FROM WhatsappUser__c WHERE Id = :userId LIMIT 1];
        System.debug('user' + user);
        if (String.isBlank(user.Tags_Data__c)) return new List<String>();
        
        return new List<String>(new Set<String>(user.Tags_Data__c.split(',')));
    }
    
    
    
    @AuraEnabled  
    public static void saveAllTagsData(String userId, List<String> tags) {
        System.debug('Incoming tags: ' + tags);
        
        if (String.isBlank(userId) || tags == null) {
            throw new AuraHandledException('Invalid input data.');
        }
        
        try {
            
            WhatsappUser__c userRecord = [
                SELECT Id, Tags_Data__c
                FROM WhatsappUser__c
                WHERE Id = :userId
                LIMIT 1
            ];
            
            
            String updatedTags = String.join(tags, ',');
            System.debug('Final tags string to save: ' + updatedTags);
            userRecord.Tags_Data__c = updatedTags;
            update userRecord;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving tag data: ' + e.getMessage());
        }
    }
    
    
}