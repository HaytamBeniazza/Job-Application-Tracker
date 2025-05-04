import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { formatDateTime } from 'c/jobTrackerUtils';
import getUpcomingInterviews from '@salesforce/apex/JobApplicationController.getUpcomingInterviews';

export default class UpcomingInterviews extends LightningElement {
    @track upcomingInterviews = [];
    @track isLoading = true;
    
    wiredInterviewsResult;
    
    // Wire the Apex method to get upcoming interviews
    @wire(getUpcomingInterviews)
    wiredUpcomingInterviews(result) {
        this.wiredInterviewsResult = result;
        this.isLoading = true;
        
        if (result.data) {
            this.upcomingInterviews = result.data.map(interview => ({
                ...interview,
                formattedInterviewDate: formatDateTime(interview.InterviewDate__c),
                reminderStatus: interview.ReminderSent__c ? 'Sent' : 'Not Sent'
            }));
            this.isLoading = false;
        } else if (result.error) {
            this.handleError(result.error);
            this.isLoading = false;
        }
    }
    
    // Refresh data
    async refreshData() {
        this.isLoading = true;
        await refreshApex(this.wiredInterviewsResult);
        this.isLoading = false;
    }
    
    // Handle error
    handleError(error) {
        console.error('Error:', error);
        
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'An error occurred while retrieving upcoming interviews',
                variant: 'error'
            })
        );
    }
    
    // Check if there are upcoming interviews
    get hasUpcomingInterviews() {
        return this.upcomingInterviews.length > 0;
    }
} 