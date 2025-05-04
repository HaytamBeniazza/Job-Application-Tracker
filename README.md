# Salesforce Job Application Tracker

A comprehensive Salesforce application designed to help job seekers track their job applications, interviews, and career progress.

## Features

- **Dashboard with Statistics**: Visual analytics showing application status distribution and monthly trends
- **Job Application Management**: Create, track, and manage all your job applications in one place
- **Interview Calendar**: Calendar view to track upcoming interviews and important dates
- **Email Notifications**: Automated reminders for upcoming interviews
- **Data Export**: Export your job application data to CSV for external analysis
- **Mobile Responsive**: Access your job tracking data from any device

## Components

### Apex Classes

- **JobApplicationController**: Main controller for job application operations
- **JobApplicationEmailUtil**: Utilities for sending email notifications
- **JobApplicationReminderBatch**: Batch job for sending interview reminders
- **JobApplicationReminderScheduler**: Scheduler for the reminder batch job
- **JobApplicationStatsController**: Controller for dashboard statistics
- **JobApplicationExportController**: Controller for data export functionality

### Lightning Web Components

- **jobTrackerApp**: Main application container with tabbed interface
- **jobApplicationForm**: Form for creating and editing job applications
- **jobApplicationList**: List view of all job applications
- **jobApplicationCalendar**: Calendar view of application activities
- **jobApplicationDashboard**: Dashboard with statistics and charts
- **upcomingInterviews**: Component showing upcoming interview schedule
- **interviewDateModal**: Modal for scheduling/rescheduling interviews
- **jobApplicationExport**: Component for exporting application data

## Installation

### Prerequisites

- Salesforce org (Enterprise Edition or above recommended)
- Salesforce CLI
- VS Code with Salesforce Extensions

### Deployment Steps

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/job-application-tracker.git
   ```

2. Log in to your Salesforce org:
   ```
   sfdx force:auth:web:login -a YourOrgAlias
   ```

3. Deploy the components:
   ```
   sfdx force:source:deploy -p force-app
   ```

4. Assign permissions:
   ```
   sfdx force:user:permset:assign -n JobApplicationTracker
   ```

5. Initialize sample data (optional):
   ```
   sfdx force:apex:execute -f scripts/apex/init-data.apex
   ```

## Usage

1. Navigate to the Job Application Tracker tab in Salesforce
2. Use the form to add new job applications
3. Track interview status and outcomes in the list view
4. View upcoming interviews in the Calendar tab
5. Monitor your job search progress in the Dashboard
6. Export your data as needed using the Export function

## Scheduled Jobs

The application includes scheduled reminders for upcoming interviews. To activate this feature:

1. Open Developer Console
2. Execute the following Apex:
   ```java
   JobApplicationReminderScheduler.scheduleDaily();
   ```

This will schedule the reminder job to run daily at 8:00 AM.

## Customization

You can customize the application by:

1. Modifying the JobApplication__c custom object to add additional fields
2. Updating the LWC components to display your custom fields
3. Creating additional reports and dashboards

## Security

The application uses with sharing Apex classes to enforce Salesforce security controls. Make sure users have appropriate permissions to:

- Create, Read, Update and Delete JobApplication__c records
- Send emails
- Access reports and dashboards

## Support and Contributions

For questions, bug reports, or feature requests, please open an issue in the repository. Pull requests for improvements are welcome. 