global with sharing class ScrubContactEmailBatchSchedular implements Schedulable {
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new ScrubContactEmailBatch());
    }
}