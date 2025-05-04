@isTest
private class JobApplicationReminderSchedulerTest {
    
    @isTest
    static void testSchedulerExecution() {
        // Create test job applications
        List<JobApplication__c> testApps = new List<JobApplication__c>();
        
        // Application with interview tomorrow (should receive reminder)
        testApps.add(new JobApplication__c(
            Company__c = 'Test Company 1',
            Position__c = 'Test Position 1',
            ApplicationDate__c = Date.today().addDays(-7),
            Status__c = 'Interview Scheduled',
            InterviewDate__c = DateTime.now().addDays(1),
            ContactName__c = 'Test Contact 1',
            ContactEmail__c = 'test1@example.com',
            ReminderSent__c = false
        ));
        
        // Application with interview in 2 days (shouldn't receive reminder yet)
        testApps.add(new JobApplication__c(
            Company__c = 'Test Company 2',
            Position__c = 'Test Position 2',
            ApplicationDate__c = Date.today().addDays(-5),
            Status__c = 'Interview Scheduled',
            InterviewDate__c = DateTime.now().addDays(2),
            ContactName__c = 'Test Contact 2',
            ContactEmail__c = 'test2@example.com',
            ReminderSent__c = false
        ));
        
        // Application with reminder already sent
        testApps.add(new JobApplication__c(
            Company__c = 'Test Company 3',
            Position__c = 'Test Position 3',
            ApplicationDate__c = Date.today().addDays(-6),
            Status__c = 'Interview Scheduled',
            InterviewDate__c = DateTime.now().addDays(1),
            ContactName__c = 'Test Contact 3',
            ContactEmail__c = 'test3@example.com',
            ReminderSent__c = true
        ));
        
        insert testApps;
        
        // Set up to track emails
        Integer emailInvocations = Limits.getEmailInvocations();
        
        Test.startTest();
        // Execute the scheduler
        JobApplicationReminderScheduler scheduler = new JobApplicationReminderScheduler();
        scheduler.execute(null);
        Test.stopTest();
        
        // Verify the first job application had its reminder sent
        JobApplication__c app1 = [
            SELECT ReminderSent__c 
            FROM JobApplication__c 
            WHERE Company__c = 'Test Company 1'
        ];
        System.assertEquals(true, app1.ReminderSent__c, 'Reminder should be sent for application with interview tomorrow');
        
        // Verify the second job application did not have its reminder sent
        JobApplication__c app2 = [
            SELECT ReminderSent__c 
            FROM JobApplication__c 
            WHERE Company__c = 'Test Company 2'
        ];
        System.assertEquals(false, app2.ReminderSent__c, 'Reminder should not be sent for application with interview in 2 days');
        
        // Verify the third job application was not modified
        JobApplication__c app3 = [
            SELECT ReminderSent__c 
            FROM JobApplication__c 
            WHERE Company__c = 'Test Company 3'
        ];
        System.assertEquals(true, app3.ReminderSent__c, 'Reminder flag should still be true for application with reminder already sent');
        
        // Verify the scheduler attempted to send one email
        System.assertEquals(emailInvocations + 1, Limits.getEmailInvocations(), 'Should have attempted to send 1 email');
    }
    
    @isTest
    static void testScheduleDaily() {
        Test.startTest();
        // Schedule the job
        JobApplicationReminderScheduler.scheduleDaily();
        Test.stopTest();
        
        // Verify the job was scheduled
        List<CronTrigger> cronTriggers = [
            SELECT Id, CronExpression, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Job Application Reminder - Daily'
        ];
        
        System.assertEquals(1, cronTriggers.size(), 'Should have scheduled 1 job');
        System.assertEquals('0 0 8 * * ?', cronTriggers[0].CronExpression, 'Should be scheduled to run at 8:00 AM daily');
    }
    
    @isTest
    static void testRescheduleDaily() {
        // Schedule the job first time
        JobApplicationReminderScheduler.scheduleDaily();
        
        // Get the job ID
        List<CronTrigger> cronTriggers = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Job Application Reminder - Daily'
        ];
        Id firstJobId = cronTriggers[0].Id;
        
        Test.startTest();
        // Schedule the job again (should abort first job and create new one)
        JobApplicationReminderScheduler.scheduleDaily();
        Test.stopTest();
        
        // Verify the job was rescheduled
        List<CronTrigger> updatedTriggers = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Job Application Reminder - Daily'
        ];
        
        System.assertEquals(1, updatedTriggers.size(), 'Should have one scheduled job');
        System.assertNotEquals(firstJobId, updatedTriggers[0].Id, 'Should have a new job ID (old job aborted)');
    }
} 