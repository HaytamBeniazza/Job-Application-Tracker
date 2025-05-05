public with sharing class EinsteinSkillMatchingService {
    
    /**
     * Analyze a job description and extract key skills required
     * @param jobDescription The job description text to analyze
     * @return List of skills extracted from the job description
     */
    @AuraEnabled
    public static List<Skill> analyzeJobDescription(String jobDescription) {
        if (String.isBlank(jobDescription)) {
            return new List<Skill>();
        }
        
        try {
            // In a real implementation, this would call the Einstein API
            // For this simulation, we'll extract skills based on keywords
            
            // Convert to lowercase for case-insensitive matching
            String lowerDesc = jobDescription.toLowerCase();
            
            // Get all skill records from our custom metadata
            List<Skill__mdt> allSkills = [
                SELECT Id, MasterLabel, DeveloperName, Category__c, Keywords__c, Description__c 
                FROM Skill__mdt 
                WHERE IsActive__c = true
            ];
            
            // Match skills based on keywords
            List<Skill> matchedSkills = new List<Skill>();
            for (Skill__mdt skillMdt : allSkills) {
                if (String.isBlank(skillMdt.Keywords__c)) {
                    continue;
                }
                
                // Check for keyword matches
                List<String> keywords = skillMdt.Keywords__c.toLowerCase().split(',');
                Boolean found = false;
                Integer matchCount = 0;
                
                for (String keyword : keywords) {
                    keyword = keyword.trim();
                    if (lowerDesc.contains(keyword)) {
                        matchCount++;
                        found = true;
                    }
                }
                
                if (found) {
                    // Calculate match strength based on number of keyword matches and prominence
                    Double matchStrength = calculateMatchStrength(matchCount, lowerDesc, keywords);
                    
                    Skill skill = new Skill();
                    skill.id = skillMdt.Id;
                    skill.name = skillMdt.MasterLabel;
                    skill.category = skillMdt.Category__c;
                    skill.description = skillMdt.Description__c;
                    skill.matchStrength = matchStrength;
                    skill.isHighlighted = matchStrength >= 75;
                    
                    matchedSkills.add(skill);
                }
            }
            
            // Sort by match strength
            matchedSkills.sort();
            
            return matchedSkills;
            
        } catch (Exception e) {
            System.debug('Error analyzing job description: ' + e.getMessage());
            throw new AuraHandledException('Error analyzing job description: ' + e.getMessage());
        }
    }
    
    /**
     * Generate recommendations for skills to highlight based on job description and user skills
     * @param jobDescription The job description text
     * @param userSkillIds List of skill IDs the user possesses
     * @return List of skill recommendations
     */
    @AuraEnabled
    public static List<SkillRecommendation> getSkillRecommendations(String jobDescription, List<String> userSkillIds) {
        if (String.isBlank(jobDescription) || userSkillIds == null || userSkillIds.isEmpty()) {
            return new List<SkillRecommendation>();
        }
        
        try {
            // First analyze the job description to get required skills
            List<Skill> jobSkills = analyzeJobDescription(jobDescription);
            
            // Get the user's skills
            List<Skill__mdt> userSkillMdts = [
                SELECT Id, MasterLabel, DeveloperName, Category__c, Description__c, RelatedSkills__c
                FROM Skill__mdt
                WHERE Id IN :userSkillIds
            ];
            
            // Create a map for easy lookup
            Map<String, Skill__mdt> userSkillMap = new Map<String, Skill__mdt>();
            for (Skill__mdt skill : userSkillMdts) {
                userSkillMap.put(skill.Id, skill);
            }
            
            // Generate recommendations
            List<SkillRecommendation> recommendations = new List<SkillRecommendation>();
            
            // Recommend highlighting skills that are both in the job description and user skills
            for (Skill jobSkill : jobSkills) {
                if (userSkillMap.containsKey(jobSkill.id)) {
                    Skill__mdt userSkill = userSkillMap.get(jobSkill.id);
                    
                    SkillRecommendation rec = new SkillRecommendation();
                    rec.skillId = jobSkill.id;
                    rec.skillName = jobSkill.name;
                    rec.matchStrength = jobSkill.matchStrength;
                    rec.recommendationType = 'highlight';
                    rec.recommendationText = 'Highlight this skill in your resume and cover letter';
                    rec.category = jobSkill.category;
                    
                    recommendations.add(rec);
                }
            }
            
            // Find skills that are mentioned in the job but user doesn't have
            for (Skill jobSkill : jobSkills) {
                if (!userSkillMap.containsKey(jobSkill.id) && jobSkill.matchStrength >= 50) {
                    SkillRecommendation rec = new SkillRecommendation();
                    rec.skillId = jobSkill.id;
                    rec.skillName = jobSkill.name;
                    rec.matchStrength = jobSkill.matchStrength;
                    rec.recommendationType = 'acquire';
                    rec.recommendationText = 'Consider acquiring this skill for better job match';
                    rec.category = jobSkill.category;
                    
                    recommendations.add(rec);
                }
            }
            
            // Find related skills that might be relevant
            Set<String> processedSkills = new Set<String>();
            for (Skill__mdt userSkill : userSkillMdts) {
                if (String.isNotBlank(userSkill.RelatedSkills__c)) {
                    List<String> relatedSkillIds = userSkill.RelatedSkills__c.split(',');
                    
                    for (String relatedId : relatedSkillIds) {
                        relatedId = relatedId.trim();
                        
                        // Skip if already processed
                        if (processedSkills.contains(relatedId)) {
                            continue;
                        }
                        processedSkills.add(relatedId);
                        
                        // Skip if user already has this skill
                        if (userSkillMap.containsKey(relatedId)) {
                            continue;
                        }
                        
                        // Get the related skill details
                        try {
                            Skill__mdt relatedSkill = [
                                SELECT Id, MasterLabel, Category__c, Description__c
                                FROM Skill__mdt
                                WHERE Id = :relatedId AND IsActive__c = true
                                LIMIT 1
                            ];
                            
                            SkillRecommendation rec = new SkillRecommendation();
                            rec.skillId = relatedSkill.Id;
                            rec.skillName = relatedSkill.MasterLabel;
                            rec.matchStrength = 40; // Lower priority for related skills
                            rec.recommendationType = 'related';
                            rec.recommendationText = 'Related to your skill ' + userSkill.MasterLabel;
                            rec.category = relatedSkill.Category__c;
                            
                            recommendations.add(rec);
                            
                        } catch (Exception e) {
                            System.debug('Error getting related skill: ' + e.getMessage());
                        }
                    }
                }
            }
            
            // Sort recommendations by match strength
            recommendations.sort();
            
            return recommendations;
            
        } catch (Exception e) {
            System.debug('Error generating skill recommendations: ' + e.getMessage());
            throw new AuraHandledException('Error generating skill recommendations: ' + e.getMessage());
        }
    }
    
    /**
     * Calculate the match strength of a skill based on keyword matches
     * @param matchCount Number of keyword matches
     * @param jobDescription The job description text
     * @param keywords List of keywords to check
     * @return Match strength percentage (0-100)
     */
    private static Double calculateMatchStrength(Integer matchCount, String jobDescription, List<String> keywords) {
        // Base score based on number of matches
        Double score = 40.0 * Math.min(matchCount, 5) / 5.0;
        
        // Check if keywords appear in the first 500 characters (higher importance)
        String intro = jobDescription.length() > 500 ? jobDescription.substring(0, 500) : jobDescription;
        for (String keyword : keywords) {
            if (intro.contains(keyword.trim())) {
                score += 15.0;
                break;
            }
        }
        
        // Check for phrases that indicate high importance
        List<String> importancePhrases = new List<String>{
            'required', 'must have', 'essential', 'necessary', 'critical', 
            'proficient in', 'expert in', 'experience with', 'knowledge of'
        };
        
        for (String phrase : importancePhrases) {
            for (String keyword : keywords) {
                // Check if the importance phrase is near the keyword
                if (jobDescription.indexOf(phrase + ' ' + keyword.trim()) > -1 || 
                    jobDescription.indexOf(keyword.trim() + ' ' + phrase) > -1) {
                    score += 15.0;
                    break;
                }
            }
        }
        
        // Cap the score at 100
        return Math.min(score, 100.0);
    }
    
    /**
     * Wrapper class for skill data
     */
    public class Skill implements Comparable {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String category;
        @AuraEnabled public String description;
        @AuraEnabled public Double matchStrength;
        @AuraEnabled public Boolean isHighlighted;
        
        // Implement the compareTo method for sorting by match strength (descending)
        public Integer compareTo(Object compareTo) {
            Skill compareToSkill = (Skill)compareTo;
            
            if (matchStrength > compareToSkill.matchStrength) {
                return -1;
            } else if (matchStrength < compareToSkill.matchStrength) {
                return 1;
            } else {
                return 0;
            }
        }
    }
    
    /**
     * Wrapper class for skill recommendations
     */
    public class SkillRecommendation implements Comparable {
        @AuraEnabled public String skillId;
        @AuraEnabled public String skillName;
        @AuraEnabled public String category;
        @AuraEnabled public Double matchStrength;
        @AuraEnabled public String recommendationType; // highlight, acquire, related
        @AuraEnabled public String recommendationText;
        
        // Implement the compareTo method for sorting by match strength (descending)
        public Integer compareTo(Object compareTo) {
            SkillRecommendation compareToRec = (SkillRecommendation)compareTo;
            
            if (matchStrength > compareToRec.matchStrength) {
                return -1;
            } else if (matchStrength < compareToRec.matchStrength) {
                return 1;
            } else {
                return 0;
            }
        }
    }
} 