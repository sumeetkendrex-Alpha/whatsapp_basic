public class ContentDocumentHandler {
    public static void createDistribution(List<ContentDocument> newContentDocList) {
        system.debug('Trigger==>'+newContentDocList);
        Set<Id> documentIds = new Set<Id>();
        Set<Id> versionId = new Set<Id>();
        for (ContentDocument doc : newContentDocList) {
            if (doc.Id != null) {
                documentIds.add(doc.Id);
            }
            if(doc.LatestPublishedVersionId != null){
                versionId.add(doc.LatestPublishedVersionId );
            }
        }
        system.debug('documentIds==>'+documentIds);
                system.debug('versionId==>'+versionId);

        if(versionId!= null){
            List<ContentVersion> latestVersions = [SELECT Id, Title, ContentDocumentId, IsLatest FROM ContentVersion
                                                   WHERE Id IN : versionId];
            system.debug('latestVersions==>'+latestVersions);  
            List<ContentDistribution> distributionsToCreate = new List<ContentDistribution>();
            if(!latestVersions.isEmpty()){
                for (ContentVersion version : latestVersions) {
                    ContentDistribution dist = new ContentDistribution(
                        Name = version.Title,
                        ContentVersionId = version.Id,
                        PreferencesAllowViewInBrowser = true,
                        PreferencesLinkLatestVersion = true,
                        PreferencesNotifyOnVisit = false,
                        PreferencesPasswordRequired = false
                    );
                    distributionsToCreate.add(dist);
                }
                
                if (!distributionsToCreate.isEmpty()) {
                    system.debug('Before Insert==>'+distributionsToCreate);
                    insert distributionsToCreate;
                    system.debug('Afters Insert==>'+distributionsToCreate);
                }
            }
            
        }
    }
}