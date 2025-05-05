import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import analyzeJobDescription from '@salesforce/apex/EinsteinSkillMatchingService.analyzeJobDescription';
import getSkillRecommendations from '@salesforce/apex/EinsteinSkillMatchingService.getSkillRecommendations';
import getAllSkills from '@salesforce/apex/SkillController.getAllSkills';

export default class JobSkillMatcher extends LightningElement {
    @track jobDescription = '';
    @track matchedSkills = [];
    @track recommendations = [];
    @track availableSkills = [];
    @track selectedSkills = [];
    @track isLoading = false;
    @track activeTab = 'skills';
    
    // Computed properties
    get hasResults() {
        return this.matchedSkills.length > 0 || this.recommendations.length > 0;
    }
    
    get isAnalyzeDisabled() {
        return !this.jobDescription || this.jobDescription.trim() === '';
    }
    
    get isRecommendationsDisabled() {
        return this.isAnalyzeDisabled || this.selectedSkills.length === 0;
    }
    
    get skillOptions() {
        return this.availableSkills.map(skill => {
            return {
                label: skill.name + ' (' + skill.category + ')',
                value: skill.id
            };
        });
    }
    
    // Group recommendations by type for easier rendering
    get recommendationsByType() {
        const result = {
            highlight: [],
            acquire: [],
            related: []
        };
        
        if (this.recommendations) {
            this.recommendations.forEach(rec => {
                if (rec.recommendationType === 'highlight') {
                    result.highlight.push(rec);
                } else if (rec.recommendationType === 'acquire') {
                    result.acquire.push(rec);
                } else if (rec.recommendationType === 'related') {
                    result.related.push(rec);
                }
            });
        }
        
        return result;
    }
    
    // Wire method to get all skills
    @wire(getAllSkills)
    wiredSkills({ error, data }) {
        if (data) {
            this.availableSkills = data;
        } else if (error) {
            this.handleError('Error loading skills', error);
        }
    }
    
    // Event handlers
    handleJobDescriptionChange(event) {
        this.jobDescription = event.target.value;
    }
    
    handleSkillsChange(event) {
        this.selectedSkills = event.detail.value;
    }
    
    async handleAnalyzeClick() {
        if (this.isAnalyzeDisabled) {
            return;
        }
        
        this.isLoading = true;
        try {
            this.matchedSkills = await analyzeJobDescription({ jobDescription: this.jobDescription });
            
            // Show toast notification
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `Found ${this.matchedSkills.length} skills in the job description`,
                    variant: 'success'
                })
            );
            
        } catch (error) {
            this.handleError('Error analyzing job description', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    async handleRecommendationsClick() {
        if (this.isRecommendationsDisabled) {
            return;
        }
        
        this.isLoading = true;
        try {
            this.recommendations = await getSkillRecommendations({
                jobDescription: this.jobDescription,
                userSkillIds: this.selectedSkills
            });
            
            // Show toast notification
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `Generated ${this.recommendations.length} skill recommendations`,
                    variant: 'success'
                })
            );
            
        } catch (error) {
            this.handleError('Error generating recommendations', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    // Helper methods
    handleError(title, error) {
        console.error(title, error);
        
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: error.message || 'Unknown error',
                variant: 'error'
            })
        );
    }
    
    getProgressBarVariant(matchStrength) {
        if (matchStrength >= 75) {
            return 'success';
        } else if (matchStrength >= 50) {
            return 'warning';
        } else {
            return 'info';
        }
    }
    
    getSkillCategoryStyle(skill) {
        let backgroundColor;
        
        switch(skill.category) {
            case 'Technical':
                backgroundColor = '#1589ee';
                break;
            case 'Soft Skill':
                backgroundColor = '#4bca81';
                break;
            case 'Domain Knowledge':
                backgroundColor = '#ffb75d';
                break;
            case 'Language':
                backgroundColor = '#54698d';
                break;
            case 'Certification':
                backgroundColor = '#e56798';
                break;
            case 'Tool':
                backgroundColor = '#3296ed';
                break;
            default:
                backgroundColor = '#706e6b';
        }
        
        return `background-color: ${backgroundColor}; color: white;`;
    }
} 