public with sharing class JobApplicationSetup {
    
    /**
     * Sets up the Job Application Tracker
     * - Schedules the reminder job
     */
    public static void initialize() {
        // Schedule the daily reminder job
        JobApplicationReminderScheduler.scheduleDaily();
    }
} 