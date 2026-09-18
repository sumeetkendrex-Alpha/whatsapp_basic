public class TemplateAnalyticsScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        TemplateInsights.insightTemplate();
    }
}