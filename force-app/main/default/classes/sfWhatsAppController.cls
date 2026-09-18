public with sharing class sfWhatsAppController {
    @AuraEnabled(cacheable=true)
    public static List<BusinessInfo> getActiveBusinesses() {
        List<BusinessInfo> results = new List<BusinessInfo>();
        for (WhatsappMeta__mdt meta : [
            SELECT Id, MasterLabel, Business_Number__c
            FROM WhatsappMeta__mdt
            WHERE Is_Active__c = true
            ORDER BY MasterLabel
        ]) {
            results.add(new BusinessInfo(meta.Id, meta.MasterLabel, meta.Business_Number__c));
        }
        return results;
    }

    public class BusinessInfo {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String businessNumber;

        public BusinessInfo(String id, String name, String businessNumber) {
            this.id = id;
            this.name = name;
            this.businessNumber = businessNumber;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ContactInfo> getContactsByBusinessNumber(String businessNumber) {
        List<ContactInfo> results = new List<ContactInfo>();
        if (String.isBlank(businessNumber)) {
            return results;
        }

        List<WhatsappUser__c> users = [
            SELECT Id, CustomerName__c, CustomerPhone__c, latestDateTime__c
            FROM WhatsappUser__c
            WHERE BusinessNumber__c = :businessNumber
            ORDER BY CustomerName__c
        ];

        Set<Id> userIds = new Set<Id>();
        Set<String> customerPhones = new Set<String>();
        for (WhatsappUser__c u : users) {
            userIds.add(u.Id);
            customerPhones.add(u.CustomerPhone__c);
        }

        Map<String, WhatsApp_Message__c> lastMessageByPhone = new Map<String, WhatsApp_Message__c>();
        if (!customerPhones.isEmpty()) {
            for (WhatsApp_Message__c msg : [
                SELECT CustomerPhone__c, MessageContent__c, MessageType__c, MediaType__c, MessageSentTime__c
                FROM WhatsApp_Message__c
                WHERE BusinessPhoneNumber__c = :businessNumber AND CustomerPhone__c IN :customerPhones
                ORDER BY MessageSentTime__c DESC
            ]) {
                if (!lastMessageByPhone.containsKey(msg.CustomerPhone__c)) {
                    lastMessageByPhone.put(msg.CustomerPhone__c, msg);
                }
            }
        }

        Map<Id, String> latestStatusByUser = new Map<Id, String>();
        if (!userIds.isEmpty()) {
            for (WhatsAppMessagingSession__c sess : [
                SELECT WhatsappUser__c, Status__c
                FROM WhatsAppMessagingSession__c
                WHERE WhatsappUser__c IN :userIds
                ORDER BY StartTime__c DESC
            ]) {
                if (!latestStatusByUser.containsKey(sess.WhatsappUser__c)) {
                    latestStatusByUser.put(sess.WhatsappUser__c, sess.Status__c);
                }
            }
        }

        Map<String, Integer> unreadByPhone = new Map<String, Integer>();
        for (AggregateResult ar : [
            SELECT CustomerPhone__c phone, COUNT(Id) unreadCount
            FROM WhatsApp_Message__c
            WHERE MessageSendType__c = 'Inbound' AND ViewedByAgent__c = false AND BusinessPhoneNumber__c = :businessNumber
            GROUP BY CustomerPhone__c
        ]) {
            unreadByPhone.put((String) ar.get('phone'), (Integer) ar.get('unreadCount'));
        }

        for (WhatsappUser__c u : users) {
            String status = latestStatusByUser.get(u.Id);
            Boolean isOnline = status != null && status != 'Ended';
            Integer unread = unreadByPhone.get(u.CustomerPhone__c);
            WhatsApp_Message__c lastMsg = lastMessageByPhone.get(u.CustomerPhone__c);
            results.add(
                new ContactInfo(
                    u.Id,
                    u.CustomerName__c,
                    u.CustomerPhone__c,
                    u.latestDateTime__c,
                    isOnline,
                    unread != null ? unread : 0,
                    lastMsg != null ? buildMessageText(lastMsg) : null,
                    lastMsg != null ? lastMsg.MessageSentTime__c : null
                )
            );
        }
        return results;
    }

    @AuraEnabled
    public static void markMessagesViewed(String customerPhone, String businessNumber) {
        if (String.isBlank(customerPhone) || String.isBlank(businessNumber)) {
            return;
        }
        List<WhatsApp_Message__c> unviewed = [
            SELECT Id, ViewedByAgent__c
            FROM WhatsApp_Message__c
            WHERE CustomerPhone__c = :customerPhone
            AND BusinessPhoneNumber__c = :businessNumber
            AND MessageSendType__c = 'Inbound'
            AND ViewedByAgent__c = false
        ];
        for (WhatsApp_Message__c msg : unviewed) {
            msg.ViewedByAgent__c = true;
        }
        if (!unviewed.isEmpty()) {
            update unviewed;
        }
    }

    public class ContactInfo {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String phone;
        @AuraEnabled
        public Datetime lastActivity;
        @AuraEnabled
        public Boolean online;
        @AuraEnabled
        public Integer unread;
        @AuraEnabled
        public String lastMessageText;
        @AuraEnabled
        public Datetime lastMessageTime;

        public ContactInfo(
            String id,
            String name,
            String phone,
            Datetime lastActivity,
            Boolean online,
            Integer unread,
            String lastMessageText,
            Datetime lastMessageTime
        ) {
            this.id = id;
            this.name = name;
            this.phone = phone;
            this.lastActivity = lastActivity;
            this.online = online;
            this.unread = unread;
            this.lastMessageText = lastMessageText;
            this.lastMessageTime = lastMessageTime;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<MessageInfo> getMessagesForContact(String customerPhone, String businessNumber) {
        List<MessageInfo> results = new List<MessageInfo>();
        if (String.isBlank(customerPhone) || String.isBlank(businessNumber)) {
            return results;
        }
        for (WhatsApp_Message__c msg : [
            SELECT Id, MessageContent__c, MessageSendType__c, MessageSentTime__c, MessageType__c, MediaType__c, MessageStatus__c
            FROM WhatsApp_Message__c
            WHERE CustomerPhone__c = :customerPhone AND BusinessPhoneNumber__c = :businessNumber
            ORDER BY MessageSentTime__c ASC
        ]) {
            results.add(
                new MessageInfo(
                    msg.Id,
                    msg.MessageSendType__c == 'Outbound' ? 'me' : 'them',
                    buildMessageText(msg),
                    msg.MessageSentTime__c,
                    msg.MessageSendType__c == 'Outbound' ? msg.MessageStatus__c : null
                )
            );
        }
        return results;
    }

    private static String buildMessageText(WhatsApp_Message__c msg) {
        if (String.isNotBlank(msg.MessageContent__c)) {
            return msg.MessageContent__c;
        }
        if (String.isNotBlank(msg.MediaType__c)) {
            return '📎 ' + msg.MediaType__c;
        }
        if (String.isNotBlank(msg.MessageType__c)) {
            return '[' + msg.MessageType__c + ']';
        }
        return '';
    }

    public class MessageInfo {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String fromWho;
        @AuraEnabled
        public String text;
        @AuraEnabled
        public Datetime sentTime;
        @AuraEnabled
        public String status;

        public MessageInfo(String id, String fromWho, String text, Datetime sentTime, String status) {
            this.id = id;
            this.fromWho = fromWho;
            this.text = text;
            this.sentTime = sentTime;
            this.status = status;
        }
    }
}