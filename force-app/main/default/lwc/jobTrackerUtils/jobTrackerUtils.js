/**
 * Formats a date as a string
 * @param {Date} date - The date to format
 * @returns {String} The formatted date string
 */
export function formatDate(date) {
    if (!date) return '';
    
    const options = { 
        weekday: 'long', 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
    };
    
    return new Date(date).toLocaleDateString('en-US', options);
}

/**
 * Formats a datetime as a string
 * @param {Date} datetime - The datetime to format
 * @returns {String} The formatted datetime string
 */
export function formatDateTime(datetime) {
    if (!datetime) return '';
    
    const options = { 
        weekday: 'long', 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    };
    
    return new Date(datetime).toLocaleString('en-US', options);
}

/**
 * Returns the color for a status
 * @param {String} status - The status
 * @returns {String} The color for the status
 */
export function getStatusColor(status) {
    switch (status) {
        case 'Applied':
            return 'slds-theme_info';
        case 'Screening':
            return 'slds-theme_warning';
        case 'Interview Scheduled':
            return 'slds-theme_warning';
        case 'Interview Completed':
            return 'slds-theme_success';
        case 'Offer Received':
            return 'slds-theme_success';
        case 'Accepted':
            return 'slds-theme_success';
        case 'Rejected':
            return 'slds-theme_error';
        case 'Declined':
            return 'slds-theme_error';
        default:
            return 'slds-theme_default';
    }
} 