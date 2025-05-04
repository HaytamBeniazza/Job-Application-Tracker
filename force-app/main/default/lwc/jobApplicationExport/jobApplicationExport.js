import { LightningElement, track, wire } from 'lwc';
import { DataExportUtil } from 'c/dataExportUtil';
import getJobApplications from '@salesforce/apex/JobApplicationExportController.getJobApplications';

export default class JobApplicationExport extends LightningElement {
    @track isLoading = false;
    @track startDate;
    @track endDate;
    @track selectedStatus = '';
    @track applications = [];
    
    // Status options for filtering
    get statusOptions() {
        return [
            { label: 'All Statuses', value: '' },
            { label: 'Submitted', value: 'Submitted' },
            { label: 'Interview Scheduled', value: 'Interview Scheduled' },
            { label: 'Rejected', value: 'Rejected' },
            { label: 'Offer Received', value: 'Offer Received' },
            { label: 'Accepted', value: 'Accepted' }
        ];
    }
    
    // Column definitions for export
    get columns() {
        return [
            { label: 'Company', fieldName: 'Company__c' },
            { label: 'Position', fieldName: 'Position__c' },
            { label: 'Application Date', fieldName: 'ApplicationDate__c' },
            { label: 'Status', fieldName: 'Status__c' },
            { label: 'Interview Date', fieldName: 'InterviewDate__c' },
            { label: 'Contact Name', fieldName: 'ContactName__c' },
            { label: 'Contact Email', fieldName: 'ContactEmail__c' },
            { label: 'Notes', fieldName: 'Notes__c' }
        ];
    }
    
    // Handle date inputs
    handleDateChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
    }
    
    // Handle status selection
    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
    }
    
    // Reset filters
    handleReset() {
        this.startDate = null;
        this.endDate = null;
        this.selectedStatus = '';
        
        // Reset the form fields
        this.template.querySelectorAll('lightning-input, lightning-combobox').forEach(field => {
            field.value = null;
        });
    }
    
    // Fetch job applications based on filters
    async handleFetchData() {
        this.isLoading = true;
        
        try {
            const result = await getJobApplications({
                startDate: this.startDate || null,
                endDate: this.endDate || null,
                status: this.selectedStatus || null
            });
            
            this.applications = result;
            
            if (this.applications.length === 0) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'No Data',
                        message: 'No job applications found with the current filters.',
                        variant: 'info'
                    })
                );
            }
        } catch (error) {
            console.error('Error fetching job applications', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error fetching job applications: ' + error.message,
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }
    
    // Export the data to CSV
    handleExport() {
        if (!this.applications || this.applications.length === 0) {
            this.handleFetchData().then(() => {
                if (this.applications && this.applications.length > 0) {
                    this.executeExport();
                }
            });
        } else {
            this.executeExport();
        }
    }
    
    // Perform the actual export
    executeExport() {
        const fileName = 'Job_Applications_Export.csv';
        
        DataExportUtil.exportToCSV(
            this, 
            this.applications, 
            this.columns, 
            fileName
        );
    }
} 