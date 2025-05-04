@isTest
private class JobApplicationEmailUtilTest {
    
    @isTest
    static void testSendInterviewReminder() {
        // Create test job application
        JobApplication__c jobApp = new JobApplication__c(
            Company__c = 'Test Company',
            Position__c = 'Test Position',
            ApplicationDate__c = Date.today().addDays(-7),
            Status__c = 'Interview Scheduled',
            InterviewDate__c = DateTime.now().addDays(1),
            ContactName__c = 'Test Contact',
            ContactEmail__c = 'test@example.com',
            ReminderSent__c = false
        );
        insert jobApp;
        
        // Set up email mock to capture sent emails
        Integer emailInvocations = Limits.getEmailInvocations();
        
        Test.startTest();
        // Enable email deliverability
        Messaging.reserveSingleEmailCapacity(1);
        
        // Call the method to test
        Boolean result = JobApplicationEmailUtil.sendInterviewReminder(jobApp);
        Test.stopTest();
        
        // Refresh the record to see if it was updated
        jobApp = [
            SELECT ReminderSent__c 
            FROM JobApplication__c 
            WHERE Id = :jobApp.Id
        ];
        
        // In a test context, emails aren't actually sent, but we can verify the method was called
        System.assertEquals(emailInvocations + 1, Limits.getEmailInvocations(), 'Should have attempted to send an email');
        
        // The method returns true in test context, but we can't verify the actual sending
        // Instead we check if the method completed successfully
        System.assertEquals(true, result, 'Method should complete successfully');
        System.assertEquals(true, jobApp.ReminderSent__c, 'ReminderSent should be set to true');
    }
    
    @isTest
    static void testSendInterviewReminderWithException() {
        // Create test job application with null InterviewDate to trigger exception
        JobApplication__c jobApp = new JobApplication__c(
            Company__c = 'Test Company',
            Position__c = 'Test Position',
            ApplicationDate__c = Date.today().addDays(-7),
            Status__c = 'Interview Scheduled',
            InterviewDate__c = null, // This will cause an exception when formatting
            ContactName__c = 'Test Contact',
            ContactEmail__c = 'test@example.com',
            ReminderSent__c = false
        );
        insert jobApp;
        
        Test.startTest();
        // Call the method to test - should handle exception internally
        Boolean result = JobApplicationEmailUtil.sendInterviewReminder(jobApp);
        Test.stopTest();
        
        // Method should return false due to the exception
        System.assertEquals(false, result, 'Method should return false when an exception occurs');
        
        // Verify record was not updated
        jobApp = [
            SELECT ReminderSent__c 
            FROM JobApplication__c 
            WHERE Id = :jobApp.Id
        ];
        System.assertEquals(false, jobApp.ReminderSent__c, 'ReminderSent should still be false');
    }
} 