public class SendWhatsAppMessageBatch implements Database.Batchable<String>, Database.AllowsCallouts {
    
      private List<String> callOutStrings;
    
    public SendWhatsAppMessageBatch(List<String> callOutStrings) {
        this.callOutStrings = callOutStrings;
    }
    
    public Iterable<String> start(Database.BatchableContext bc) {
        return callOutStrings;
    }
    
    public void execute(Database.BatchableContext bc, List<String> scope) {
        system.debug('scope==>'+scope);
        system.debug('scope==>'+scope.size());
        
        for (String msg : scope) {
            wahtsAppMessageQueueablehandler.sendMessageQueue(msg);
            system.debug('msg==>'+msg);
            
        }
    }
    
    public void finish(Database.BatchableContext bc) {
    }
  


}