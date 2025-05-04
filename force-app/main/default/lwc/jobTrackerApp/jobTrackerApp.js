import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getJobApplications from '@salesforce/apex/JobApplicationController.getJobApplications';

export default class JobTrackerApp extends LightningElement {
    @track activeTab = 'dashboard';
    @track showInterviewModal = false;
    @track selectedApplicationId;
    @track applications = [];
    @track wiredApplicationsResult;
    
    // Tab getters to control active state
    get isDashboardActive() {
        return this.activeTab === 'dashboard';
    }
    
    get isApplicationsActive() {
        return this.activeTab === 'applications';
    }
    
    get isCalendarActive() {
        return this.activeTab === 'calendar';
    }
    
    get isReportsActive() {
        return this.activeTab === 'reports';
    }
    
    // Tab CSS classes
    get dashboardTabClass() {
        return this.activeTab === 'dashboard' ? 'slds-tabs_default__content slds-show' : 'slds-tabs_default__content slds-hide';
    }
    
    get applicationsTabClass() {
        return this.activeTab === 'applications' ? 'slds-tabs_default__content slds-show' : 'slds-tabs_default__content slds-hide';
    }
    
    get calendarTabClass() {
        return this.activeTab === 'calendar' ? 'slds-tabs_default__content slds-show' : 'slds-tabs_default__content slds-hide';
    }
    
    get reportsTabClass() {
        return this.activeTab === 'reports' ? 'slds-tabs_default__content slds-show' : 'slds-tabs_default__content slds-hide';
    }
    
    // Fetch job applications
    @wire(getJobApplications)
    wiredApplications(result) {
        this.wiredApplicationsResult = result;
        if (result.data) {
            this.applications = result.data;
        } else if (result.error) {
            console.error('Error fetching job applications', result.error);
        }
    }
    
    // Handle tab click
    handleTabClick(event) {
        this.activeTab = event.currentTarget.dataset.tabName;
    }
    
    // Handle application submission
    handleApplicationSubmit() {
        this.refreshApplications();
    }
    
    // Refresh applications data
    refreshApplications() {
        return refreshApex(this.wiredApplicationsResult);
    }
    
    // Open interview modal
    openInterviewModal(event) {
        this.selectedApplicationId = event.detail.applicationId;
        this.showInterviewModal = true;
    }
    
    // Close interview modal
    closeInterviewModal() {
        this.showInterviewModal = false;
        this.selectedApplicationId = undefined;
    }
    
    // Handle interview save
    handleInterviewSave() {
        this.closeInterviewModal();
        this.refreshApplications();
    }
} 