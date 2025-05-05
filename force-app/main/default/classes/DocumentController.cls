public with sharing class DocumentController {
    
    /**
     * Get all documents
     * @return List of documents
     */
    @AuraEnabled(cacheable=true)
    public static List<Document__c> getAllDocuments() {
        try {
            return [
                SELECT Id, Name, DocumentType__c, Version__c, FileURL__c, Description__c, CreatedDate
                FROM Document__c
                ORDER BY DocumentType__c, Name, Version__c DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving documents: ' + e.getMessage());
        }
    }
    
    /**
     * Get documents by type
     * @param documentType The type of document to filter by
     * @return List of documents of the specified type
     */
    @AuraEnabled(cacheable=true)
    public static List<Document__c> getDocumentsByType(String documentType) {
        try {
            return [
                SELECT Id, Name, DocumentType__c, Version__c, FileURL__c, Description__c, CreatedDate
                FROM Document__c
                WHERE DocumentType__c = :documentType
                ORDER BY Name, Version__c DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving documents by type: ' + e.getMessage());
        }
    }
    
    /**
     * Get documents associated with a job application
     * @param jobApplicationId The ID of the job application
     * @return List of documents associated with the job application
     */
    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getDocumentsByJobApplication(String jobApplicationId) {
        try {
            List<JobApplicationDocument__c> junctionRecords = [
                SELECT Id, Document__c, Document__r.Name, Document__r.DocumentType__c, 
                       Document__r.Version__c, Document__r.FileURL__c, Document__r.Description__c,
                       Document__r.CreatedDate
                FROM JobApplicationDocument__c
                WHERE JobApplication__c = :jobApplicationId
                ORDER BY Document__r.DocumentType__c, Document__r.Name, Document__r.Version__c DESC
            ];
            
            List<DocumentWrapper> wrappers = new List<DocumentWrapper>();
            for (JobApplicationDocument__c junction : junctionRecords) {
                DocumentWrapper wrapper = new DocumentWrapper();
                wrapper.junctionId = junction.Id;
                wrapper.documentId = junction.Document__c;
                wrapper.name = junction.Document__r.Name;
                wrapper.documentType = junction.Document__r.DocumentType__c;
                wrapper.version = junction.Document__r.Version__c;
                wrapper.fileUrl = junction.Document__r.FileURL__c;
                wrapper.description = junction.Document__r.Description__c;
                wrapper.createdDate = junction.Document__r.CreatedDate;
                
                wrappers.add(wrapper);
            }
            
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving documents by job application: ' + e.getMessage());
        }
    }
    
    /**
     * Save a document and associate it with a job application
     * @param documentName The name of the document
     * @param documentType The type of document
     * @param version The version of the document
     * @param fileUrl The URL of the file
     * @param description The description of the document
     * @param jobApplicationId The ID of the job application to associate the document with
     * @return The ID of the created document
     */
    @AuraEnabled
    public static String saveDocument(String documentName, String documentType, 
                                     Decimal version, String fileUrl, 
                                     String description, String jobApplicationId) {
        try {
            // Create the document record
            Document__c doc = new Document__c(
                Name = documentName,
                DocumentType__c = documentType,
                Version__c = version,
                FileURL__c = fileUrl,
                Description__c = description
            );
            
            insert doc;
            
            // Create the junction record if a job application ID is provided
            if (String.isNotBlank(jobApplicationId)) {
                JobApplicationDocument__c junction = new JobApplicationDocument__c(
                    JobApplication__c = jobApplicationId,
                    Document__c = doc.Id
                );
                
                insert junction;
            }
            
            return doc.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving document: ' + e.getMessage());
        }
    }
    
    /**
     * Associate an existing document with a job application
     * @param documentId The ID of the document
     * @param jobApplicationId The ID of the job application
     * @return The ID of the created junction record
     */
    @AuraEnabled
    public static String associateDocumentWithJobApplication(String documentId, String jobApplicationId) {
        try {
            // Check if the association already exists
            List<JobApplicationDocument__c> existingAssociations = [
                SELECT Id FROM JobApplicationDocument__c
                WHERE Document__c = :documentId
                AND JobApplication__c = :jobApplicationId
                LIMIT 1
            ];
            
            if (!existingAssociations.isEmpty()) {
                return existingAssociations[0].Id;
            }
            
            // Create the junction record
            JobApplicationDocument__c junction = new JobApplicationDocument__c(
                JobApplication__c = jobApplicationId,
                Document__c = documentId
            );
            
            insert junction;
            
            return junction.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error associating document with job application: ' + e.getMessage());
        }
    }
    
    /**
     * Remove association between a document and a job application
     * @param junctionId The ID of the junction record
     * @return True if the association was removed successfully
     */
    @AuraEnabled
    public static Boolean removeDocumentAssociation(String junctionId) {
        try {
            delete new JobApplicationDocument__c(Id = junctionId);
            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Error removing document association: ' + e.getMessage());
        }
    }
    
    /**
     * Delete a document
     * @param documentId The ID of the document to delete
     * @return True if the document was deleted successfully
     */
    @AuraEnabled
    public static Boolean deleteDocument(String documentId) {
        try {
            // Delete associated junction records
            delete [
                SELECT Id FROM JobApplicationDocument__c
                WHERE Document__c = :documentId
            ];
            
            // Delete the document
            delete new Document__c(Id = documentId);
            
            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting document: ' + e.getMessage());
        }
    }
    
    /**
     * Wrapper class for document data
     */
    public class DocumentWrapper {
        @AuraEnabled public String junctionId;
        @AuraEnabled public String documentId;
        @AuraEnabled public String name;
        @AuraEnabled public String documentType;
        @AuraEnabled public Decimal version;
        @AuraEnabled public String fileUrl;
        @AuraEnabled public String description;
        @AuraEnabled public Datetime createdDate;
    }
} 