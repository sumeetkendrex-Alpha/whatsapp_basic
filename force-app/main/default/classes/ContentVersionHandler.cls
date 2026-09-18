public class ContentVersionHandler {

    public static void createContentDistributions(List<ContentVersion> newVersions) {

        List<ContentDistribution> distributionsToCreate = new List<ContentDistribution>();

        for (ContentVersion version : newVersions) {
            if (version.IsLatest && version.ContentDocumentId != null) {
                ContentDistribution dist = new ContentDistribution(
                    Name = version.Title,
                    ContentVersionId = version.Id,
                    PreferencesAllowViewInBrowser = true,
                    PreferencesLinkLatestVersion = true,
                    PreferencesNotifyOnVisit = false,
                    PreferencesPasswordRequired = false
                );
                distributionsToCreate.add(dist);
            }
        }

        if (!distributionsToCreate.isEmpty()) {
            insert distributionsToCreate;
        }
    }
}