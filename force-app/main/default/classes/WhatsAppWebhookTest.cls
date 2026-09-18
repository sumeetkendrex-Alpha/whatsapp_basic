@IsTest
private class WhatsAppWebhookTest {
    @IsTest
    static void webhookSuccessRequests() {
        RestRequest getRequest = new RestRequest();
        getRequest.httpMethod = 'GET';
        getRequest.params.put('hub.verify_token', System.Label.SecurityToken);
        getRequest.params.put('hub.challenge', 'challenge-1');
        RestContext.request = getRequest;
        RestContext.response = new RestResponse();

        Test.startTest();
        WhatsAppWebhook.doGet();

        System.assertEquals('challenge-1', RestContext.response.responseBody.toString());

        RestRequest postRequest = new RestRequest();
        postRequest.httpMethod = 'POST';
        postRequest.requestBody = Blob.valueOf('{"entry":[]}');
        RestContext.request = postRequest;
        RestContext.response = new RestResponse();

        WhatsAppWebhook.doPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(1, [SELECT COUNT() FROM MessageLog__c]);
    }
}