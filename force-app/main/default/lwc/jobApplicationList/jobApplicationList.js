import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { formatDate, formatDateTime, getStatusColor } from 'c/jobTrackerUtils';
import getJobApplications from '@salesforce/apex/JobApplicationController.getJobApplications';
import updateJobApplicationStatus from '@salesforce/apex/JobApplicationController.updateJobApplicationStatus';

export default class JobApplicationList extends LightningElement {
    @track jobApplications = [];
    @track filteredApplications = [];
    @track selectedView = 'all';
    @track isLoading = true;
    @track showNewForm = false;
    
    wiredJobApplicationsResult;
    
    statusOptions = [
        { label: 'Applied', value: 'Applied' },
        { label: 'Screening', value: 'Screening' },
        { label: 'Interview Scheduled', value: 'Interview Scheduled' },
        { label: 'Interview Completed', value: 'Interview Completed' },
        { label: 'Offer Received', value: 'Offer Received' },
        { label: 'Accepted', value: 'Accepted' },
        { label: 'Rejected', value: 'Rejected' },
        { label: 'Declined', value: 'Declined' }
    ];
    
    viewOptions = [
        { label: 'All Applications', value: 'all' },
        { label: 'Active Applications', value: 'active' },
        { label: 'Interviews Scheduled', value: 'interviews' },
        { label: 'Offers', value: 'offers' },
        { label: 'Closed', value: 'closed' }
    ];
    
    // Wire the Apex method to get job applications
    @wire(getJobApplications)
    wiredJobApplications(result) {
        this.wiredJobApplicationsResult = result;
        this.isLoading = true;
        
        if (result.data) {
            this.jobApplications = result.data.map(app => ({
                ...app,
                formattedApplicationDate: formatDate(app.ApplicationDate__c),
                formattedInterviewDate: app.InterviewDate__c ? formatDateTime(app.InterviewDate__c) : '',
                statusClass: 'slds-badge ' + getStatusColor(app.Status__c)
            }));
            
            this.filterApplications();
            this.isLoading = false;
        } else if (result.error) {
            this.handleError(result.error);
            this.isLoading = false;
        }
    }
    
    // Handle status change
    handleStatusChange(event) {
        const recordId = event.target.dataset.recordid;
        const status = event.target.value;
        
        // If the status is 'Interview Scheduled', prompt for interview date
        if (status === 'Interview Scheduled') {
            this.promptForInterviewDate(recordId, status);
        } else {
            this.updateStatus(recordId, status, null);
        }
    }
    
    // Prompt for interview date
    promptForInterviewDate(recordId, status) {
        // Use modal or other UI to get interview date
        // For simplicity, we'll just use a date-time picker in a modal
        const modal = this.template.querySelector('.interview-date-modal');
        if (modal) {
            modal.recordId = recordId;
            modal.status = status;
            modal.show();
        }
    }
    
    // Update the status
    async updateStatus(recordId, status, interviewDate) {
        this.isLoading = true;
        
        try {
            await updateJobApplicationStatus({
                recordId: recordId,
                status: status,
                interviewDate: interviewDate
            });
            
            // Refresh the data
            await refreshApex(this.wiredJobApplicationsResult);
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Job application status updated',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }
    
    // Filter applications based on selected view
    filterApplications() {
        switch (this.selectedView) {
            case 'all':
                this.filteredApplications = [...this.jobApplications];
                break;
            case 'active':
                this.filteredApplications = this.jobApplications.filter(app => 
                    ['Applied', 'Screening', 'Interview Scheduled', 'Interview Completed'].includes(app.Status__c)
                );
                break;
            case 'interviews':
                this.filteredApplications = this.jobApplications.filter(app => 
                    app.Status__c === 'Interview Scheduled'
                );
                break;
            case 'offers':
                this.filteredApplications = this.jobApplications.filter(app => 
                    app.Status__c === 'Offer Received'
                );
                break;
            case 'closed':
                this.filteredApplications = this.jobApplications.filter(app => 
                    ['Accepted', 'Rejected', 'Declined'].includes(app.Status__c)
                );
                break;
            default:
                this.filteredApplications = [...this.jobApplications];
        }
    }
    
    // Handle view change
    handleViewChange(event) {
        this.selectedView = event.detail.value;
        this.filterApplications();
    }
    
    // Handle new application button click
    handleNewApplication() {
        this.showNewForm = true;
    }
    
    // Handle form cancel
    handleFormCancel() {
        this.showNewForm = false;
    }
    
    // Handle form success
    async handleFormSuccess() {
        this.showNewForm = false;
        await refreshApex(this.wiredJobApplicationsResult);
    }
    
    // Handle error
    handleError(error) {
        console.error('Error:', error);
        
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'An error occurred',
                variant: 'error'
            })
        );
    }
    
    // Refresh data
    async refreshData() {
        this.isLoading = true;
        await refreshApex(this.wiredJobApplicationsResult);
        this.isLoading = false;
    }
} 