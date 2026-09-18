public class WhatsAppCaseHandler {
  /*  public static void afterCaseInsert(Set<Id> msgIds) {
        List<WhatsApp_Message__c> messages = [
            SELECT Id, Account__c, InteractiveDetail__c 
            FROM WhatsApp_Message__c 
            WHERE Id IN :msgIds
        ];

        List<Case> casesToInsert = new List<Case>();

        for (WhatsApp_Message__c msg : messages) {
            if (String.isNotBlank(msg.InteractiveDetail__c)) {
                try {
                    Map<String, Object> detailMap = 
                        (Map<String, Object>) JSON.deserializeUntyped(msg.InteractiveDetail__c);

                    Case newCase = new Case();
                    newCase.AccountId = msg.Account__c;

                    // Subject
                    newCase.Subject = (String) detailMap.get('screen_0_Subject_0');

                    // Complaint_Type__c - extract only value after underscore
                    String complaintTypeRaw = (String) detailMap.get('screen_0__Complaint_Type_1');
                    if (String.isNotBlank(complaintTypeRaw)) {
                        List<String> parts = complaintTypeRaw.split('_');
                        newCase.Complaint_Type__c = parts.size() > 1 ? parts[1] : complaintTypeRaw;
                    }

                    newCase.Description = (String) detailMap.get('screen_0_Description_2');

                    newCase.Status = 'New';
                    newCase.RecordTypeId = '012GB000001VnbeYAC';
                    newCase.Origin='WhatsApp';

                    casesToInsert.add(newCase);
                } catch (Exception e) {
                    System.debug('Error parsing InteractiveDetail__c: ' + e.getMessage());
                }
            }
        }

        if (!casesToInsert.isEmpty()) {
            insert casesToInsert;
            System.debug('casesToInsert: ' + casesToInsert);
        }
    }*/
}