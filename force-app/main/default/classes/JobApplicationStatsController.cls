public with sharing class JobApplicationStatsController {
    
    @AuraEnabled(cacheable=true)
    public static ApplicationStats getApplicationStats() {
        ApplicationStats stats = new ApplicationStats();
        
        try {
            // Get the total count of applications
            stats.totalApplications = [SELECT COUNT() FROM JobApplication__c];
            
            // Get counts by status
            for(AggregateResult ar : [
                SELECT Status__c, COUNT(Id) statusCount
                FROM JobApplication__c
                GROUP BY Status__c
            ]) {
                String status = (String)ar.get('Status__c');
                Integer count = (Integer)ar.get('statusCount');
                
                switch on status {
                    when 'Submitted' {
                        stats.pendingApplications = count;
                    }
                    when 'Interview Scheduled' {
                        stats.interviewScheduled = count;
                    }
                    when 'Rejected' {
                        stats.rejected = count;
                    }
                    when 'Offer Received' {
                        stats.offered = count;
                    }
                    when 'Accepted' {
                        stats.accepted = count;
                    }
                }
            }
            
            // Get monthly application data for the last 6 months
            List<MonthlyData> monthlyData = new List<MonthlyData>();
            Date sixMonthsAgo = Date.today().addMonths(-6);
            
            for(AggregateResult ar : [
                SELECT CALENDAR_MONTH(ApplicationDate__c) monthNum, 
                       CALENDAR_YEAR(ApplicationDate__c) yearNum,
                       COUNT(Id) appCount
                FROM JobApplication__c
                WHERE ApplicationDate__c >= :sixMonthsAgo
                GROUP BY CALENDAR_MONTH(ApplicationDate__c), CALENDAR_YEAR(ApplicationDate__c)
                ORDER BY CALENDAR_YEAR(ApplicationDate__c), CALENDAR_MONTH(ApplicationDate__c)
            ]) {
                Integer monthNum = (Integer)ar.get('monthNum');
                Integer yearNum = (Integer)ar.get('yearNum');
                Integer count = (Integer)ar.get('appCount');
                
                String monthName = getMonthName(monthNum);
                
                MonthlyData md = new MonthlyData();
                md.month = monthName + ' ' + yearNum;
                md.count = count;
                
                monthlyData.add(md);
            }
            
            stats.monthlyData = monthlyData;
            
            // Get recent activity (last 5 applications or status changes)
            List<RecentActivity> recentActivity = new List<RecentActivity>();
            
            for(JobApplication__c app : [
                SELECT Id, Company__c, Position__c, Status__c, ApplicationDate__c, LastModifiedDate
                FROM JobApplication__c
                ORDER BY LastModifiedDate DESC
                LIMIT 5
            ]) {
                RecentActivity activity = new RecentActivity();
                activity.id = app.Id;
                activity.title = app.Company__c + ' - ' + app.Position__c;
                activity.description = 'Status: ' + app.Status__c;
                activity.date = app.LastModifiedDate.format('MMM d, yyyy h:mm a');
                
                // Set icon based on status
                switch on app.Status__c {
                    when 'Submitted' {
                        activity.icon = 'standard:task';
                    }
                    when 'Interview Scheduled' {
                        activity.icon = 'standard:event';
                    }
                    when 'Rejected' {
                        activity.icon = 'standard:task2';
                    }
                    when 'Offer Received' {
                        activity.icon = 'standard:opportunity';
                    }
                    when 'Accepted' {
                        activity.icon = 'standard:thanks';
                    }
                    when else {
                        activity.icon = 'standard:record';
                    }
                }
                
                recentActivity.add(activity);
            }
            
            stats.recentActivity = recentActivity;
            
        } catch(Exception e) {
            System.debug('Error getting application stats: ' + e.getMessage());
            stats.error = e.getMessage();
        }
        
        return stats;
    }
    
    // Helper method to convert month number to name
    private static String getMonthName(Integer monthNum) {
        List<String> monthNames = new List<String>{
            'January', 'February', 'March', 'April', 'May', 'June', 
            'July', 'August', 'September', 'October', 'November', 'December'
        };
        
        return monthNames[monthNum - 1];
    }
    
    // Wrapper class for the dashboard statistics
    public class ApplicationStats {
        @AuraEnabled public Integer totalApplications = 0;
        @AuraEnabled public Integer pendingApplications = 0;
        @AuraEnabled public Integer interviewScheduled = 0;
        @AuraEnabled public Integer rejected = 0;
        @AuraEnabled public Integer offered = 0;
        @AuraEnabled public Integer accepted = 0;
        @AuraEnabled public List<MonthlyData> monthlyData;
        @AuraEnabled public List<RecentActivity> recentActivity;
        @AuraEnabled public String error;
    }
    
    public class MonthlyData {
        @AuraEnabled public String month;
        @AuraEnabled public Integer count;
    }
    
    public class RecentActivity {
        @AuraEnabled public String id;
        @AuraEnabled public String title;
        @AuraEnabled public String description;
        @AuraEnabled public String date;
        @AuraEnabled public String icon;
    }
} 