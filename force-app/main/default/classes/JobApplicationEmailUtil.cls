public with sharing class JobApplicationEmailUtil {
    
    /**
     * Sends an email reminder for an upcoming interview
     * @param jobApplication The Job Application record
     * @return True if the email was sent successfully
     */
    public static Boolean sendInterviewReminder(JobApplication__c jobApplication) {
        try {
            // Get the user's email
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            // Create the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            // Set the recipient to the current user
            email.setToAddresses(new String[] { currentUser.Email });
            
            // Set the subject
            email.setSubject('Upcoming Interview Reminder: ' + jobApplication.Company__c + ' - ' + jobApplication.Position__c);
            
            // Format the interview date
            String formattedDate = jobApplication.InterviewDate__c.format('EEEE, MMMM d, yyyy \'at\' h:mm a');
            
            // Create the email body
            String emailBody = 'Hello,<br/><br/>';
            emailBody += 'This is a reminder that you have an upcoming interview:<br/><br/>';
            emailBody += '<b>Company:</b> ' + jobApplication.Company__c + '<br/>';
            emailBody += '<b>Position:</b> ' + jobApplication.Position__c + '<br/>';
            emailBody += '<b>Date and Time:</b> ' + formattedDate + '<br/>';
            
            // Add contact information if available
            if (String.isNotBlank(jobApplication.ContactName__c)) {
                emailBody += '<b>Contact:</b> ' + jobApplication.ContactName__c + '<br/>';
            }
            
            if (String.isNotBlank(jobApplication.ContactEmail__c)) {
                emailBody += '<b>Contact Email:</b> ' + jobApplication.ContactEmail__c + '<br/>';
            }
            
            emailBody += '<br/>Good luck with your interview!<br/><br/>';
            emailBody += 'Job Application Tracker<br/>';
            
            email.setHtmlBody(emailBody);
            
            // Send the email
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
            // Update the Job Application to indicate the reminder was sent
            if (results[0].isSuccess()) {
                jobApplication.ReminderSent__c = true;
                update jobApplication;
                return true;
            }
            
            return false;
        } catch (Exception e) {
            System.debug('Error sending interview reminder: ' + e.getMessage());
            return false;
        }
    }
} 