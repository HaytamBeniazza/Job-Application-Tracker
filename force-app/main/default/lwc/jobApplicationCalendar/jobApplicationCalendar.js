import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getJobApplications from '@salesforce/apex/JobApplicationController.getJobApplications';

export default class JobApplicationCalendar extends LightningElement {
    @track isLoading = true;
    @track calendarEvents = [];
    @track selectedDate = new Date();
    @track currentMonth;
    @track currentYear;
    @track calendarDays = [];
    @track weeks = [];
    
    daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    // Wire the Apex method to get job applications
    @wire(getJobApplications)
    wiredJobApplications({ error, data }) {
        this.isLoading = true;
        
        if (data) {
            // Transform job applications into calendar events
            this.calendarEvents = this.processJobApplications(data);
            this.buildCalendar();
            this.isLoading = false;
        } else if (error) {
            this.handleError(error);
            this.isLoading = false;
        }
    }
    
    // Process job applications into calendar events
    processJobApplications(applications) {
        const events = [];
        
        applications.forEach(app => {
            // Add application date events
            if (app.ApplicationDate__c) {
                events.push({
                    id: app.Id + '-app',
                    title: `${app.Company__c} - Applied`,
                    date: new Date(app.ApplicationDate__c),
                    type: 'application',
                    status: app.Status__c,
                    details: app
                });
            }
            
            // Add interview date events
            if (app.InterviewDate__c) {
                events.push({
                    id: app.Id + '-interview',
                    title: `${app.Company__c} - Interview`,
                    date: new Date(app.InterviewDate__c),
                    type: 'interview',
                    status: app.Status__c,
                    details: app
                });
            }
        });
        
        return events;
    }
    
    // Initialize the calendar
    connectedCallback() {
        this.currentMonth = this.selectedDate.getMonth();
        this.currentYear = this.selectedDate.getFullYear();
    }
    
    // Build the calendar
    buildCalendar() {
        const firstDay = new Date(this.currentYear, this.currentMonth, 1);
        const lastDay = new Date(this.currentYear, this.currentMonth + 1, 0);
        const numDays = lastDay.getDate();
        const firstDayOfWeek = firstDay.getDay();
        
        // Reset calendar days
        this.calendarDays = [];
        
        // Add empty cells for days before the first day of the month
        for (let i = 0; i < firstDayOfWeek; i++) {
            this.calendarDays.push({
                day: '',
                date: null,
                isToday: false,
                events: []
            });
        }
        
        // Add days of the month
        const today = new Date();
        for (let i = 1; i <= numDays; i++) {
            const date = new Date(this.currentYear, this.currentMonth, i);
            const isToday = date.getDate() === today.getDate() && 
                           date.getMonth() === today.getMonth() && 
                           date.getFullYear() === today.getFullYear();
            
            // Get events for this day
            const events = this.calendarEvents.filter(event => {
                const eventDate = new Date(event.date);
                return eventDate.getDate() === i && 
                       eventDate.getMonth() === this.currentMonth && 
                       eventDate.getFullYear() === this.currentYear;
            });
            
            this.calendarDays.push({
                day: i,
                date: date,
                isToday: isToday,
                events: events
            });
        }
        
        // Group days into weeks
        this.weeks = [];
        for (let i = 0; i < this.calendarDays.length; i += 7) {
            this.weeks.push(this.calendarDays.slice(i, i + 7));
        }
    }
    
    // Handle previous month button click
    handlePreviousMonth() {
        this.currentMonth--;
        if (this.currentMonth < 0) {
            this.currentMonth = 11;
            this.currentYear--;
        }
        this.buildCalendar();
    }
    
    // Handle next month button click
    handleNextMonth() {
        this.currentMonth++;
        if (this.currentMonth > 11) {
            this.currentMonth = 0;
            this.currentYear++;
        }
        this.buildCalendar();
    }
    
    // Get current month and year
    get formattedMonthYear() {
        return `${this.months[this.currentMonth]} ${this.currentYear}`;
    }
    
    // Handle error
    handleError(error) {
        console.error('Error:', error);
        
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'An error occurred',
                variant: 'error'
            })
        );
    }
} 