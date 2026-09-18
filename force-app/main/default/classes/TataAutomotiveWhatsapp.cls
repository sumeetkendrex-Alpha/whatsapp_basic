public class TataAutomotiveWhatsapp{
    
  /*  public static void handleMessage(Set<Id> msgIds) {
        List<WhatsApp_Message__c> newMessages = [
            SELECT Id, BusinessPhoneNumber__c, CustomerName__c, TemplateButtonPayload__c, OrderNumber__c, 
            TemplateButtonText__c, Account__c, MessageID__c, CustomerPhone__c, MessageType__c, 
            MessageSendType__c, ParentMessageID__c, MessageContent__c,MediaId__c
            FROM WhatsApp_Message__c
            WHERE Id IN :msgIds];
        
        // Collect unique customer phone numbers
        Set<String> customerPhones = new Set<String>();
        String whatsappUser ='';
        String accountId = '';
        for (WhatsApp_Message__c msg : newMessages) {
            if (msg.CustomerPhone__c != null) {
                customerPhones.add(msg.CustomerPhone__c);
            }
            if(msg.MessageContent__c=='Hi'||msg.MessageContent__c=='Hello'){
                String JsonBody ='{"messaging_product":"whatsapp","to":"'+msg.CustomerPhone__c+'","type":"template","template":{"name":"tata_welcome","language":{"code":"en"},"components":[{"type":"body","parameters":[{"type":"text","text":"'+msg.CustomerName__c+'"}]}]}}';
                String calloutString = msg.CustomerPhone__c+'@@'+msg.BusinessPhoneNumber__c+'@@'+JsonBody+'@@'+'WelcomeTemplate'+'@@'+null+'@@'+null+'@@'+msg.CustomerName__c;
                WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
            }
        }
        
        // Fetch the most recent outbound message per customer
        Map<String, WhatsApp_Message__c> latestOutboundMessages = new Map<String, WhatsApp_Message__c>();
        Map<String, WhatsApp_Message__c> latestOutboundMessages2 = new Map<String, WhatsApp_Message__c>();
        if (!customerPhones.isEmpty()) {
            List<WhatsApp_Message__c> outboundMessages = [
                SELECT Id, CustomerPhone__c,MessageID__c, MessageContent__c, MessageSendType__c,MediaId__c,TemplateButtonPayload__c ,CreatedDate
                FROM WhatsApp_Message__c
                WHERE CustomerPhone__c IN :customerPhones AND MessageSendType__c = 'Outbound'
                ORDER BY CreatedDate DESC
            ];
            List<WhatsApp_Message__c> outboundMessages2 = [
                SELECT Id, CustomerPhone__c,MessageID__c, MessageContent__c, MessageSendType__c,MediaId__c,TemplateButtonPayload__c ,CreatedDate
                FROM WhatsApp_Message__c
                WHERE CustomerPhone__c IN :customerPhones AND MessageSendType__c = 'Outbound'
                
            ];
            
            List<WhatsappUser__c> whatsappuserList = [select id, CustomerPhone__c from WhatsappUser__c WHERE CustomerPhone__c=:customerPhones];
            for(WhatsappUser__c wp : whatsappuserList){
                whatsappUser = wp.Id;
            }
            
            List<Account> accList = [select id, Phone from Account WHERE Phone=:customerPhones];
            for(Account acc : accList){
                accountId=acc.Id;
            }
            
            for (WhatsApp_Message__c msg : outboundMessages) {
                if (!latestOutboundMessages.containsKey(msg.CustomerPhone__c)) {
                    latestOutboundMessages.put(msg.CustomerPhone__c, msg);
                }
            }
            for (WhatsApp_Message__c msg : outboundMessages2) {
                if (!latestOutboundMessages2.containsKey(msg.CustomerPhone__c)) {
                    latestOutboundMessages2.put(msg.MessageID__c, msg);
                }
            }
        }
        system.debug('latestOutboundMessages2'+latestOutboundMessages2);
        
        // Debugging or further processing
        for (WhatsApp_Message__c newMsg : newMessages) {
            if (latestOutboundMessages.containsKey(newMsg.CustomerPhone__c)) {
                WhatsApp_Message__c previousOutbound = latestOutboundMessages.get(newMsg.CustomerPhone__c);
                System.debug('Previous Outbound Message for ' + newMsg.CustomerPhone__c + ': ' + previousOutbound.MessageContent__c);
                if(previousOutbound.TemplateButtonPayload__c=='jobcard'){
                    List<WorkOrder> wrkOrd = [select Id, WorkOrderNumber,Path_Status__c from WorkOrder WHERE WorkOrderNumber =: newMsg.MessageContent__c];
                    if(!wrkOrd.isEmpty()){
                        String callOutString = newMsg.CustomerPhone__c+'@@'+newMsg.BusinessPhoneNumber__c+'@@'+'🚗🧾 Your Job Card Status is: '+wrkOrd[0].Path_Status__c+'@@'+'text'+'@@'+''+'@@'+''+'@@'+newMsg.CustomerName__c;
                        WhatsAppOutgoingMessage.sendMediaMessage(callOutString);
                    }
                }
                
                System.debug('No previous outbound message found for customer: ' + newMsg.CustomerPhone__c);
            }
            
            
        } 
        
        
        // Debugging or further processing
        for (WhatsApp_Message__c newMsg2 : newMessages) {
            
            if (latestOutboundMessages2.containsKey(newMsg2.ParentMessageID__c)) {
                
                WhatsApp_Message__c previousOutbound2 = latestOutboundMessages2.get(newMsg2.ParentMessageID__c);
                System.debug('previousOutbound2: ' + previousOutbound2);
                if(previousOutbound2 != null && previousOutbound2.MessageID__c == newMsg2.ParentMessageID__c){
                    
                    if(previousOutbound2.MessageID__c==newMsg2.ParentMessageID__c){
                        if(newMsg2.TemplateButtonPayload__c=='Book Service Appointment'){
                            String callOutString = newMsg2.CustomerPhone__c+'@@'+newMsg2.BusinessPhoneNumber__c+'@@'+'🚗 Time for a tune-up? Book your service appointment using the link below 🔧📲 \\n'+'https://crmlanding.in/serviceappointment/?cid='+accountId+'@@'+'text'+'@@'+''+'@@'+''+'@@'+newMsg2.CustomerName__c;
                            WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                        }else if(newMsg2.TemplateButtonPayload__c=='Raise Complaint'){
String JsonBody ='{"messaging_product":"whatsapp","to":"'+newMsg2.CustomerPhone__c+'","type":"template","template":{"name":"tatacomplain","language":{"code":"en"},"components":[{"type":"button","sub_type":"flow","index":"0"}]}}';

                           // String JsonBody ='{"messaging_product":"whatsapp","to":"'+newMsg2.CustomerPhone__c+'","type":"template","template":{"name":"d_raise_comaplin","language":{"code":"en"}}}';
                            String calloutString = newMsg2.CustomerPhone__c+'@@'+newMsg2.BusinessPhoneNumber__c+'@@'+JsonBody+'@@'+'WelcomeTemplate'+'@@'+null+'@@'+'NewCase'+'@@'+newMsg2.CustomerName__c;
                            WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                        }else if(newMsg2.TemplateButtonPayload__c=='Job Card Status'){
                            String JsonBody ='{"messaging_product":"whatsapp","to":"'+newMsg2.CustomerPhone__c+'","type":"template","template":{"name":"tata_jobcardstatus","language":{"code":"en"}}}';
                            String calloutString = newMsg2.CustomerPhone__c+'@@'+newMsg2.BusinessPhoneNumber__c+'@@'+JsonBody+'@@'+'WelcomeTemplate'+'@@'+null+'@@'+'jobcard'+'@@'+newMsg2.CustomerName__c;
                            WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                        }else if(newMsg2.TemplateButtonPayload__c=='Connect with agent'){
                            String callOutString = newMsg2.CustomerPhone__c+'@@'+newMsg2.BusinessPhoneNumber__c+'@@'+'Thank you for your message. Please hold on — we’re connecting you to one of our support agents.'+'@@'+'text'+'@@'+''+'@@'+''+'@@'+newMsg2.CustomerName__c;
                            WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                            List<User> userList = [Select Id from User WHERE Id=:'005GB00000aQfDkYAK'];
                            Set<String> user = New Set<String>();
                            for(User us : userList){
                                user.add(us.Id);
                            }
                            CustomNotificationType notificationType = 
                                [SELECT Id, DeveloperName 
                                 FROM CustomNotificationType 
                                 WHERE DeveloperName='ConnectToAgent'];
                            
                            // Create a new custom notification
                            Messaging.CustomNotification notification = new Messaging.CustomNotification();
                            
                            // Set the contents for the notification
                            notification.setTitle(newMsg2.CustomerName__c+' wants to connect you');
                            notification.setBody('The notifications from wahtsApp');
                            
                            // Set the notification type and target
                            notification.setNotificationTypeId(notificationType.Id);
                            notification.setTargetId(whatsappUser);
                            
                            
                            notification.send(user);
                        }
                    } 
                    System.debug('No previous outbound message found for customer: ' + newMsg2.CustomerPhone__c);
                }
            }
        }
    } */
}