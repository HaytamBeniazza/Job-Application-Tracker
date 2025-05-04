public with sharing class JobApplicationExportController {
    
    /**
     * Get job applications based on filters
     * @param startDate Optional start date filter
     * @param endDate Optional end date filter
     * @param status Optional status filter
     * @return List of job applications matching the filters
     */
    @AuraEnabled
    public static List<JobApplication__c> getJobApplications(Date startDate, Date endDate, String status) {
        String query = 'SELECT Id, Company__c, Position__c, ApplicationDate__c, Status__c, ' +
                        'InterviewDate__c, ContactName__c, ContactEmail__c, Notes__c ' +
                        'FROM JobApplication__c';
        
        List<String> conditions = new List<String>();
        List<Object> params = new List<Object>();
        
        // Add date range filters if provided
        if (startDate != null) {
            conditions.add('ApplicationDate__c >= :startDate');
            params.add(startDate);
        }
        
        if (endDate != null) {
            conditions.add('ApplicationDate__c <= :endDate');
            params.add(endDate);
        }
        
        // Add status filter if provided
        if (String.isNotBlank(status)) {
            conditions.add('Status__c = :status');
            params.add(status);
        }
        
        // Build the WHERE clause if conditions exist
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        // Add order by
        query += ' ORDER BY ApplicationDate__c DESC';
        
        // Execute the query
        List<JobApplication__c> applications = Database.query(query);
        
        return applications;
    }
    
    /**
     * Get a file download URL for the generated CSV
     * @param csvContent The CSV content to save as a file
     * @return The download URL for the generated file
     */
    @AuraEnabled
    public static String generateCSVFile(String csvContent) {
        try {
            // Create a content version
            ContentVersion cv = new ContentVersion();
            cv.VersionData = Blob.valueOf(csvContent);
            cv.Title = 'JobApplications_' + Datetime.now().format('yyyy-MM-dd') + '.csv';
            cv.PathOnClient = cv.Title;
            
            insert cv;
            
            // Get the content document ID
            Id contentDocumentId = [
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :cv.Id
            ].ContentDocumentId;
            
            // Return the URL to download the file
            return '/sfc/servlet.shepherd/document/download/' + contentDocumentId;
        } catch(Exception e) {
            System.debug('Error generating CSV file: ' + e.getMessage());
            throw new AuraHandledException('Error generating CSV file: ' + e.getMessage());
        }
    }
} 