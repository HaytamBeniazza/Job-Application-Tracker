@isTest
private class JobApplicationSetupTest {
    
    @isTest
    static void testInitialize() {
        // Verify no scheduled jobs exist before the test
        List<CronTrigger> existingJobs = [
            SELECT Id FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Job Application Reminder - Daily'
        ];
        System.assertEquals(0, existingJobs.size(), 'No jobs should exist before test');
        
        Test.startTest();
        // Call the initialize method
        JobApplicationSetup.initialize();
        Test.stopTest();
        
        // Verify a job was scheduled
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronExpression, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Job Application Reminder - Daily'
        ];
        System.assertEquals(1, scheduledJobs.size(), 'A job should have been scheduled');
        System.assertEquals('0 0 8 * * ?', scheduledJobs[0].CronExpression, 'Job should be scheduled for 8:00 AM daily');
    }
} 