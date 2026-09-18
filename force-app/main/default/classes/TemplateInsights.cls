public class TemplateInsights {
    public static void insightTemplate(){
        
        // Today's Start (00:00:00)
        Date today = Date.today();
        String startToday = today.format(); // 'YYYY-MM-DD'

        // Today's End (23:59:59)
        String startTodayEnd = today.format(); // same date, API expects only date

        List<WhatsAppMetaTemplate__c> templateList = [
            SELECT Id, Id__c, Template_Name__c 
            FROM WhatsAppMetaTemplate__c 
            LIMIT 49999
        ];
        
        for (WhatsAppMetaTemplate__c temp : templateList) {
            TemplateInsightsController.getTemplateAnalytics(startToday, startTodayEnd, temp.Id__c);
        }
    }
}