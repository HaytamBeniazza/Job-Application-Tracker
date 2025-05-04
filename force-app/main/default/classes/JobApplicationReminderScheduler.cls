global class JobApplicationReminderScheduler implements Schedulable {
    
    // Batch size for processing job applications
    private static final Integer BATCH_SIZE = 50;
    
    /**
     * Executes the scheduled job to send reminders for upcoming interviews
     * @param context The SchedulableContext
     */
    global void execute(SchedulableContext context) {
        // Start the batch job to send reminders
        JobApplicationReminderBatch batchJob = new JobApplicationReminderBatch();
        Database.executeBatch(batchJob, BATCH_SIZE);
        
        // Log that the job started
        System.debug('Job Application Reminder batch job scheduled by ' + 
                    UserInfo.getName() + ' at ' + DateTime.now());
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
            throw e;  // Re-throw the exception to ensure it's handled by the caller
        }
    }
} 