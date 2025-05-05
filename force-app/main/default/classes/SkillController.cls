public with sharing class SkillController {
    
    /**
     * Get all skills from custom metadata
     * @return List of skills
     */
    @AuraEnabled(cacheable=true)
    public static List<SkillDto> getAllSkills() {
        try {
            List<Skill__mdt> skillMdts = [
                SELECT Id, MasterLabel, DeveloperName, Category__c, Description__c
                FROM Skill__mdt
                WHERE IsActive__c = true
                ORDER BY Category__c, MasterLabel
            ];
            
            List<SkillDto> skills = new List<SkillDto>();
            for (Skill__mdt skillMdt : skillMdts) {
                SkillDto skill = new SkillDto();
                skill.id = skillMdt.Id;
                skill.name = skillMdt.MasterLabel;
                skill.developerName = skillMdt.DeveloperName;
                skill.category = skillMdt.Category__c;
                skill.description = skillMdt.Description__c;
                
                skills.add(skill);
            }
            
            return skills;
            
        } catch (Exception e) {
            System.debug('Error getting skills: ' + e.getMessage());
            throw new AuraHandledException('Error getting skills: ' + e.getMessage());
        }
    }
    
    /**
     * Get skills by category
     * @param category The category to filter by
     * @return List of skills in the specified category
     */
    @AuraEnabled(cacheable=true)
    public static List<SkillDto> getSkillsByCategory(String category) {
        if (String.isBlank(category)) {
            return getAllSkills();
        }
        
        try {
            List<Skill__mdt> skillMdts = [
                SELECT Id, MasterLabel, DeveloperName, Category__c, Description__c
                FROM Skill__mdt
                WHERE IsActive__c = true
                AND Category__c = :category
                ORDER BY MasterLabel
            ];
            
            List<SkillDto> skills = new List<SkillDto>();
            for (Skill__mdt skillMdt : skillMdts) {
                SkillDto skill = new SkillDto();
                skill.id = skillMdt.Id;
                skill.name = skillMdt.MasterLabel;
                skill.developerName = skillMdt.DeveloperName;
                skill.category = skillMdt.Category__c;
                skill.description = skillMdt.Description__c;
                
                skills.add(skill);
            }
            
            return skills;
            
        } catch (Exception e) {
            System.debug('Error getting skills by category: ' + e.getMessage());
            throw new AuraHandledException('Error getting skills by category: ' + e.getMessage());
        }
    }
    
    /**
     * Get available skill categories
     * @return List of skill categories
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getSkillCategories() {
        try {
            List<AggregateResult> results = [
                SELECT Category__c
                FROM Skill__mdt
                WHERE IsActive__c = true
                GROUP BY Category__c
                ORDER BY Category__c
            ];
            
            List<String> categories = new List<String>();
            for (AggregateResult result : results) {
                categories.add((String)result.get('Category__c'));
            }
            
            return categories;
            
        } catch (Exception e) {
            System.debug('Error getting skill categories: ' + e.getMessage());
            throw new AuraHandledException('Error getting skill categories: ' + e.getMessage());
        }
    }
    
    /**
     * Data transfer object for Skill
     */
    public class SkillDto {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String developerName;
        @AuraEnabled public String category;
        @AuraEnabled public String description;
    }
} 