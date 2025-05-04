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
        
        // Clear validation errors when user types
        if (event.target.name === 'contactEmail') {
            this.validateEmail(event.target);
        }
    }
    
    // Validate email format
    validateEmail(field) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (field.value && !emailRegex.test(field.value)) {
            field.setCustomValidity('Please enter a valid email address');
        } else {
            field.setCustomValidity('');
        }
        field.reportValidity();
    }
    
    // Validate date is not in the future
    validateDate(field) {
        const selectedDate = new Date(field.value);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        if (selectedDate > today) {
            field.setCustomValidity('Application date cannot be in the future');
        } else {
            field.setCustomValidity('');
        }
        field.reportValidity();
    }
    
    // Validate the form
    validateForm() {
        // Check all standard input validations
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
            
        // Additional custom validations
        const emailField = this.template.querySelector('lightning-input[name="contactEmail"]');
        if (emailField.value) {
            this.validateEmail(emailField);
        }
        
        const dateField = this.template.querySelector('lightning-input[name="applicationDate"]');
        this.validateDate(dateField);
        
        return allValid && (!emailField.value || emailField.checkValidity()) && dateField.checkValidity();
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
                field.setCustomValidity(''); // Clear any validation messages
            });
        }
    }
    
    // Cancel button handler
    handleCancel() {
        this.resetForm();
        this.dispatchEvent(new CustomEvent('cancel'));
    }
} 