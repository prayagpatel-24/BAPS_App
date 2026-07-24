class MukhpathItem {
  const MukhpathItem({
    required this.id,
    required this.question,
    required this.answer,
  });

  final String id;
  final String question;
  final String answer;

  String get englishQuestion => _englishQuestions[id] ?? question;
  String get englishAnswer => _englishAnswers[id] ?? answer;

  static const _englishQuestions = <String, String>{
    'm1': 'What is the most important rule for a sattvik life?',
    'm2': 'What is the first requirement for devotion to God?',
    'm3': 'What is the main fruit of satsang?',
    'm4': 'How can helping others be considered good?',
    'm5': 'What should one do to live without fear?',
    'm6': 'What is the opposite of selfishness?',
    'm7': 'What is the greatest practice in devotion?',
    'm8': 'Which thoughts should we avoid?',
    'm9': 'What is the root of knowledge?',
    'm10': 'What is the effect of good deeds?',
    'm11': 'What is the highest form of love?',
    'm12': 'What should we remember at all times?',
    'm13': 'What does self-control mean?',
    'm14': 'What is the main foundation of good conduct?',
    'm15': 'What do we learn in satsang?',
    'm16': 'What is the best divine effect of devotion?',
    'm17': 'What should one do for a healthy mind?',
    'm18': 'What is the basis of a divine life?',
    'm19': 'What is the main ornament of faith?',
    'm20': 'What should we keep in mind when there is a need?',
  };

  static const _englishAnswers = <String, String>{
    'm1': 'To live truthfully and peacefully.',
    'm2': 'Clear and faithful trust.',
    'm3': 'Inner peace and guidance.',
    'm4': 'By doing good for others and working together.',
    'm5': 'Rely on God and keep good thoughts.',
    'm6': 'Charity and service.',
    'm7': 'Faithful and regular worship.',
    'm8': 'Thoughts of violence and bitterness.',
    'm9': 'Understanding the depth of truth.',
    'm10': 'Inner refinement and joy.',
    'm11': 'Trust and service toward others.',
    'm12': 'The remembrance of God.',
    'm13': 'Keeping our thoughts and actions under control.',
    'm14': 'Truth, kindness, and compassion.',
    'm15': 'To walk on the path of truth.',
    'm16': 'Spiritual peace and protection.',
    'm17': 'Regular meditation and a peaceful mind.',
    'm18': 'True personal discipline.',
    'm19': 'Good actions and faithfulness.',
    'm20': 'Cooperation and support for others.',
  };
}
