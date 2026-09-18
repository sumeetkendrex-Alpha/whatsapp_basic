public class SendWhatsAppFlowInvoker {
    public class Request {
        @InvocableVariable(required=true)
        public String callOutString;
    }
    
    @InvocableMethod(label='Send WhatsApp Message (Queue)' description='Sends a WhatsApp message using Queueable from Flow')
    public static void invokeWhatsAppMessageFromFlow(List<Request> requestList) {
        system.debug('RequestList flow==>'+requestList);
        List<String> callOutStrings = new List<String>();
      
        for (Request req : requestList) {
            if (String.isNotBlank(req.callOutString)) {
                callOutStrings.add(req.callOutString);
            }
        }
        
        if (!callOutStrings.isEmpty()) {
            SendWhatsAppMessageBatch batch = new SendWhatsAppMessageBatch(callOutStrings);
            Database.executeBatch(batch, 50);
        }
    }
}