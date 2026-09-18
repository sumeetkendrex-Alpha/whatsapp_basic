public class ChampranWhatsapp {
  public static void SendWelcomeMessage(Set<Id> msgIdsbatch) {
        
         List<WhatsApp_Message__c> newMessages = [Select ID,MessageContent__c,CustomerName__c,CustomerPhone__c,BusinessPhoneNumber__c, MessageSendType__c from WhatsApp_Message__c WHERE Id=:msgIdsbatch];
  
     Set<String> customerPhones = new Set<String>();
        Set<String> businessPhones = new Set<String>();
        Set<String> customerName = new Set<String>();
        
        for (WhatsApp_Message__c msg : newMessages) {
            if (msg.CustomerPhone__c != null && msg.BusinessPhoneNumber__c != null && msg.MessageSendType__c=='Inbound') {
                    customerPhones.add(msg.CustomerPhone__c);
                    businessPhones.add(msg.BusinessPhoneNumber__c);
                    customerName.add(msg.CustomerName__c);
                }
        }
        
          List<WhatsApp_Message__c> oldMessages = [Select ID,CustomerPhone__c,BusinessPhoneNumber__c, MessageSendType__c from WhatsApp_Message__c WHERE
                                                 CustomerPhone__c=:customerPhones AND BusinessPhoneNumber__c=:businessPhones AND MessageSendType__c='Outbound'];
        system.debug('oldMessages===>'+oldMessages);
        if(!oldMessages.isEmpty()){
            system.debug('He is purana Customer===>');
        } else{
            system.debug(' New Customer===>'+System.Label.Library_Name);
            String Libranyname =System.Label.Library_Name;
            system.debug(' New Libranyname===>'+Libranyname);
            
            List<ContentWorkspace> workspaceList = [SELECT Id,Name FROM ContentWorkspace WHERE Name =:Libranyname LIMIT 1];
            system.debug('workspaceList===>'+workspaceList);
            if (!workspaceList.isEmpty()) {
                Id workspaceId = workspaceList[0].Id;
                List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :workspaceId];
                system.debug('docLinks===>'+docLinks);
                Set<Id> docIds = new Set<Id>();
                for (ContentDocumentLink link : docLinks) {
                    docIds.add(link.ContentDocumentId);
                }
                system.debug('docIds===>'+docIds);
                if (!docIds.isEmpty()) {
                    List<ContentVersion> versionList = [SELECT Id, ContentDocumentId, FileExtension FROM ContentVersion WHERE ContentDocumentId IN :docIds 
                                                        AND FileExtension IN ('JPG', 'PNG', 'JPEG', 'GIF') ORDER BY LastModifiedDate DESC];
                    system.debug('versionList===>'+versionList);
                    
                    Set<Id> contentVersionIds = new Set<Id>();
                    for (ContentVersion version : versionList) {
                        contentVersionIds.add(version.Id);
                    }
                    
                    if (!contentVersionIds.isEmpty()) {
                        List<String> urls = new List<String>();
                        for (ContentDistribution cd : [SELECT ContentVersionId, ContentDownloadUrl FROM ContentDistribution 
                                                       WHERE ContentVersionId IN :contentVersionIds]) {
                                                           urls.add(cd.ContentDownloadUrl);
                                                       }
                        
                        if (!urls.isEmpty()) {
                            List<String> callOutStrings = new List<String>();
                            for (String url : urls) {
                                String callOutString = customerPhones + '@@' + businessPhones + '@@' + url + '@@image@@' + null + '@@' + null + '@@' + customerName;
                                callOutStrings.add(callOutString);
                            }
                            system.debug('callOutStrings===>'+callOutStrings);
                            system.debug('callOutStrings===>'+callOutStrings.size());
                            
                          //  WhatsAppBatchStarter.startBatches(callOutStrings);

                            
                            SendWhatsAppMessageBatch batch = new SendWhatsAppMessageBatch(callOutStrings);
                            Database.executeBatch(batch, 1);
                        }
                    }
                }
            }
        }
    }
}