@isTest
private class JobApplicationControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            Alias = 'testuser',
            Email = 'test.user@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert testUser;
        
        // Create test job application records
        List<JobApplication__c> testApps = new List<JobApplication__c>();
        
        // Application with 'Applied' status
        testApps.add(new JobApplication__c(
            Company__c = 'Test Company 1',
            Position__c = 'Test Position 1',
            ApplicationDate__c = Date.today(),
            Status__c = 'Applied',
            ContactName__c = 'Test Contact 1',
            ContactEmail__c = 'test1@example.com',
            OwnerId = testUser.Id
        ));
        
        // Application with 'Interview Scheduled' status
        testApps.add(new JobApplication__c(
            Company__c = 'Test Company 2',
            Position__c = 'Test Position 2',
            ApplicationDate__c = Date.today().addDays(-5),
            Status__c = 'Interview Scheduled',
            InterviewDate__c = DateTime.now().addDays(3),
            ContactName__c = 'Test Contact 2',
            ContactEmail__c = 'test2@example.com',
            OwnerId = testUser.Id,
            ReminderSent__c = false
        ));
        
        insert testApps;
    }
    
    @isTest
    static void testCreateJobApplication() {
        // Test data setup
        String company = 'New Test Company';
        String position = 'New Test Position';
        Date appDate = Date.today();
        String contactName = 'New Test Contact';
        String contactEmail = 'newtest@example.com';
        
        Test.startTest();
        // Call the controller method
        JobApplication__c result = JobApplicationController.createJobApplication(
            company,
            position,
            appDate,
            contactName,
            contactEmail
        );
        Test.stopTest();
        
        // Verify the result
        System.assertNotEquals(null, result.Id, 'Job Application should be created with an ID');
        System.assertEquals(company, result.Company__c, 'Company name should match');
        System.assertEquals(position, result.Position__c, 'Position should match');
        System.assertEquals(appDate, result.ApplicationDate__c, 'Application date should match');
        System.assertEquals(contactName, result.ContactName__c, 'Contact name should match');
        System.assertEquals(contactEmail, result.ContactEmail__c, 'Contact email should match');
        System.assertEquals('Applied', result.Status__c, 'Status should be set to Applied');
    }
    
    @isTest
    static void testUpdateJobApplicationStatus() {
        // Get a test job application
        JobApplication__c jobApp = [
            SELECT Id FROM JobApplication__c 
            WHERE Company__c = 'Test Company 1' 
            LIMIT 1
        ];
        
        String newStatus = 'Interview Scheduled';
        DateTime interviewDate = DateTime.now().addDays(7);
        
        Test.startTest();
        // Call the controller method
        JobApplication__c result = JobApplicationController.updateJobApplicationStatus(
            jobApp.Id,
            newStatus,
            interviewDate
        );
        Test.stopTest();
        
        // Verify the result
        System.assertEquals(newStatus, result.Status__c, 'Status should be updated');
        System.assertEquals(interviewDate, result.InterviewDate__c, 'Interview date should be set');
        System.assertEquals(false, result.ReminderSent__c, 'Reminder sent should be false');
    }
    
    @isTest
    static void testGetJobApplications() {
        // Get the test user
        User testUser = [SELECT Id FROM User WHERE LastName = 'Testing' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            // Call the controller method
            List<JobApplication__c> results = JobApplicationController.getJobApplications();
            Test.stopTest();
            
            // Verify the results
            System.assertEquals(2, results.size(), 'Should return 2 job applications');
        }
    }
    
    @isTest
    static void testGetUpcomingInterviews() {
        // Get the test user
        User testUser = [SELECT Id FROM User WHERE LastName = 'Testing' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            // Call the controller method
            List<JobApplication__c> results = JobApplicationController.getUpcomingInterviews();
            Test.stopTest();
            
            // Verify the results
            System.assertEquals(1, results.size(), 'Should return 1 upcoming interview');
            System.assertEquals('Test Company 2', results[0].Company__c, 'Should return the correct company');
        }
    }
    
    @isTest
    static void testErrorHandling() {
        // Test with invalid ID to trigger error
        Id invalidId = '001000000000000'; // Invalid ID format
        
        Test.startTest();
        try {
            // Call the controller method with invalid ID
            JobApplication__c result = JobApplicationController.updateJobApplicationStatus(
                invalidId,
                'Interview Scheduled',
                DateTime.now()
            );
            System.assert(false, 'An exception should have been thrown');
        } catch (AuraHandledException e) {
            // Verify that an AuraHandledException was thrown
            System.assert(true, 'AuraHandledException was thrown as expected');
        }
        Test.stopTest();
    }
} 