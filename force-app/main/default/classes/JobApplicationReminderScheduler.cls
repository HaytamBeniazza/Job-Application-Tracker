global class JobApplicationReminderScheduler implements Schedulable {
    
    /**
     * Executes the scheduled job to send reminders for upcoming interviews
     * @param context The SchedulableContext
     */
    global void execute(SchedulableContext context) {
        // Find Job Applications with interviews scheduled within the next 24 hours
        // that haven't had a reminder sent yet
        DateTime now = DateTime.now();
        DateTime tomorrow = now.addDays(1);
        
        List<JobApplication__c> jobApplications = [
            SELECT Id, Name, Company__c, Position__c, InterviewDate__c, 
                   ContactName__c, ContactEmail__c, ReminderSent__c
            FROM JobApplication__c
            WHERE Status__c = 'Interview Scheduled'
            AND InterviewDate__c > :now
            AND InterviewDate__c < :tomorrow
            AND ReminderSent__c = false
        ];
        
        for (JobApplication__c jobApp : jobApplications) {
            // Send the reminder email
            JobApplicationEmailUtil.sendInterviewReminder(jobApp);
        }
    }
    
    /**
     * Schedules the job to run daily at 8:00 AM
     */
    public static void scheduleDaily() {
        // Schedule the job to run daily at 8:00 AM
        String jobName = 'Job Application Reminder - Daily';
        String cronExpression = '0 0 8 * * ?';
        
        try {
            // Check if the job already exists
            List<CronTrigger> existingJobs = [
                SELECT Id FROM CronTrigger 
                WHERE CronJobDetail.Name = :jobName
                LIMIT 1
            ];
            
            // If the job exists, abort it
            if (!existingJobs.isEmpty()) {
                System.abortJob(existingJobs[0].Id);
            }
            
            // Schedule the new job
            JobApplicationReminderScheduler scheduler = new JobApplicationReminderScheduler();
            System.schedule(jobName, cronExpression, scheduler);
            
            System.debug('Job Application Reminder scheduler has been set up to run daily at 8:00 AM');
        } catch (Exception e) {
            System.debug('Error scheduling Job Application Reminder: ' + e.getMessage());
        }
    }
} 