global class WhatsappMessageSessionSchedulable implements Schedulable {
    global void execute(SchedulableContext sc) {
        WhatsappMessageSessionBatchable batch = new WhatsappMessageSessionBatchable();
        Database.executeBatch(batch, 1000);
    }
}