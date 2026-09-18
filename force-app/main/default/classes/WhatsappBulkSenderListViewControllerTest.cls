@isTest
private class WhatsappBulkSenderListViewControllerTest {

    @isTest
   public static void testGetTemplateById() {
        WhatsAppMetaTemplate__c template = new WhatsAppMetaTemplate__c(
            Template_Name__c = 'Test Template',
            TemplateJSON__c = '{"text": "Hello World"}'
        );
        insert template;

        Test.startTest();
        WhatsAppMetaTemplate__c result = WhatsappBulkSenderListViewController.getTemplateById(template.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Template should not be null');
        System.assertEquals(template.Id, result.Id, 'Returned template ID should match inserted record');
        System.assertEquals('Test Template', result.Template_Name__c, 'Template name should match');
    }

    @isTest
   public static void testGetUsers() {
        List<WhatsappUser__c> userList = new List<WhatsappUser__c>();
        for (Integer i = 0; i < 5; i++) {
            userList.add(new WhatsappUser__c(
                BusinessNumber__c = 'BN-' + i,
                CustomerPhone__c = '999000' + i,
                CustomerName__c = 'User ' + i
            ));
        }
        insert userList;

        Test.startTest();
        List<WhatsappUser__c> result = WhatsappBulkSenderListViewController.getUsers();
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'User list should not be empty');
        System.assert(result.size() <= 4900, 'Returned user list should not exceed limit');
        System.assertNotEquals(null, result[0].CustomerPhone__c, 'Customer phone should not be null');
    }
}