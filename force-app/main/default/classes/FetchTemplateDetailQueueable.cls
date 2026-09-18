public class FetchTemplateDetailQueueable implements Queueable, Database.AllowsCallouts {
    
    private Set<Id> newMsgId;

    public FetchTemplateDetailQueueable(Set<Id> newMsgId) {
        this.newMsgId = newMsgId;
    }

    public void execute(QueueableContext context) {
        WhatsappMeta__mdt metaBusiness = [SELECT Id, AccessToken__c, Business_Number__c, PhoneNumber_Id__c, WABA_Id__c, Version__c FROM WhatsappMeta__mdt LIMIT 1];

        List<WhatsApp_Message__c> messagesList = [SELECT Id, TemplateName__c FROM WhatsApp_Message__c WHERE Id IN :newMsgId];
        List<WhatsApp_Message__c> updatedMessages = new List<WhatsApp_Message__c>();

        for (WhatsApp_Message__c message : messagesList) {
            if (String.isNotBlank(message.TemplateName__c)) {
                String url = 'https://graph.facebook.com/' + metaBusiness.Version__c + '/' + metaBusiness.WABA_Id__c + '/message_templates?name=' + message.TemplateName__c;

                HttpRequest secondReq = new HttpRequest();
                secondReq.setEndpoint(url);
                secondReq.setMethod('GET');
                secondReq.setHeader('Authorization', 'Bearer ' + metaBusiness.AccessToken__c);

                Http secondHttp = new Http();
                HttpResponse secondRes;

                try {
                    secondRes = secondHttp.send(secondReq);
                } catch (Exception ex) {
                    System.debug('Callout error: ' + ex.getMessage());
                    continue;
                }

                if (secondRes.getStatusCode() == 200) {
                    Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(secondRes.getBody());
                    List<Object> dataList = (List<Object>) jsonResponse.get('data');

                    if (!dataList.isEmpty()) {
                        Map<String, Object> templateData = (Map<String, Object>) dataList[0];
                        List<Object> components = (List<Object>) templateData.get('components');

                        String bodyText = '';
                        String footerText = '';
                        String headerUrl = '';
                        List<String> buttonTexts = new List<String>();

                        for (Object comp : components) {
                            Map<String, Object> compMap = (Map<String, Object>) comp;
                            String type = (String) compMap.get('type');

                            if (type == 'BODY' && compMap.containsKey('text')) {
                                bodyText = (String) compMap.get('text');
                            } else if (type == 'FOOTER' && compMap.containsKey('text')) {
                                footerText = (String) compMap.get('text');
                            } else if (type == 'HEADER' && compMap.containsKey('format')) {
                                String format = (String) compMap.get('format');
                                if ((format == 'IMAGE' || format == 'VIDEO' || format == 'DOCUMENT' || format == 'AUDIO') && compMap.containsKey('example')) {
                                    Map<String, Object> example = (Map<String, Object>) compMap.get('example');
                                    List<Object> handleList = (List<Object>) example.get('header_handle');
                                    if (!handleList.isEmpty()) {
                                        headerUrl = (String) handleList[0];
                                    }
                                }
                            }

                            if (compMap.containsKey('buttons')) {
                                List<Object> buttons = (List<Object>) compMap.get('buttons');
                                for (Object btn : buttons) {
                                    Map<String, Object> btnMap = (Map<String, Object>) btn;
                                    if (btnMap.containsKey('text')) {
                                        buttonTexts.add((String) btnMap.get('text'));
                                    }
                                }
                            }
                        }

                        // Store values in custom object
                        message.MessageContent__c = bodyText;
                        message.TemplateButtonText__c = String.join(buttonTexts, ';');
                        updatedMessages.add(message);
                    }
                } else {
                    System.debug('Error response: ' + secondRes.getStatus() + ' - ' + secondRes.getBody());
                }
            }
        }

        if (!updatedMessages.isEmpty()) {
            try {
                update updatedMessages;
            } catch (Exception e) {
                System.debug('Update failed: ' + e.getMessage());
            }
        }
    }
}