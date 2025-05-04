# Job Application Tracker for Salesforce

A comprehensive job application tracking system built on the Salesforce platform.

## Features

- **Track Job Applications**: Store and manage job applications including company, position, status, contact information, and notes.
- **Calendar View**: Visualize application and interview dates in a calendar format.
- **Status Management**: Update application statuses as they progress through the hiring pipeline.
- **Email Reminders**: Receive automated email reminders before scheduled interviews.
- **Comprehensive Test Coverage**: Full test suite for all Apex classes.

## Components

### Apex Classes

- **JobApplicationController**: Handles record creation, retrieval, and status updates.
- **JobApplicationEmailUtil**: Utility for sending email notifications.
- **JobApplicationReminderScheduler**: Scheduled job to send email reminders for upcoming interviews.
- **JobApplicationSetup**: Setup class to initialize the application.
- **Test Classes**: Complete test coverage for all Apex code.

### Lightning Web Components (LWC)

- **jobTrackerApp**: Main application component with tabbed interface.
- **jobApplicationForm**: Form for creating new job applications.
- **jobApplicationList**: Table view to display and manage job applications.
- **jobApplicationCalendar**: Calendar view to visualize application and interview dates.
- **upcomingInterviews**: Component to display upcoming interviews.
- **interviewDateModal**: Modal for scheduling interview dates and times.
- **jobTrackerUtils**: Utility functions for formatting dates and getting status colors.

### Custom Object

- **JobApplication__c**: Custom object to store job application data.

## Installation

1. Deploy the code to your Salesforce org using the provided `package.xml`.
2. Add the `jobTrackerApp` component to a Lightning App Page or Home Page.
3. Initialize the application by executing `JobApplicationSetup.initialize()` in the Developer Console to set up the email reminder scheduled job.

## Usage

1. Create new job applications using the application form.
2. Update application statuses as they progress through the hiring process.
3. View upcoming interviews and receive email reminders.
4. Use the calendar view to manage your interview schedule.

## Email Notifications

Email reminders are automatically sent 24 hours before scheduled interviews. The email includes:
- Company name
- Position
- Interview date and time
- Contact information (if available)

## Customization

This application can be customized by:
- Adding new fields to the JobApplication__c object
- Modifying the email template in JobApplicationEmailUtil
- Adjusting the reminder schedule in JobApplicationReminderScheduler

## Testing

The application includes comprehensive test classes for all Apex code:
- JobApplicationControllerTest
- JobApplicationEmailUtilTest
- JobApplicationReminderSchedulerTest
- JobApplicationSetupTest

These tests provide full coverage of all business logic and functionality. 