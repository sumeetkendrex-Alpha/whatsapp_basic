public class Vadilal {
    
    public static void handleMessage(Set<Id> msgIds) {
        List<WhatsApp_Message__c> newMessages = [
            SELECT Id, BusinessPhoneNumber__c, CustomerName__c, TemplateButtonPayload__c, OrderNumber__c, 
            TemplateButtonText__c, Account__c, MessageID__c, CustomerPhone__c, MessageType__c, 
            MessageSendType__c, ParentMessageID__c, MessageContent__c,MediaId__c
            FROM WhatsApp_Message__c
            WHERE Id IN :msgIds];
        
        // Collect unique customer phone numbers
        Set<String> customerPhones = new Set<String>();
        for (WhatsApp_Message__c msg : newMessages) {
            if (msg.CustomerPhone__c != null) {
                customerPhones.add(msg.CustomerPhone__c);
            }
            if(msg.MessageContent__c=='Hi'||msg.MessageContent__c=='Hello'){
                String JsonBody ='{"messaging_product":"whatsapp","to":"'+msg.CustomerPhone__c+'","type":"template","template":{"name":"kem_biyos","language":{"code":"en"},"components":[{"type":"body","parameters":[{"type":"text","text":"'+msg.CustomerName__c+'"}]}]}}';
                String calloutString = msg.CustomerPhone__c+'@@'+msg.BusinessPhoneNumber__c+'@@'+JsonBody+'@@'+'WelcomeTemplate'+'@@'+null+'@@'+null+'@@'+msg.CustomerName__c;
                WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
            }
        }
        
        // Fetch the most recent outbound message per customer
        Map<String, WhatsApp_Message__c> latestOutboundMessages = new Map<String, WhatsApp_Message__c>();
        if (!customerPhones.isEmpty()) {
            List<WhatsApp_Message__c> outboundMessages = [
                SELECT Id, CustomerPhone__c,MessageID__c, MessageContent__c, MessageSendType__c,MediaId__c,TemplateButtonPayload__c ,CreatedDate
                FROM WhatsApp_Message__c
                WHERE CustomerPhone__c IN :customerPhones AND MessageSendType__c = 'Outbound'
                ORDER BY CreatedDate DESC
            ];
            
            for (WhatsApp_Message__c msg : outboundMessages) {
                if (!latestOutboundMessages.containsKey(msg.CustomerPhone__c)) {
                    latestOutboundMessages.put(msg.CustomerPhone__c, msg);
                }
            }
        }
        
        // Debugging or further processing
        for (WhatsApp_Message__c newMsg : newMessages) {
            if (latestOutboundMessages.containsKey(newMsg.CustomerPhone__c)) {
                WhatsApp_Message__c previousOutbound = latestOutboundMessages.get(newMsg.CustomerPhone__c);
                System.debug('Previous Outbound Message for ' + newMsg.CustomerPhone__c + ': ' + previousOutbound.MessageContent__c);
                if(previousOutbound.TemplateButtonPayload__c=='NewCase'){
                    Case cs = New Case();
                    cs.Subject =newMsg.TemplateButtonPayload__c;
                    cs.Status = 'New';
                    cs.Origin ='Phone';
                    cs.CustomerName__c = newMsg.CustomerPhone__c + ': ' + newMsg.BusinessPhoneNumber__c;
                    Insert cs;
                    
                    String JsonBody ='{"messaging_product":"whatsapp","to":"'+newMsg.CustomerPhone__c+'","type":"template","template":{"name":"d_thank_you","language":{"code":"en"}}}';
                    String calloutString = newMsg.CustomerPhone__c+'@@'+newMsg.BusinessPhoneNumber__c+'@@'+JsonBody+'@@'+'WelcomeTemplate'+'@@'+null+'@@'+null+'@@'+newMsg.CustomerName__c;
                    WhatsAppOutgoingMessage.sendMediaMessage(calloutString);                    
                    
                } else if(previousOutbound.TemplateButtonPayload__c=='caseNumber'){
                    List<Case> cs = [Select Id,CaseNumber ,Status from Case WHERE CaseNumber =: newMsg.MessageContent__c];
                    if(!cs.isEmpty()){
                        String callOutString = newMsg.CustomerPhone__c+'@@'+newMsg.BusinessPhoneNumber__c+'@@'+'Your Case Status is :'+cs[0].Status+'@@'+'text'+'@@'+''+'@@'+''+'@@'+newMsg.CustomerName__c;
                        WhatsAppOutgoingMessage.sendMediaMessage(callOutString);
                    }else{
                        String callOutString = newMsg.CustomerPhone__c+'@@'+newMsg.BusinessPhoneNumber__c+'@@'+'Please Provide the Correct Number'+'@@'+'text'+'@@'+''+'@@'+'caseNumber'+'@@'+newMsg.CustomerName__c;
                        WhatsAppOutgoingMessage.sendMediaMessage(callOutString);        
                    }
                }else if(previousOutbound.MessageID__c==newMsg.ParentMessageID__c){
                    if(newMsg.TemplateButtonPayload__c=='Place Order'){
                        String JsonBody ='{"messaging_product":"whatsapp","to":"'+newMsg.CustomerPhone__c+'","type":"template","template":{"name":"kan_biosys_prod_categogory","language":{"code":"en"}}}';
                        String calloutString = newMsg.CustomerPhone__c+'@@'+newMsg.BusinessPhoneNumber__c+'@@'+JsonBody+'@@'+'WelcomeTemplate'+'@@'+null+'@@'+null+'@@'+newMsg.CustomerName__c;
                        WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                    }else if(newMsg.TemplateButtonPayload__c=='Bio Fertilizers'){
                        String JsonBody ='{"messaging_product":"whatsapp","to":"'+newMsg.CustomerPhone__c+'","type":"template","template":{"name":"bio_fertilizers","language":{"code":"en"}}}';
                        String calloutString = newMsg.CustomerPhone__c+'@@'+newMsg.BusinessPhoneNumber__c+'@@'+JsonBody+'@@'+'WelcomeTemplate'+'@@'+null+'@@'+null+'@@'+newMsg.CustomerName__c;
                        WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                    }else if(newMsg.TemplateButtonPayload__c=='B-seepel – RP'|| newMsg.TemplateButtonPayload__c=='B:SEEPEL'|| newMsg.TemplateButtonPayload__c=='Mycozoots'
                             || newMsg.TemplateButtonPayload__c=='Fiana'|| newMsg.TemplateButtonPayload__c=='Trivo'){
                                 
                                 Order ord = new Order();
                                 ord.AccountId = '001Qy00000kgzxSIAQ';
                                 ord.EffectiveDate = Date.today();
                                 ord.Status = 'Draft';
                                 ord.Description = 'Order has been placed for ' + newMsg.TemplateButtonPayload__c;
                                 
                                 // Standard Price Book
                                 Pricebook2 stdPb = [
                                     SELECT Id
                                     FROM Pricebook2
                                     WHERE IsStandard = true
                                     LIMIT 1
                                 ];
                                 
                                 ord.Pricebook2Id = stdPb.Id;
                                 insert ord;
                                 
                                 // Get Pricebook Entry by Product Name
                                 PricebookEntry pbe = [
                                     SELECT Id, UnitPrice
                                     FROM PricebookEntry
                                     WHERE Pricebook2Id = :stdPb.Id
                                     AND Product2.Name = :newMsg.TemplateButtonPayload__c
                                     AND IsActive = true
                                     LIMIT 1
                                 ];
                                 
                                 // Create Order Item
                                 OrderItem oi = new OrderItem(
                                     OrderId = ord.Id,
                                     PricebookEntryId = pbe.Id,
                                     Quantity = 1,
                                     UnitPrice = pbe.UnitPrice
                                 );
                                 
                                 insert oi;
                                 
                                 
                                 
                                 String JsonBody ='{"messaging_product":"whatsapp","to":"'+newMsg.CustomerPhone__c+'","type":"template","template":{"name":"great_white_quantity","language":{"code":"en"}}}';
                                 String calloutString = newMsg.CustomerPhone__c+'@@'+newMsg.BusinessPhoneNumber__c+'@@'+JsonBody+'@@'+'WelcomeTemplate'+'@@'+null+'@@'+null+'@@'+newMsg.CustomerName__c;
                                 WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                                 
                                 
                             }else if(newMsg.TemplateButtonPayload__c=='5'|| newMsg.TemplateButtonPayload__c=='10'|| newMsg.TemplateButtonPayload__c=='20'
                                      || newMsg.TemplateButtonPayload__c=='30'|| newMsg.TemplateButtonPayload__c=='40'){
                                          
                                          
                                          Integer qty = Integer.valueOf(newMsg.TemplateButtonPayload__c);
                                          
                                          List<Order> ordList = [Select Id,OrderNumber from Order ORDER BY CreatedDate DESC LIMIT 1];
                                          
                                       
                                          if(!ordList.isEmpty()){
                                                 OrderItem oi = [SELECT Id, Quantity FROM OrderItem WHERE OrderId = :ordList[0].Id LIMIT 1];
                                          
                                          oi.Quantity = qty;
                                          update oi;
                                              String JsonBody ='{"messaging_product":"whatsapp","to":"'+newMsg.CustomerPhone__c+'","type":"template","template":{"name":"order_placed","language":{"code":"en"},"components":[{"type":"body","parameters":[{"type":"text","text":"'+ordList[0].OrderNumber+'"}]}]}}';
                                              String calloutString = newMsg.CustomerPhone__c+'@@'+newMsg.BusinessPhoneNumber__c+'@@'+JsonBody+'@@'+'WelcomeTemplate'+'@@'+null+'@@'+null+'@@'+newMsg.CustomerName__c;
                                              WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                                              
                                          }
                                      }else if(newMsg.TemplateButtonPayload__c=='Buy at home'){
                                          String JsonBody ='{"messaging_product":"whatsapp","to":"'+newMsg.CustomerPhone__c+'","type":"template","template":{"name":"buy_at_home","language":{"code":"en"}}}';
                                          String calloutString = newMsg.CustomerPhone__c+'@@'+newMsg.BusinessPhoneNumber__c+'@@'+JsonBody+'@@'+'WelcomeTemplate'+'@@'+null+'@@'+null+'@@'+newMsg.CustomerName__c;
                                          WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                                      }else if(newMsg.TemplateButtonPayload__c=='Visit the Store'){
                                          String JsonBody ='{"messaging_product":"whatsapp","to":"'+newMsg.CustomerPhone__c+'","type":"template","template":{"name":"appointment","language":{"code":"en"},"components":[{"type":"button","sub_type":"flow","index":"0"}]}}';
                                          String calloutString = newMsg.CustomerPhone__c+'@@'+newMsg.BusinessPhoneNumber__c+'@@'+JsonBody+'@@'+'WelcomeTemplate'+'@@'+null+'@@'+null+'@@'+newMsg.CustomerName__c;
                                          WhatsAppOutgoingMessage.sendMediaMessage(calloutString);
                                      }
                } else {
                    
                }
                System.debug('No previous outbound message found for customer: ' + newMsg.CustomerPhone__c);
            }
        }
    }
}