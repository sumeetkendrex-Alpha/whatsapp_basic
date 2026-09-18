@IsTest
private class WhatsAppMessageInboundTest {
    @IsTest
    static void deserializeSuccessPayload() {
        String payload = '{"entry":[{"id":"entry-1","changes":[{"field":"messages","value":{"messaging_product":"whatsapp","metadata":{"display_phone_number":"15550001111","phone_number_id":"phone-1"},"contacts":[{"profile":{"name":"Test Customer"},"wa_id":"15550002222"}],"messages":[{"from":"15550002222","id":"message-1","timestamp":"1700000000","type":"text","text":{"body":"Hello"}}]}}]}]}';

        WhatsAppMessageInbound result = (WhatsAppMessageInbound) JSON.deserialize(payload, WhatsAppMessageInbound.class);

        System.assertEquals('entry-1', result.entry[0].id);
        System.assertEquals('15550002222', result.entry[0].changes[0].value.contacts[0].wa_id);
        System.assertEquals('Hello', result.entry[0].changes[0].value.messages[0].text.body);
    }
}