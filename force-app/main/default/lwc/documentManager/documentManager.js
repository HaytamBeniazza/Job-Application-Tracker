import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Import Apex methods
import getAllDocuments from '@salesforce/apex/DocumentController.getAllDocuments';
import getDocumentsByJobApplication from '@salesforce/apex/DocumentController.getDocumentsByJobApplication';
import saveDocument from '@salesforce/apex/DocumentController.saveDocument';
import associateDocumentWithJobApplication from '@salesforce/apex/DocumentController.associateDocumentWithJobApplication';
import removeDocumentAssociation from '@salesforce/apex/DocumentController.removeDocumentAssociation';
import deleteDocument from '@salesforce/apex/DocumentController.deleteDocument';

export default class DocumentManager extends LightningElement {
    @api recordId; // Job Application Id when used in record context
    @api showAllDocuments = false; // Whether to show all documents or only those related to the job application
    @api allowUploads = true; // Whether to show upload controls
    
    @track documents = [];
    @track allDocuments = [];
    @track selectedDocumentId;
    @track isLoading = false;
    @track showNewDocumentModal = false;
    @track showAddExistingModal = false;
    @track documentToDelete;
    @track showDeleteConfirmation = false;
    
    @track newDocument = {
        name: '',
        documentType: 'Resume',
        version: 1.0,
        fileUrl: '',
        description: ''
    };
    
    wiredDocumentsResult;
    wiredAllDocumentsResult;
    
    get hasDocuments() {
        return this.documents && this.documents.length > 0;
    }
    
    get hasNoDocuments() {
        return !this.isLoading && (!this.documents || this.documents.length === 0);
    }
    
    get documentTypeOptions() {
        return [
            { label: 'Resume', value: 'Resume' },
            { label: 'Cover Letter', value: 'Cover Letter' },
            { label: 'Other', value: 'Other' }
        ];
    }
    
    get isNewDocumentFormValid() {
        return this.newDocument.name && 
               this.newDocument.documentType &&
               this.newDocument.fileUrl;
    }
    
    get availableDocumentsForAssociation() {
        if (!this.allDocuments || !this.documents) return [];
        
        // Filter out documents that are already associated with this job application
        const existingDocIds = new Set(this.documents.map(doc => doc.documentId));
        return this.allDocuments.filter(doc => !existingDocIds.has(doc.Id))
            .map(doc => ({
                label: `${doc.Name} (${doc.DocumentType__c} v${doc.Version__c})`,
                value: doc.Id
            }));
    }
    
    // Get CSS class for document type badge
    getDocTypeClass(docType) {
        let baseClass = 'slds-badge ';
        
        switch(docType) {
            case 'Resume':
                return baseClass + 'slds-badge_success';
            case 'Cover Letter':
                return baseClass + 'slds-badge_warning';
            default:
                return baseClass + 'slds-badge_inverse';
        }
    }
    
    // Get icon name based on document type
    getDocIcon(docType) {
        switch(docType) {
            case 'Resume':
                return 'doctype:pdf';
            case 'Cover Letter':
                return 'doctype:txt';
            default:
                return 'doctype:unknown';
        }
    }
    
    // Wire method to get documents for this job application
    @wire(getDocumentsByJobApplication, { jobApplicationId: '$recordId' })
    wiredDocuments(result) {
        this.wiredDocumentsResult = result;
        this.isLoading = true;
        
        if (result.data) {
            this.documents = result.data;
            this.isLoading = false;
        } else if (result.error) {
            this.handleError('Error loading documents', result.error);
            this.isLoading = false;
        }
    }
    
    // Wire method to get all documents for associating with job application
    @wire(getAllDocuments)
    wiredAllDocuments(result) {
        this.wiredAllDocumentsResult = result;
        
        if (result.data) {
            this.allDocuments = result.data;
        } else if (result.error) {
            this.handleError('Error loading all documents', result.error);
        }
    }
    
    // Method to handle new document creation
    handleNewDocumentClick() {
        this.showNewDocumentModal = true;
    }
    
    handleCancelNewDocument() {
        this.showNewDocumentModal = false;
        this.resetNewDocumentForm();
    }
    
    handleDocumentNameChange(event) {
        this.newDocument.name = event.target.value;
    }
    
    handleDocumentTypeChange(event) {
        this.newDocument.documentType = event.target.value;
    }
    
    handleVersionChange(event) {
        this.newDocument.version = event.target.value;
    }
    
    handleFileUrlChange(event) {
        this.newDocument.fileUrl = event.target.value;
    }
    
    handleDescriptionChange(event) {
        this.newDocument.description = event.target.value;
    }
    
    async handleSaveDocument() {
        if (!this.isNewDocumentFormValid) return;
        
        this.isLoading = true;
        
        try {
            await saveDocument({
                documentName: this.newDocument.name,
                documentType: this.newDocument.documentType,
                version: this.newDocument.version,
                fileUrl: this.newDocument.fileUrl,
                description: this.newDocument.description,
                jobApplicationId: this.recordId
            });
            
            this.showToast('Success', 'Document saved successfully', 'success');
            this.showNewDocumentModal = false;
            this.resetNewDocumentForm();
            
            // Refresh the data
            await this.refreshData();
            
        } catch (error) {
            this.handleError('Error saving document', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    // Methods for handling existing document association
    handleAddExistingDocumentClick() {
        this.showAddExistingModal = true;
    }
    
    handleCancelAddExisting() {
        this.showAddExistingModal = false;
        this.selectedDocumentId = null;
    }
    
    handleDocumentSelection(event) {
        this.selectedDocumentId = event.target.value;
    }
    
    async handleAssociateDocument() {
        if (!this.selectedDocumentId) return;
        
        this.isLoading = true;
        
        try {
            await associateDocumentWithJobApplication({
                documentId: this.selectedDocumentId,
                jobApplicationId: this.recordId
            });
            
            this.showToast('Success', 'Document associated successfully', 'success');
            this.showAddExistingModal = false;
            this.selectedDocumentId = null;
            
            // Refresh the data
            await this.refreshData();
            
        } catch (error) {
            this.handleError('Error associating document', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    // Method to handle document removal from job application
    async handleRemoveDocument(event) {
        const junctionId = event.target.dataset.id;
        
        this.isLoading = true;
        
        try {
            await removeDocumentAssociation({ junctionId });
            
            this.showToast('Success', 'Document removed from application', 'success');
            
            // Refresh the data
            await this.refreshData();
            
        } catch (error) {
            this.handleError('Error removing document', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    // Methods for handling document deletion
    handleDeleteDocument(event) {
        this.documentToDelete = event.target.dataset.id;
        this.showDeleteConfirmation = true;
    }
    
    handleCancelDelete() {
        this.showDeleteConfirmation = false;
        this.documentToDelete = null;
    }
    
    async handleConfirmDelete() {
        if (!this.documentToDelete) return;
        
        this.isLoading = true;
        
        try {
            await deleteDocument({ documentId: this.documentToDelete });
            
            this.showToast('Success', 'Document deleted successfully', 'success');
            this.showDeleteConfirmation = false;
            this.documentToDelete = null;
            
            // Refresh the data
            await this.refreshData();
            
        } catch (error) {
            this.handleError('Error deleting document', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    // Helper methods
    resetNewDocumentForm() {
        this.newDocument = {
            name: '',
            documentType: 'Resume',
            version: 1.0,
            fileUrl: '',
            description: ''
        };
    }
    
    async refreshData() {
        await refreshApex(this.wiredDocumentsResult);
        await refreshApex(this.wiredAllDocumentsResult);
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
    
    handleError(title, error) {
        console.error(title, error);
        this.showToast(
            title,
            error.body?.message || error.message || 'Unknown error',
            'error'
        );
    }
    
    handleViewDocument(event) {
        const url = event.target.dataset.url;
        if (url) {
            window.open(url, '_blank');
        }
    }
} 