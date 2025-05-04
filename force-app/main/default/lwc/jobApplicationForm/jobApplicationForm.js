import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createJobApplication from '@salesforce/apex/JobApplicationController.createJobApplication';

export default class JobApplicationForm extends LightningElement {
    @api
    recordId;
    
    @track
    jobApplication = {
        company: '',
        position: '',
        applicationDate: new Date().toISOString().slice(0, 10), // Today's date in YYYY-MM-DD format
        contactName: '',
        contactEmail: ''
    };
    
    isLoading = false;
    
    // Handle input field changes
    handleInputChange(event) {
        const { name, value } = event.target;
        this.jobApplication = {
            ...this.jobApplication,
            [name]: value
        };
    }
    
    // Validate the form
    validateForm() {
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);
        
        return allValid;
    }
    
    // Submit the form
    async handleSubmit(event) {
        event.preventDefault();
        
        if (!this.validateForm()) {
            return;
        }
        
        this.isLoading = true;
        
        try {
            // Call the Apex method to create the job application
            await createJobApplication({
                company: this.jobApplication.company,
                position: this.jobApplication.position,
                applicationDate: this.jobApplication.applicationDate,
                contactName: this.jobApplication.contactName,
                contactEmail: this.jobApplication.contactEmail
            });
            
            // Show success toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Job application created successfully',
                    variant: 'success'
                })
            );
            
            // Reset the form
            this.resetForm();
            
            // Dispatch the success event
            this.dispatchEvent(new CustomEvent('success'));
        } catch (error) {
            console.error('Error creating job application:', error);
            
            // Show error toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'An error occurred while creating the job application',
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }
    
    // Reset the form
    resetForm() {
        this.jobApplication = {
            company: '',
            position: '',
            applicationDate: new Date().toISOString().slice(0, 10),
            contactName: '',
            contactEmail: ''
        };
        
        // Reset all input fields
        if (this.template.querySelectorAll('lightning-input')) {
            this.template.querySelectorAll('lightning-input').forEach(field => {
                if (field.type === 'checkbox') {
                    field.checked = false;
                } else {
                    field.value = '';
                }
            });
        }
    }
    
    // Cancel button handler
    handleCancel() {
        this.resetForm();
        this.dispatchEvent(new CustomEvent('cancel'));
    }
} 