public with sharing class StandardMessageController {
    @AuraEnabled(cacheable=true)
    public static List<StanderdMessage__c> getStandardMessages() {
        return [
            SELECT Id, Name__c, Description__c
            FROM StanderdMessage__c
        ];
    }
}