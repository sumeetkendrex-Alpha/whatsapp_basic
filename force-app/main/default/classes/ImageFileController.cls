public with sharing class ImageFileController {
    
    @AuraEnabled(cacheable=true)
    public static List<ContentWorkspace> getLibraries() {
        return [SELECT Id, Name FROM ContentWorkspace ORDER BY Name];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ContentVersion> getImagesByLibrary(Id libraryId) {
        Set<Id> docIds = new Set<Id>();
        
        for (ContentDocumentLink link : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :libraryId]) {
            docIds.add(link.ContentDocumentId);
        }
        if (docIds.isEmpty()) return new List<ContentVersion>();
        return [SELECT Id, Title, FileExtension, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :docIds
                AND FileExtension IN ('JPG', 'PNG', 'JPEG', 'GIF') ORDER BY LastModifiedDate DESC];
    }
    
    @AuraEnabled
    public static String processSelectedImages(List<Id> selectedImageIds, String customerName, string customerNumber,String businessNumber) {
        System.debug('Selected Image IDs: ' + selectedImageIds);
        System.debug('Selected Image Count: ' + selectedImageIds.size());
        Set<Id> contentVersionIds = new Set<Id>();
        for (Id contentId : selectedImageIds) {
            contentVersionIds.add(contentId);
        }
        
        if (!contentVersionIds.isEmpty()) {
            List<String> urls = New List<String>();
            Map<Id, ContentDistribution> existingDistributions = new Map<Id, ContentDistribution>();
            for (ContentDistribution cd : [SELECT Id, ContentVersionId, DistributionPublicUrl, ContentDownloadUrl, PdfDownloadUrl FROM ContentDistribution 
                                           WHERE ContentVersionId IN :contentVersionIds]) {
                                               existingDistributions.put(cd.ContentVersionId, cd);
                                               urls.add(cd.ContentDownloadUrl);    
                                           }
            
            List<String> callOutStrings = new List<String>();
            if (!urls.isEmpty()) {
                for (String url : urls) {
                    String callOutString = customerNumber + '@@' + businessNumber + '@@' + url + '@@' + 'image' + '@@' + null + '@@' + null + '@@' + customerName;
                    callOutStrings.add(callOutString);
                }
            }
            if (!callOutStrings.isEmpty()) {
                SendWhatsAppMessageBatch batch = new SendWhatsAppMessageBatch(callOutStrings);
                Database.executeBatch(batch, 100);
            }
        }
        return 'Success';
    }
    
}