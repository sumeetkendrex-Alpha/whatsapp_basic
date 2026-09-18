public class SendWahtsAppMessageQueueable implements Queueable, Database.AllowsCallouts {
    private String callOutString;

    public SendWahtsAppMessageQueueable(String callOutString) {
        this.callOutString = callOutString;
    }

    public void execute(QueueableContext context) {
        wahtsAppMessageQueueablehandler.sendMessageQueue(callOutString);
    }
}