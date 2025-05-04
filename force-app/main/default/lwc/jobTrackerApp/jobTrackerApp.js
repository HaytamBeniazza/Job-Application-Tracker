import { LightningElement, track } from 'lwc';

export default class JobTrackerApp extends LightningElement {
    @track activeTab = 'list';
    
    // Handle tab change
    handleTabChange(event) {
        this.activeTab = event.target.dataset.tabValue;
    }
    
    // Tab class getters
    get listTabClass() {
        return this.activeTab === 'list' ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item';
    }
    
    get calendarTabClass() {
        return this.activeTab === 'calendar' ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item';
    }
    
    get interviewsTabClass() {
        return this.activeTab === 'interviews' ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item';
    }
    
    // Tab visibility getters
    get isListTab() {
        return this.activeTab === 'list';
    }
    
    get isCalendarTab() {
        return this.activeTab === 'calendar';
    }
    
    get isInterviewsTab() {
        return this.activeTab === 'interviews';
    }
} 