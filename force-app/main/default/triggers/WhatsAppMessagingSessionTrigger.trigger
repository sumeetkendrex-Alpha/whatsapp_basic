trigger WhatsAppMessagingSessionTrigger on WhatsAppMessagingSession__c (after insert) {
    If(Trigger.isInsert && Trigger.isAfter){
        Set<Id> Ids = New Set<Id>();
        For(WhatsAppMessagingSession__c session : Trigger.New){
            If(session.Status__c =='Active'){
                Ids.add(session.Id);
            }
        }
        //WhatsAppMessagingSessionHandler.sendImages(Ids);
    }
}