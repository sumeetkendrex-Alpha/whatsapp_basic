public with sharing class WhatsappMultiImageSenderController {
    @AuraEnabled
    public static List<String> createPublicLinksFromVersions(List<Id> contentVersionIds, String customerName, String phoneNumber, String businessNumber) {
       system.debug('contentVersionIds==>'+contentVersionIds);
        // Step 1: Get ContentDocumentIds from ContentVersionIds
        Map<Id, Id> versionToDocumentMap = new Map<Id, Id>();
        for (ContentVersion version : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionIds]) {
            versionToDocumentMap.put(version.Id, version.ContentDocumentId);
        }
       system.debug('versionToDocumentMap==>'+versionToDocumentMap);
        // Step 2: Create ContentDistributions
        List<ContentDistribution> distributions = new List<ContentDistribution>();
        for (Id docId : versionToDocumentMap.KeySet()) {
            distributions.add(new ContentDistribution(
                Name = 'Public Link for Document',
                contentVersionId = docId,
                PreferencesAllowViewInBrowser = true,
                PreferencesAllowOriginalDownload = true,
                PreferencesNotifyOnVisit = false
            ));
        }
        insert distributions;
       system.debug('distributions==>'+distributions);
        List<String> publicUrls = new List<String>();
        for (ContentDistribution dist : [SELECT DistributionPublicUrl,ContentDownloadUrl FROM ContentDistribution WHERE Id IN :distributions]) {
            publicUrls.add(dist.ContentDownloadUrl);
        }
       system.debug('publicUrls==>'+publicUrls);
        for(String urls :publicUrls){
           String callOutString = phoneNumber +'@@'+ businessNumber+'@@'+urls+'@@'+'image'+'@@'+null+'@@'+null+'@@'+customerName;
            WhatsAppOutgoingMessage.sendMediaMessage(callOutString);
        }
        return publicUrls;
    }
}