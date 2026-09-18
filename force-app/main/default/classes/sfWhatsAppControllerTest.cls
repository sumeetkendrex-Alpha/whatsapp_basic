@IsTest
private class sfWhatsAppControllerTest {
    @IsTest
    static void controllerSuccessPaths() {
        WhatsappUser__c user = new WhatsappUser__c(
            CustomerName__c = 'Test Customer',
            CustomerPhone__c = '15550002222',
            BusinessNumber__c = '15550001111'
        );
        insert user;

        WhatsAppMessagingSession__c session = new WhatsAppMessagingSession__c(
            Status__c = 'Active',
            StartTime__c = System.now(),
            EndTIme__c = System.now().addHours(1),
            CustomerName__c = user.CustomerName__c,
            CustomerPhone__c = user.CustomerPhone__c,
            BusinessPhoneNumber__c = user.BusinessNumber__c,
            WhatsappUser__c = user.Id
        );
        insert session;

        WhatsApp_Message__c message = new WhatsApp_Message__c(
            CustomerName__c = user.CustomerName__c,
            CustomerPhone__c = user.CustomerPhone__c,
            BusinessPhoneNumber__c = user.BusinessNumber__c,
            WhatsApp_Messaging_Session__c = session.Id,
            MessageID__c = 'message-controller-1',
            MessageContent__c = 'Hello from WhatsApp',
            MessageType__c = 'text',
            MessageSendType__c = 'Inbound',
            MessageStatus__c = 'received',
            MessageSentTime__c = System.now(),
            ViewedByAgent__c = false
        );
        insert message;

        Test.startTest();
        List<sfWhatsAppController.ContactInfo> contacts = sfWhatsAppController.getContactsByBusinessNumber(user.BusinessNumber__c);
        List<sfWhatsAppController.MessageInfo> messages = sfWhatsAppController.getMessagesForContact(user.CustomerPhone__c, user.BusinessNumber__c);
        sfWhatsAppController.markMessagesViewed(user.CustomerPhone__c, user.BusinessNumber__c);
        List<sfWhatsAppController.BusinessInfo> businesses = sfWhatsAppController.getActiveBusinesses();
        Test.stopTest();

        System.assertEquals(1, contacts.size());
        System.assertEquals(1, contacts[0].unread);
        System.assertEquals('Hello from WhatsApp', contacts[0].lastMessageText);
        System.assertEquals(1, messages.size());
        System.assertEquals('them', messages[0].fromWho);
        System.assertEquals('Hello from WhatsApp', messages[0].text);
        System.assertNotEquals(null, businesses);
        System.assertEquals(true, [SELECT ViewedByAgent__c FROM WhatsApp_Message__c WHERE Id = :message.Id].ViewedByAgent__c);
    }
}