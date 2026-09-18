/**
* @File Name : QueryClass_Test.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : May 6, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 6, 2025 |   | Initial Version
**/

@isTest
Public class QueryClass_Test {

    @isTest
    static void testGetRecordsWithValidQuery() {
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 5];
        Test.startTest();
        List<SObject> result = QueryClass.getRecords('SELECT Id, Name FROM Account LIMIT 5');
        Test.stopTest();
        System.assertEquals(accounts.size(), result.size(), '');
    }

    @isTest
    static void testGetRecordsWithNullQuery() {
        Test.startTest();
        List<SObject> result = QueryClass.getRecords(null);
        Test.stopTest();
        System.assertEquals(null, result,'null');
    }

    @isTest
    static void testGetRecordsWithBlankQuery() {
        Test.startTest();
        List<SObject> result = QueryClass.getRecords('   ');
        Test.stopTest();
        System.assertEquals(null, result,'null');
    }

    @isTest
    static void testGetRecordsWithException() {
        Test.startTest();
        try {
            List<SObject> result = QueryClass.getRecords('SELECT Id FROM Invalid_Object__c');
        } catch(AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(),'null');
        }
        Test.stopTest();
    }
}