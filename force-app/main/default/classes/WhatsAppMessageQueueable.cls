public class WhatsAppMessageQueueable implements Queueable {
    private List<String> callOutStrings;
    
    public WhatsAppMessageQueueable(List<String> callOutStrings) {
        this.callOutStrings = callOutStrings;
    }
    
    public void execute(QueueableContext context) {
        system.debug('Excecute===>'+callOutStrings);
        system.debug('Excecute===>'+callOutStrings.size());
        SendWhatsAppMessageBatch batch = new SendWhatsAppMessageBatch(callOutStrings);
        Database.executeBatch(batch, 1);
    }
}