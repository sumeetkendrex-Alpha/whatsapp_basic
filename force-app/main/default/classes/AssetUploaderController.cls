public with sharing class AssetUploaderController {
    
    @AuraEnabled
public static Boolean isUserAllowed() {
    return [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name == 'System Administrator';
}


   @AuraEnabled(cacheable=true)
    public static List<ContentWorkspace> getAssetLibraries() {
        return [SELECT Id, Name FROM ContentWorkspace ORDER BY Name];
    }

    @AuraEnabled
    public static Id uploadImageToLibrary(String base64, String fileName, Id libraryId) {
        // Step 1: Check if file already exists in the library
        List<ContentWorkspaceDoc> existing = [
            SELECT ContentDocumentId 
            FROM ContentWorkspaceDoc 
            WHERE ContentWorkspaceId = :libraryId 
            AND ContentDocument.Title = :fileName
        ];

        if (!existing.isEmpty()) {
            throw new AuraHandledException('File with this name already exists in the selected library.');
        }

        // Step 2: Insert ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = '/' + fileName;
        cv.VersionData = EncodingUtil.base64Decode(base64);
        insert cv;
        
          ContentDistribution dist = new ContentDistribution(
                    Name = cv.Title,
                    ContentVersionId = cv.Id,
                    PreferencesAllowViewInBrowser = true,
                    PreferencesLinkLatestVersion = true,
                    PreferencesNotifyOnVisit = false,
                    PreferencesPasswordRequired = false
                );
                Insert dist;

        // Step 3: Get ContentDocumentId
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        // Step 4: Link to Asset Library
        ContentWorkspaceDoc cwd = new ContentWorkspaceDoc();
        cwd.ContentWorkspaceId = libraryId;
        cwd.ContentDocumentId = cv.ContentDocumentId;
        insert cwd;

        return cv.Id;
    }
}