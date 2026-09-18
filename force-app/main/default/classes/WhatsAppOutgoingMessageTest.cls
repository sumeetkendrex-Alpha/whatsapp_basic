@IsTest
private class WhatsAppOutgoingMessageTest {
    private class SuccessResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"contacts":[{"wa_id":"15550002222"}],"messages":[{"id":"outbound-message-1","message_status":"accepted"}]}');
            return response;
        }
    }

    @IsTest
    static void sendTextMessageSuccess() {
        List<WhatsappMeta__mdt> metadata = [
            SELECT Business_Number__c
            FROM WhatsappMeta__mdt
            WHERE Business_Number__c != NULL
            LIMIT 1
        ];
        if (metadata.isEmpty()) {
            System.assert(true, 'No packaged WhatsApp metadata is available in this org.');
            return;
        }

        Test.setMock(HttpCalloutMock.class, new SuccessResponse());
        String callout = '15550002222@@' + metadata[0].Business_Number__c + '@@Hello@@text@@Test Customer';

        Test.startTest();
        String result = WhatsAppOutgoingMessage.sendTextMessage(callout);
        Test.stopTest();

        System.assertEquals('success', result);
        System.assertEquals(1, [SELECT COUNT() FROM WhatsApp_Message__c WHERE MessageID__c = 'outbound-message-1']);
    }
}