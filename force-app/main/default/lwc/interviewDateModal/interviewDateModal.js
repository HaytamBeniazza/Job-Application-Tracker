import { LightningElement, api } from 'lwc';

export default class InterviewDateModal extends LightningElement {
    @api recordId;
    @api status;
    
    isModalOpen = false;
    interviewDateTime = null;
    minDate = new Date().toISOString();
    
    // Show the modal
    @api
    show() {
        this.isModalOpen = true;
    }
    
    // Hide the modal
    @api
    hide() {
        this.isModalOpen = false;
    }
    
    // Handle date-time input change
    handleDateTimeChange(event) {
        this.interviewDateTime = event.target.value;
    }
    
    // Handle save button click
    handleSave() {
        if (!this.interviewDateTime) {
            // Show validation error
            const input = this.template.querySelector('lightning-input');
            input.setCustomValidity('Please select an interview date and time');
            input.reportValidity();
            return;
        }
        
        // Dispatch the save event with the record ID, status, and interview date-time
        const saveEvent = new CustomEvent('save', {
            detail: {
                recordId: this.recordId,
                status: this.status,
                interviewDateTime: this.interviewDateTime
            }
        });
        this.dispatchEvent(saveEvent);
        
        // Close the modal
        this.hide();
    }
    
    // Handle cancel button click
    handleCancel() {
        // Dispatch the cancel event
        this.dispatchEvent(new CustomEvent('cancel'));
        
        // Close the modal
        this.hide();
    }
} 