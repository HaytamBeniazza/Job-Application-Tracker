@isTest
private class JobApplicationReminderBatchTest {
    
    @isTest
    static void testBatchExecution() {
        // Create test job applications
        List<JobApplication__c> testApps = new List<JobApplication__c>();
        
        // Create 10 applications with interviews tomorrow
        for (Integer i = 0; i < 10; i++) {
            testApps.add(new JobApplication__c(
                Company__c = 'Test Company ' + i,
                Position__c = 'Test Position ' + i,
                ApplicationDate__c = Date.today().addDays(-7),
                Status__c = 'Interview Scheduled',
                InterviewDate__c = DateTime.now().addDays(1),
                ContactName__c = 'Test Contact ' + i,
                ContactEmail__c = 'test' + i + '@example.com',
                ReminderSent__c = false
            ));
        }
        
        // Create 5 applications with interviews in 2 days (shouldn't receive reminders)
        for (Integer i = 10; i < 15; i++) {
            testApps.add(new JobApplication__c(
                Company__c = 'Test Company ' + i,
                Position__c = 'Test Position ' + i,
                ApplicationDate__c = Date.today().addDays(-5),
                Status__c = 'Interview Scheduled',
                InterviewDate__c = DateTime.now().addDays(2),
                ContactName__c = 'Test Contact ' + i,
                ContactEmail__c = 'test' + i + '@example.com',
                ReminderSent__c = false
            ));
        }
        
        // Create 5 applications with reminders already sent
        for (Integer i = 15; i < 20; i++) {
            testApps.add(new JobApplication__c(
                Company__c = 'Test Company ' + i,
                Position__c = 'Test Position ' + i,
                ApplicationDate__c = Date.today().addDays(-6),
                Status__c = 'Interview Scheduled',
                InterviewDate__c = DateTime.now().addDays(1),
                ContactName__c = 'Test Contact ' + i,
                ContactEmail__c = 'test' + i + '@example.com',
                ReminderSent__c = true
            ));
        }
        
        insert testApps;
        
        // Create a test admin user for receiving failure reports
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Email = 'testadmin@example.com',
            Username = 'testadmin' + DateTime.now().getTime() + '@example.com',
            Alias = 'tadmin',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = adminProfile.Id
        );
        insert adminUser;
        
        // Set up email tracking
        Integer emailInvocations = Limits.getEmailInvocations();
        
        Test.startTest();
        // Execute the batch job
        JobApplicationReminderBatch batchJob = new JobApplicationReminderBatch();
        Database.executeBatch(batchJob, 200); // Use a large batch size to process all at once in test
        Test.stopTest();
        
        // Verify reminders were sent to appropriate records
        List<JobApplication__c> updatedApps = [
            SELECT Id, Company__c, ReminderSent__c
            FROM JobApplication__c
            WHERE InterviewDate__c > :DateTime.now()
            AND InterviewDate__c < :DateTime.now().addDays(1.5) // Within ~36 hours
            AND ReminderSent__c = true
        ];
        
        System.assertEquals(10, updatedApps.size(), 'Should have sent reminders to 10 job applications');
        
        // Verify applications with interviews in 2+ days were not updated
        List<JobApplication__c> futureApps = [
            SELECT Id FROM JobApplication__c
            WHERE InterviewDate__c > :DateTime.now().addDays(1.5)
            AND ReminderSent__c = false
        ];
        
        System.assertEquals(5, futureApps.size(), 'Applications with interviews in 2+ days should not receive reminders');
        
        // Verify applications that already had reminders sent were not modified
        List<JobApplication__c> existingReminderApps = [
            SELECT Id FROM JobApplication__c
            WHERE Company__c LIKE 'Test Company 1%'
            AND ReminderSent__c = true
        ];
        
        System.assertEquals(5, existingReminderApps.size(), 'Applications with reminders already sent should remain unchanged');
        
        // Verify emails were sent (10 reminders + potentially 1 admin email)
        // We can only verify the number of attempted emails, not actual sending
        System.assert(Limits.getEmailInvocations() > emailInvocations, 'Should have attempted to send emails');
    }
    
    @isTest
    static void testBatchWithFailures() {
        // Create a test application with null interview date to cause a failure
        JobApplication__c failureApp = new JobApplication__c(
            Company__c = 'Failure Company',
            Position__c = 'Failure Position',
            ApplicationDate__c = Date.today().addDays(-7),
            Status__c = 'Interview Scheduled',
            InterviewDate__c = null, // This will cause failure
            ContactName__c = 'Failure Contact',
            ContactEmail__c = 'failure@example.com',
            ReminderSent__c = false
        );
        insert failureApp;
        
        // Create a test admin user for receiving failure reports
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Email = 'testadmin@example.com',
            Username = 'testadmin' + DateTime.now().getTime() + '@example.com',
            Alias = 'tadmin',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = adminProfile.Id
        );
        insert adminUser;
        
        Test.startTest();
        JobApplicationReminderBatch batchJob = new JobApplicationReminderBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();
        
        // Verify application has not been updated due to error
        JobApplication__c updatedApp = [SELECT ReminderSent__c FROM JobApplication__c WHERE Id = :failureApp.Id];
        System.assertEquals(false, updatedApp.ReminderSent__c, 'Application should not be updated due to error');
    }
} 