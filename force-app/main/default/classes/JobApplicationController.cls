public with sharing class JobApplicationController {
    
    /**
     * Creates a new Job Application record
     * @param company The company name
     * @param position The position applied for
     * @param applicationDate The date of application
     * @param contactName Optional contact name
     * @param contactEmail Optional contact email
     * @return The newly created Job Application record
     */
    @AuraEnabled
    public static JobApplication__c createJobApplication(
        String company,
        String position,
        Date applicationDate,
        String contactName,
        String contactEmail
    ) {
        try {
            JobApplication__c jobApp = new JobApplication__c(
                Company__c = company,
                Position__c = position,
                ApplicationDate__c = applicationDate,
                Status__c = 'Applied',
                ContactName__c = contactName,
                ContactEmail__c = contactEmail
            );
            
            insert jobApp;
            return jobApp;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating job application: ' + e.getMessage());
        }
    }
    
    /**
     * Updates the status of a Job Application
     * @param recordId The ID of the Job Application record
     * @param status The new status
     * @param interviewDate Optional interview date (required for Interview Scheduled status)
     * @return The updated Job Application record
     */
    @AuraEnabled
    public static JobApplication__c updateJobApplicationStatus(
        Id recordId,
        String status,
        DateTime interviewDate
    ) {
        try {
            JobApplication__c jobApp = [
                SELECT Id, Status__c, InterviewDate__c, ReminderSent__c
                FROM JobApplication__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            
            jobApp.Status__c = status;
            
            if (status == 'Interview Scheduled' && interviewDate != null) {
                jobApp.InterviewDate__c = interviewDate;
                jobApp.ReminderSent__c = false;
            }
            
            update jobApp;
            return jobApp;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating job application: ' + e.getMessage());
        }
    }
    
    /**
     * Gets all Job Applications for the current user
     * @return List of Job Application records
     */
    @AuraEnabled(cacheable=true)
    public static List<JobApplication__c> getJobApplications() {
        try {
            return [
                SELECT Id, Name, Company__c, Position__c, Status__c, 
                       ApplicationDate__c, InterviewDate__c, 
                       ContactName__c, ContactEmail__c, Notes__c, ReminderSent__c
                FROM JobApplication__c
                WHERE OwnerId = :UserInfo.getUserId()
                ORDER BY ApplicationDate__c DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving job applications: ' + e.getMessage());
        }
    }
    
    /**
     * Gets Job Applications with upcoming interviews
     * @return List of Job Application records with upcoming interviews
     */
    @AuraEnabled(cacheable=true)
    public static List<JobApplication__c> getUpcomingInterviews() {
        try {
            return [
                SELECT Id, Name, Company__c, Position__c, InterviewDate__c, ReminderSent__c
                FROM JobApplication__c
                WHERE Status__c = 'Interview Scheduled'
                AND InterviewDate__c > :DateTime.now()
                AND OwnerId = :UserInfo.getUserId()
                ORDER BY InterviewDate__c ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving upcoming interviews: ' + e.getMessage());
        }
    }
} 