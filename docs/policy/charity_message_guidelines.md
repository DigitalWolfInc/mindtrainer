# Charity Message Guidelines for MindTrainer

## Core Principle
**Charity messaging must be completely separate from app purchases and features to comply with Google Play policies and maintain ethical standards.**

## Prohibited Practices

### ❌ Never Imply Feature Perks Tied to Donations
- **Don't say**: "Donate $5 to unlock premium meditation sounds"
- **Don't say**: "Support our charity partner and get bonus focus sessions"  
- **Don't say**: "Your donation helps us provide Pro features to underserved communities"
- **Don't say**: "Charitable users get priority customer support"

### ❌ Never Bundle Donations with Subscriptions
- **Don't say**: "Pro subscription includes $2/month donation to mental health charities"
- **Don't say**: "Upgrade to Pro and automatically support mindfulness education"
- **Don't say**: "Pro users can enable charitable giving in settings"

### ❌ Never Create Donation-Based App Features
- **Don't create**: "Charity Challenge" sessions that unlock with donations
- **Don't create**: Badge systems tied to donation amounts
- **Don't create**: Leaderboards showing charitable contributions
- **Don't create**: Special content available only to donors

## Approved Practices

### ✅ Educational Content About Mental Health Organizations
- **Acceptable**: "Learn about organizations working to improve mental health accessibility"
- **Acceptable**: Brief descriptions of mental health nonprofits and their missions
- **Acceptable**: General information about mindfulness research and education initiatives

### ✅ External Links Without Incentives
- **Acceptable**: "Visit [Charity Name] to learn about their work" (external link)
- **Acceptable**: "Support mental health research at [University/Organization]" (external link)
- **Acceptable**: Links to meditation teacher training programs or educational resources

### ✅ Seasonal Awareness Campaigns
- **Acceptable**: "Mental Health Awareness Month - Learn about resources in your community"
- **Acceptable**: "World Mental Health Day - Explore mindfulness research and advocacy"
- **Acceptable**: Information about mental health observances with educational focus

## Implementation Requirements

### Message Placement
- Charity information should appear in:
  - **Dedicated "Resources" or "Community" section**
  - **About page or app information area**
  - **Separate educational content area**
- **Never** in:
  - Billing or subscription flows
  - Pro feature unlock screens
  - App functionality areas
  - Push notifications about app features

### Clear Separation Language
Always include disclaimers such as:
- "This link takes you to an external website not affiliated with MindTrainer"
- "Donations are processed by [Charity Name], not through this app"
- "MindTrainer does not collect, process, or benefit from any charitable contributions"
- "All app features are available regardless of any external charitable activity"

### Technical Implementation
```dart
// Example: Compliant charity link implementation
void _showCharityInfo() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Mental Health Resources'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Learn about organizations working to improve mental health awareness and accessibility.'),
          SizedBox(height: 16),
          Text('Note: These are external websites not affiliated with MindTrainer. Any donations are processed independently.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _launchExternalUrl('https://charity.org'),
          child: Text('Visit Organization'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}
```

## Content Guidelines

### Tone and Language
- **Supportive**: Focus on community and shared values
- **Educational**: Emphasize learning and awareness
- **Non-Transactional**: Never suggest quid pro quo arrangements
- **Respectful**: Honor both users and charitable causes

### Word Choice Guidelines
- **Use**: "Learn about", "Explore", "Discover", "Community resources"
- **Use**: "External link", "Independent organization", "Not affiliated"  
- **Avoid**: "Support and get", "Donate to unlock", "Charitable subscribers"
- **Avoid**: "Exclusive", "Premium donors", "Supporter benefits"

## Review Checklist

Before implementing any charity-related content, verify:

- [ ] **No app features tied to donations**
- [ ] **Clear external link disclaimers**
- [ ] **No donation processing within app**
- [ ] **No subscriber-based charity access**
- [ ] **Educational focus, not transactional**
- [ ] **Separate from billing/Pro flows**
- [ ] **No donation amount tracking**
- [ ] **No charity-based user segmentation**

## Examples of Compliant Messaging

### Resource Page Content
```
Mental Health Awareness Resources

MindTrainer believes in supporting mental health education and accessibility. 
Below are some organizations working to improve mental wellness in communities:

• National Alliance on Mental Illness - Education and advocacy
• Mental Health America - Research and community programs  
• Mindfulness in Schools Project - Educational initiatives

Note: These are independent organizations not affiliated with MindTrainer. 
Any donations or involvement with these groups is entirely separate from your 
use of this app.
```

### About Page Addition
```
Community Impact

While MindTrainer focuses on individual wellness, we recognize the importance 
of broader mental health awareness. We encourage users to learn about 
mental health advocacy, research, and education in their communities.

Visit our Resources section to explore organizations working on mental 
health accessibility and mindfulness education.
```

## Legal and Ethical Considerations

### Google Play Compliance
- Prevents violations of "Deceptive Behavior" policies
- Ensures clear separation of app functionality and external activities
- Maintains transparency in subscription billing

### User Trust
- Builds confidence through transparent practices
- Prevents confusion about what users are paying for
- Respects user autonomy in charitable decisions

### Ethical Standards
- Honors charitable organizations by not commercializing their missions
- Maintains integrity of both app functionality and charitable giving
- Supports genuine community impact rather than marketing tactics

## Monitoring and Updates

### Regular Review
- Quarterly review of all charity-related content
- Annual policy compliance audit
- User feedback monitoring for confusion about donations vs. features

### Update Procedures
- All charity content changes must be reviewed by legal team
- Test messaging with small user group before broad release
- Document any policy changes and their rationale

---

**Remember: The goal is to support mental health awareness while maintaining complete separation from app monetization. When in doubt, err on the side of clearer separation and more explicit disclaimers.**