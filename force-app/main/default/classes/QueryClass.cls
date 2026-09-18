/**
* @File Name : QueryClass.cls
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

public with sharing class QueryClass {
    @AuraEnabled
    public static List<sobject> getRecords(String query){
        try {
            if(query == null || String.isBlank(query)){
                return null;
            }
            query = query.trim();
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}