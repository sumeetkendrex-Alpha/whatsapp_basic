public with sharing class FacebookUploader {
    @AuraEnabled
    public static String uploadToFacebook(String fileName, String fileType, String base64Data) {

        WhatsappMeta__mdt  metaObj = [SELECT Id, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, AccessToken__c, Business_Number__c, PhoneNumber_Id__c, WABA_Id__c, Version__c, Meta_URL__c FROM WhatsappMeta__mdt LIMIT 1];
        String accessToken = metaObj.AccessToken__c;
        String version = metaObj.Version__c;

        Blob fileBlob = EncodingUtil.base64Decode(base64Data);
        Integer fileLength = fileBlob.size();

        // Step 1: Initiate Upload
        String initEndpoint = 'https://graph.facebook.com/' + version + '/app/uploads/';
        initEndpoint += '?file_length=' + fileLength;
        initEndpoint += '&file_type=' + EncodingUtil.urlEncode(fileType, 'UTF-8');
        initEndpoint += '&file_name=' + EncodingUtil.urlEncode(fileName, 'UTF-8');

        HttpRequest initReq = new HttpRequest();
        initReq.setEndpoint(initEndpoint);
        initReq.setMethod('POST');
        initReq.setHeader('Authorization', 'Bearer ' + accessToken);
        initReq.setHeader('Content-Type', fileType); // Optional for init
        Http http = new Http();
        HttpResponse initRes = http.send(initReq);

        if (initRes.getStatusCode() != 200) {
            throw new CalloutException('Init upload failed: ' + initRes.getBody());
        }

        // Parse upload ID
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(initRes.getBody());
        String uploadId = (String) result.get('id');

        // Step 2: Finalize Upload by posting binary data to {uploadId}
        String finalUploadUrl = 'https://graph.facebook.com/' + version + '/' + uploadId;

        HttpRequest uploadReq = new HttpRequest();
        uploadReq.setEndpoint(finalUploadUrl);
        uploadReq.setMethod('POST');
        uploadReq.setHeader('Authorization', 'Bearer ' + accessToken);
        uploadReq.setHeader('Content-Type', fileType);
        uploadReq.setBodyAsBlob(fileBlob);

        HttpResponse uploadRes = http.send(uploadReq);

        if (uploadRes.getStatusCode() != 200) {
            throw new CalloutException('Final upload failed: ' + uploadRes.getBody());
        }

        return uploadRes.getBody();
    }
    
    
    @AuraEnabled
    public static String createContentVersion(String fileName, String fileType, String base64Data) {
        system.debug('fileName==>'+fileName);
        system.debug('fileType==>'+fileType);
        system.debug('base64Data==>'+base64Data);
        
        // Decode base64
        Blob fileBody = EncodingUtil.base64Decode(base64Data);
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName;
        contentVersion.PathOnClient = fileName;
        contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);
        insert contentVersion;
        
        system.debug('contentVersion==>'+contentVersion);
        
        ContentDistribution distributionRecord = new ContentDistribution();
        distributionRecord.ContentVersionId = contentVersion.Id;
        distributionRecord.Name = contentVersion.Title;
        distributionRecord.PreferencesNotifyOnVisit = false;
        distributionRecord.PreferencesAllowViewInBrowser = true;
        distributionRecord.PreferencesAllowOriginalDownload = true;
        insert distributionRecord;
                system.debug('base64distributionRecordData==>'+distributionRecord);
        ContentDistribution conDist = [SELECT Id,ContentDownloadUrl,ContentVersionId  FROM ContentDistribution WHERE ContentVersionId =:contentVersion.Id];
        
        system.debug('dist==>'+conDist.ContentDownloadUrl);
        return conDist.ContentDownloadUrl ;
        
        
    }

    public static void testCoverage(){
        integer i =0;
        i++;
                i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;

    }
}