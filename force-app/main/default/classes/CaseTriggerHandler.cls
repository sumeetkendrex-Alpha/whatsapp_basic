public class CaseTriggerHandler {
  /*  public static void sendWhatsappMessage(List<Case> newCaseList){
        if(!newCaseList.isEmpty()){
            Map<String,Case> newCaseMap = new Map<String,Case>();
            for(Case cs : newCaseList){
                if(cs.AccountId != null){
                   	newCaseMap.put(cs.AccountId,cs);
                    //WhatsAppOutgoingMessage.sendTextMessage()
                } 
            }
            User currentUser = [
        SELECT Id, WhatsAppNumber__c 
        FROM User 
        WHERE Id = '005dM000009dswDQAQ' 
        LIMIT 1
    ];
     
            List<Account> listAccount = [SELECT Id, Name,Phone FROM Account WHERE Id IN:newCaseMap.keySet() AND Phone != null AND Name != Null];
            
            for(Account acc : listAccount){
                Case cs = newCaseMap.get(acc.Id);
                String callOutString = acc.Phone+'@@'+currentUser.WhatsAppNumber__c+'@@'+'Hi '+acc.Name+'! 👋 Thank you for reaching out to us. 🙏 ✨ Your case has been successfully created! Here are the details: 📄 Case Number: '+cs.CaseNumber+' 📅 Created On: '+System.Today()+' 📌 Subject: '+cs.Subject+''+'@@'+'text'+'@@'+''+'@@'+''+'@@'+acc.Name;
            	WhatsAppOutgoingMessage.sendMediaMessage(callOutString);
            }
        }
    }*/
    
  public static void sendWhatsappMessage(List<Case> newCaseList) {
    for (Case cs : newCaseList) {
        if (String.isBlank(cs.CustomerName__c)) {
            System.debug('CustomerName__c is blank for Case: ' + cs.Id);
            continue;
        }

        // Split by ':'
        String[] parts = cs.CustomerName__c.split(':');
            System.debug('parts==> ' + parts);
        if (parts.size() < 2) {
            System.debug('Invalid format for CustomerName__c: ' + cs.CustomerName__c);
            continue;
        }

        String customerNumber = parts[0].trim();
        String businessNumber = parts[1].trim();
            System.debug('customerNumber==> ' + customerNumber);
            System.debug('businessNumber==> ' + businessNumber);
List<WhatsappUser__c> wp =[select id,CustomerName__c from 	WhatsappUser__c WHERE CustomerPhone__c =:customerNumber];
       String callOutString = customerNumber+'@@'+businessNumber+'@@'+'Hi  ! 👋 Thank you for reaching out to us. 🙏 ✨ Your case has been successfully created! Here are the details: 📄 Case Number: '+cs.CaseNumber+' 📅 Created On: '+System.Today()+' 📌 Subject: '+cs.Subject+''+'@@'+'text'+'@@'+''+'@@'+''+'@@'+wp[0].CustomerName__c;
            	WhatsAppOutgoingMessage.sendMediaMessage(callOutString);
    }
}

}