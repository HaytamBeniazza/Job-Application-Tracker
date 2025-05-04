import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * Utility class with methods for exporting data from Salesforce
 */
const DataExportUtil = {
    /**
     * Export data to CSV file
     * @param {Object} component - The LWC component instance
     * @param {Array} data - Array of data objects to export
     * @param {Array} columns - Array of column definitions {label: 'Label', fieldName: 'apiName'}
     * @param {String} fileName - Name of the file to download
     */
    exportToCSV: function(component, data, columns, fileName) {
        if (!data || !data.length) {
            this.showToast(component, 'Error', 'No data to export', 'error');
            return;
        }
        
        try {
            // Prepare CSV content
            let csvContent = this.convertToCSV(data, columns);
            
            // Create a blob with the data
            let blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            
            // Create download link and click it
            if (navigator.msSaveBlob) { // For IE
                navigator.msSaveBlob(blob, fileName);
            } else {
                let link = document.createElement('a');
                if (link.download !== undefined) {
                    let url = URL.createObjectURL(blob);
                    link.setAttribute('href', url);
                    link.setAttribute('download', fileName);
                    link.style.visibility = 'hidden';
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                }
            }
            
            this.showToast(component, 'Success', 'Export completed successfully', 'success');
        } catch (error) {
            console.error('Error exporting to CSV: ', error);
            this.showToast(component, 'Error', 'Failed to export data: ' + error.message, 'error');
        }
    },
    
    /**
     * Convert data to CSV string
     * @param {Array} data - Array of data objects
     * @param {Array} columns - Array of column definitions
     * @returns {String} CSV formatted string
     */
    convertToCSV: function(data, columns) {
        // Create CSV header row
        let csvRows = [];
        let headerRow = columns.map(column => '"' + column.label + '"').join(',');
        csvRows.push(headerRow);
        
        // Add data rows
        for (let i = 0; i < data.length; i++) {
            let row = [];
            for (let j = 0; j < columns.length; j++) {
                let fieldName = columns[j].fieldName;
                let value = this.getNestedProperty(data[i], fieldName);
                
                // Handle null or undefined
                if (value === null || value === undefined) {
                    value = '';
                }
                
                // Format based on type
                if (value instanceof Date) {
                    value = value.toISOString().split('T')[0];
                }
                
                // Escape quotes and wrap in quotes
                value = '"' + ('' + value).replace(/"/g, '""') + '"';
                row.push(value);
            }
            csvRows.push(row.join(','));
        }
        
        return csvRows.join('\n');
    },
    
    /**
     * Get property from object even if nested using dot notation
     * @param {Object} obj - Object to get property from
     * @param {String} path - Property path, e.g. "parent.child.property"
     * @returns {*} Property value
     */
    getNestedProperty: function(obj, path) {
        if (!obj || !path) {
            return undefined;
        }
        
        // Handle simple field
        if (obj[path] !== undefined) {
            return obj[path];
        }
        
        // Handle nested fields using dot notation
        const fields = path.split('.');
        let value = obj;
        
        for (let i = 0; i < fields.length; i++) {
            if (value === null || value === undefined) {
                return undefined;
            }
            value = value[fields[i]];
        }
        
        return value;
    },
    
    /**
     * Show a toast notification
     * @param {Object} component - The LWC component instance
     * @param {String} title - Toast title
     * @param {String} message - Toast message
     * @param {String} variant - Toast variant (success, error, warning, info)
     */
    showToast: function(component, title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        component.dispatchEvent(event);
    }
};

export { DataExportUtil }; 