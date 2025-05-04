import { LightningElement, wire, track } from 'lwc';
import getApplicationStats from '@salesforce/apex/JobApplicationStatsController.getApplicationStats';
import { loadScript } from 'lightning/platformResourceLoader';
import chartjs from '@salesforce/resourceUrl/chartjs';

export default class JobApplicationDashboard extends LightningElement {
    @track stats = {
        totalApplications: 0,
        pendingApplications: 0,
        interviewScheduled: 0,
        rejected: 0,
        offered: 0,
        accepted: 0
    };
    
    @track statusChartConfig;
    @track monthlyChartConfig;
    @track isChartJsInitialized = false;
    
    renderedCallback() {
        if (this.isChartJsInitialized) {
            return;
        }
        
        Promise.all([
            loadScript(this, chartjs)
        ]).then(() => {
            this.isChartJsInitialized = true;
            this.initializeCharts();
        }).catch(error => {
            console.error('Error loading ChartJS', error);
        });
    }
    
    @wire(getApplicationStats)
    wiredStats({ error, data }) {
        if (data) {
            this.stats = data;
            if (this.isChartJsInitialized) {
                this.initializeCharts();
            }
        } else if (error) {
            console.error('Error fetching application stats', error);
        }
    }
    
    initializeCharts() {
        this.initializeStatusChart();
        this.initializeMonthlyChart();
    }
    
    initializeStatusChart() {
        const statusCanvas = this.template.querySelector('canvas.statusChart');
        if (!statusCanvas) return;
        
        this.statusChartConfig = {
            type: 'doughnut',
            data: {
                labels: ['Pending', 'Interview Scheduled', 'Rejected', 'Offered', 'Accepted'],
                datasets: [{
                    data: [
                        this.stats.pendingApplications,
                        this.stats.interviewScheduled,
                        this.stats.rejected,
                        this.stats.offered,
                        this.stats.accepted
                    ],
                    backgroundColor: [
                        '#36A2EB',
                        '#FFCE56',
                        '#FF6384',
                        '#4BC0C0',
                        '#9966FF'
                    ]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                legend: {
                    position: 'right'
                },
                animation: {
                    animateScale: true,
                    animateRotate: true
                }
            }
        };
        
        const ctx = statusCanvas.getContext('2d');
        new window.Chart(ctx, this.statusChartConfig);
    }
    
    initializeMonthlyChart() {
        const monthlyCanvas = this.template.querySelector('canvas.monthlyChart');
        if (!monthlyCanvas) return;
        
        const months = this.stats.monthlyData ? this.stats.monthlyData.map(item => item.month) : [];
        const applications = this.stats.monthlyData ? this.stats.monthlyData.map(item => item.count) : [];
        
        this.monthlyChartConfig = {
            type: 'line',
            data: {
                labels: months,
                datasets: [{
                    label: 'Applications',
                    data: applications,
                    borderColor: '#2196F3',
                    backgroundColor: 'rgba(33, 150, 243, 0.1)',
                    borderWidth: 2,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    xAxes: [{
                        gridLines: {
                            display: false
                        }
                    }],
                    yAxes: [{
                        ticks: {
                            beginAtZero: true,
                            precision: 0
                        }
                    }]
                }
            }
        };
        
        const ctx = monthlyCanvas.getContext('2d');
        new window.Chart(ctx, this.monthlyChartConfig);
    }
} 