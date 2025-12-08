class CompetitionRule {
  final String id;      // например: 'fastest_time'
  final String title;   // 'Fastest time'
  final String description;

  const CompetitionRule({
    required this.id,
    required this.title,
    required this.description,
  });
}

const lorem =
    'Lorem ipsum, or lipsum as it is sometimes known, is dummy text used in laying out print, '
    'graphic or web designs. In publishing and graphic design, Lorem ipsum is a placeholder text.';

const competitionRules = <CompetitionRule>[
  CompetitionRule(
    id: 'fastest_time',
    title: 'Fastest time',
    description: lorem,
  ),
  CompetitionRule(
    id: 'most_waypoints',
    title: 'Most waypoints',
    description: lorem,
  ),
  CompetitionRule(
    id: 'checkpoint_hunt',
    title: 'Checkpoint hunt',
    description: lorem,
  ),
  CompetitionRule(
    id: 'fuel_economy',
    title: 'Fuel economy challenge',
    description: lorem,
  ),
];
