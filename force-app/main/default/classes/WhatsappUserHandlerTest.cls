@isTest
public class WhatsappUserHandlerTest {
    
    @TestSetup
    public static void setupTestData() {
        List<WhatsAppUser__c> testUsers = new List<WhatsAppUser__c>();
        testUsers.add(new WhatsappUser__c(
            CustomerPhone__c = '+1234567890',
            BusinessNumber__c = 'Business1'
        ));
        testUsers.add(new WhatsappUser__c(
            CustomerPhone__c = '+1987654321',
            BusinessNumber__c = 'Business2'
        ));
        insert testUsers;
    }
    
    @isTest
   public static void testHandleBeforeInsert_NoDuplicates() {
        List<WhatsAppUser__c> newUsers = new List<WhatsAppUser__c>();
        newUsers.add(new WhatsAppUser__c(
            CustomerPhone__c = '+1111111111',
            BusinessNumber__c = 'Business1'
        ));
        newUsers.add(new WhatsAppUser__c(
            CustomerPhone__c = '+1234567890', 
            BusinessNumber__c = 'Business3'  
        ));
        
        Test.startTest();
        WhatsappUserHandler.handleBeforeInsert(newUsers);
        Test.stopTest();
        
        for(WhatsappUser__c user : newUsers) {
            System.assert(!user.hasErrors(), 'No errors should be present for non-duplicate records');
        }
    }
    
    @isTest
  public static void testHandleBeforeInsert_WithDuplicates() {
        List<WhatsAppUser__c> duplicateUsers = new List<WhatsAppUser__c>();
        duplicateUsers.add(new WhatsappUser__c(
            CustomerPhone__c = '+1234567890', 
            BusinessNumber__c = 'Business1'   
        ));
        duplicateUsers.add(new WhatsAppUser__c(
            CustomerPhone__c = '+1987654321', 
            BusinessNumber__c = 'Business2'  
        ));
        
        Test.startTest();
        WhatsappUserHandler.handleBeforeInsert(duplicateUsers);
        Test.stopTest();
        
        for(WhatsAppUser__c user : duplicateUsers) {
            System.assert(user.hasErrors(), 'Errors should be present for duplicate records');
            System.assertEquals(
                'This customer phone already exists for the same business. Duplicate not allowed.',
                user.getErrors()[0].getMessage(),
                'Correct error message should be set'
            );
        }
    }
    
    @isTest
  public static void testHandleBeforeInsert_NullValues() {
        List<WhatsAppUser__c> newUsers = new List<WhatsAppUser__c>();
        newUsers.add(new WhatsAppUser__c(
            CustomerPhone__c = null,
            BusinessNumber__c = 'Business1'
        ));
        newUsers.add(new WhatsAppUser__c(
            CustomerPhone__c = '+1234567890',
            BusinessNumber__c = null
        ));
        newUsers.add(new WhatsAppUser__c(
            CustomerPhone__c = null,
            BusinessNumber__c = null
        ));
        
        Test.startTest();
        WhatsappUserHandler.handleBeforeInsert(newUsers);
        Test.stopTest();
        
        for(WhatsAppUser__c user : newUsers) {
            System.assert(!user.hasErrors(), 'No errors should be present for records with null values');
        }
    }
    
    @isTest
   public static void testHandleBeforeInsert_BulkOperation() {
        List<WhatsAppUser__c> bulkUsers = new List<WhatsAppUser__c>();
        for(Integer i = 0; i < 100; i++) {
            if(i < 50) {
                bulkUsers.add(new WhatsAppUser__c(
                    CustomerPhone__c = '+11111111' + String.valueOf(i).leftPad(2, '0'),
                    BusinessNumber__c = 'Business' + i
                ));
            } else {
                bulkUsers.add(new WhatsAppUser__c(
                    CustomerPhone__c = '+1234567890', 
                    BusinessNumber__c = 'Business1'  
                ));
            }
        }
        
        Test.startTest();
        WhatsappUserHandler.handleBeforeInsert(bulkUsers);
        Test.stopTest();
        
        for(Integer i = 0; i < bulkUsers.size(); i++) {
            WhatsAppUser__c user = bulkUsers[i];
            if(i < 50) {
                System.assert(!user.hasErrors(), 'Non-duplicate records should not have errors');
            } else {
                System.assert(user.hasErrors(), 'Duplicate records should have errors');
            }
        }
    }
}