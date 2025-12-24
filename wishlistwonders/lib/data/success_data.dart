import '../models/success_person.dart';

class SuccessData {
  static List<SuccessPerson> getSuccessPeople() {
    return [
      SuccessPerson(
        name: 'Sarah Johnson',
        position: 'CEO',
        company: 'Creative Minds Agency',
        industry: 'Advertising',
        imageUrl: '👩‍💼',
        story: 'Started as a junior copywriter, worked her way up through dedication and innovative thinking.',
        milestones: [
          'Junior Copywriter at local agency',
          'Senior Creative Director',
          'VP of Marketing',
          'CEO of Creative Minds Agency',
        ],
        skills: [
          'Creative Thinking',
          'Leadership',
          'Strategic Planning',
          'Client Relations',
          'Digital Marketing',
        ],
      ),
      SuccessPerson(
        name: 'David Chen',
        position: 'Chief Creative Officer',
        company: 'Global Ads Inc',
        industry: 'Advertising',
        imageUrl: '👨‍💼',
        story: 'Built his career through continuous learning and embracing new technologies in advertising.',
        milestones: [
          'Graphic Designer',
          'Art Director',
          'Creative Director',
          'Chief Creative Officer',
        ],
        skills: [
          'Visual Design',
          'Brand Strategy',
          'Team Management',
          'Innovation',
          'Communication',
        ],
      ),
      SuccessPerson(
        name: 'Maria Rodriguez',
        position: 'Marketing Director',
        company: 'Brand Builders Co',
        industry: 'Advertising',
        imageUrl: '👩‍💻',
        story: 'Transformed from a social media manager to leading entire marketing campaigns for Fortune 500 companies.',
        milestones: [
          'Social Media Manager',
          'Digital Marketing Specialist',
          'Marketing Manager',
          'Marketing Director',
        ],
        skills: [
          'Social Media Strategy',
          'Data Analytics',
          'Campaign Management',
          'Budget Planning',
          'Content Creation',
        ],
      ),
    ];
  }
}
