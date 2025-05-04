global class JobApplicationReminderBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    // Store metrics
    private Integer successCount = 0;
    private Integer failureCount = 0;
    private List<String> errors = new List<String>();
    
    // The query locator
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Find Job Applications with interviews scheduled within the next 24 hours
        // that haven't had a reminder sent yet
        DateTime now = DateTime.now();
        DateTime tomorrow = now.addDays(1);
        
        return Database.getQueryLocator([
            SELECT Id, Name, Company__c, Position__c, InterviewDate__c, 
                   ContactName__c, ContactEmail__c, ReminderSent__c, OwnerId
            FROM JobApplication__c
            WHERE Status__c = 'Interview Scheduled'
            AND InterviewDate__c > :now
            AND InterviewDate__c < :tomorrow
            AND ReminderSent__c = false
        ]);
    }
    
    // Process each batch
    global void execute(Database.BatchableContext bc, List<JobApplication__c> scope) {
        // List to hold records to update
        List<JobApplication__c> recordsToUpdate = new List<JobApplication__c>();
        
        for (JobApplication__c jobApp : scope) {
            try {
                // Send the reminder email
                Boolean success = JobApplicationEmailUtil.sendInterviewReminder(jobApp);
                
                if (success) {
                    successCount++;
                    // No need to update the record here since sendInterviewReminder already updates it
                } else {
                    failureCount++;
                    errors.add('Failed to send reminder for: ' + jobApp.Company__c + ' - ' + jobApp.Position__c);
                }
            } catch (Exception e) {
                failureCount++;
                errors.add('Exception sending reminder for ' + jobApp.Company__c + ': ' + e.getMessage());
            }
        }
    }
    
    // Handle finish
    global void finish(Database.BatchableContext bc) {
        // Log the results
        System.debug('Job Application Reminder Batch completed');
        System.debug('Successes: ' + successCount);
        System.debug('Failures: ' + failureCount);
        
        // Send an email to the admin if there were failures
        if (failureCount > 0) {
            try {
                // Get a user to send the email to (system admin)
                List<User> admins = [SELECT Email FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
                
                if (!admins.isEmpty()) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[] { admins[0].Email });
                    mail.setSubject('Job Application Reminder Batch Results');
                    
                    String body = 'The Job Application Reminder Batch job has completed.\n\n';
                    body += 'Successful reminders sent: ' + successCount + '\n';
                    body += 'Failed reminders: ' + failureCount + '\n\n';
                    
                    if (!errors.isEmpty()) {
                        body += 'Error details:\n';
                        for (String error : errors) {
                            body += '- ' + error + '\n';
                        }
                    }
                    
                    mail.setPlainTextBody(body);
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                }
            } catch (Exception e) {
                System.debug('Error sending batch results email: ' + e.getMessage());
            }
        }
    }
} 