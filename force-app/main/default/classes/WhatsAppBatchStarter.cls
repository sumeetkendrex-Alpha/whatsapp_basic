public class WhatsAppBatchStarter {

    public static void startBatches(List<String> callOutStrings) {
        Integer chunkSize = 50;

        for (Integer i = 0; i < callOutStrings.size(); i += chunkSize) {
            Integer toIndex = Math.min(i + chunkSize, callOutStrings.size());
            List<String> chunk = new List<String>();

            for (Integer j = i; j < toIndex; j++) {
                chunk.add(callOutStrings[j]);
            }

            System.debug('🚀 Starting batch for chunk ' + i + ' to ' + (toIndex - 1) + ', size: ' + chunk.size());

            SendWhatsAppMessageBatch batch = new SendWhatsAppMessageBatch(chunk);
            Database.executeBatch(batch, 1);
        }
    }
}