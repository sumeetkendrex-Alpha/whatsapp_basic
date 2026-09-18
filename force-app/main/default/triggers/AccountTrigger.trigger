trigger AccountTrigger on Account (after insert) {
    for (Account acc : Trigger.new) {
        AccountSync.sendAccountData(acc.Id, acc.Name, acc.Phone, acc.Website);
    }
}