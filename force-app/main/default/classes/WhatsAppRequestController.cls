/**
* @File Name : WhatsAppRequestController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 11, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 11, 2024 |   | Initial Version
**/

public class WhatsAppRequestController {
  @AuraEnabled
public static List<WhatsappUser__c> getUnmatchedNewWhatsAppMessages() {
    // Fetch all WhatsappUser records with a non-null phone
    List<WhatsappUser__c> whatsAppUserList = [
        SELECT Id, BusinessNumber__c, CustomerName__c, CustomerPhone__c ,CreatedDate 
        FROM WhatsappUser__c 
        WHERE CustomerPhone__c != null
    ];

    Set<String> phoneNumbers = new Set<String>();
    for (WhatsappUser__c message : whatsAppUserList) {
        phoneNumbers.add(message.CustomerPhone__c);
    }

    // Fetch phone numbers from Account, Contact, and Lead objects
    Set<String> matchedPhones = new Set<String>();
    
    for (Account acc : [SELECT Phone FROM Account WHERE Phone IN :phoneNumbers]) {
        if (acc.Phone != null) matchedPhones.add(acc.Phone);
    }
    for (Contact con : [SELECT Phone FROM Contact WHERE Phone IN :phoneNumbers]) {
        if (con.Phone != null) matchedPhones.add(con.Phone);
    }
    for (Lead lead : [SELECT Phone FROM Lead WHERE Phone IN :phoneNumbers]) {
        if (lead.Phone != null) matchedPhones.add(lead.Phone);
    }

    // Filter out matched WhatsappUser records
    List<WhatsappUser__c> finalWhatsappMessageList = new List<WhatsappUser__c>();
    for (WhatsappUser__c user : whatsAppUserList) {
        if (!matchedPhones.contains(user.CustomerPhone__c)) {
            finalWhatsappMessageList.add(user);
        }
    }

    return finalWhatsappMessageList;
}


    
    @AuraEnabled
    public static String redirectToWhatsappChatActivity(String businessNumber, String customerPhone) {
        WhatsappUser__c wca = [SELECT Id FROM WhatsappUser__c WHERE CustomerPhone__c = :customerPhone AND BusinessNumber__c =: businessNumber LIMIT 1];
        List<WhatsApp_Message__c> listToReturn =  [
            SELECT Id
            FROM WhatsApp_Message__c
            WHERE CustomerPhone__c = :customerPhone AND BusinessPhoneNumber__c=:businessNumber ORDER BY CreatedDate ASC
        ];
        return wca.Id;
    }
    
    @AuraEnabled
    public static String createLead(String customerName, String customerPhone) {
        if (String.isBlank(customerName)) {
            throw new AuraHandledException('Customer name cannot be null or empty.');
        }
        if (String.isBlank(customerPhone)) {
            throw new AuraHandledException('Customer phone cannot be null or empty.');
        }
        
        Lead newLead = new Lead();
        newLead.LastName = customerName;
        newLead.Phone = customerPhone;
        newLead.OwnerId = UserInfo.getUserId();
        newLead.Status = 'New';
        newLead.Company = 'Unknown';
        newLead.LeadSource ='WhatsApp';
        
        try {
            insert newLead;
            refreshLwcCmpChatsWithoutNotify();
        } catch (DmlException e) {
            throw new AuraHandledException('Error creating lead: ' + e.getMessage());
        }
        return newLead.Id;
    }
    
    
    @AuraEnabled
    public static void refreshLwcCmpChatsMethod(){
        system.debug('refreshEvent');
        WhatsApp_Notify_Lwc__e eventBusObj = new WhatsApp_Notify_Lwc__e();
        EventBus.publish(eventBusObj);
    }
    
    @AuraEnabled
    public static void refreshLwcCmpChatsWithoutNotify(){
        system.debug('refreshEvent2');
        Whatsapp_Request_Lwc__e eventBusObj = new Whatsapp_Request_Lwc__e();
        EventBus.publish(eventBusObj);
    }
    
}