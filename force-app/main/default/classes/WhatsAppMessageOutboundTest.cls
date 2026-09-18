@IsTest
private class WhatsAppMessageOutboundTest {
    @IsTest
    static void deserializeSuccessPayload() {
        String payload = '{"messaging_product":"whatsapp","contacts":[{"wa_id":"15550002222"}],"messages":[{"id":"message-1","message_status":"accepted"}],"type":"text","text":{"body":"Hello"}}';

        WhatsAppMessageOutbound result = (WhatsAppMessageOutbound) JSON.deserialize(payload, WhatsAppMessageOutbound.class);

        System.assertEquals('15550002222', result.contacts[0].wa_id);
        System.assertEquals('message-1', result.messages[0].id);
        System.assertEquals('Hello', result.text.body);
    }
}