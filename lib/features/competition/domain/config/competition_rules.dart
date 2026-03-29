class CompetitionRule {
  final String id;      // например: 'fastest_time'
  final String title;   // 'Fastest time'
  final String description;
  final bool enabled;

  const CompetitionRule({
    required this.id,
    required this.title,
    required this.description,
    this.enabled = false,
  });
}

const lorem =
    'Lorem ipsum, or lipsum as it is sometimes known, is dummy text used in laying out print, '
    'graphic or web designs. In publishing and graphic design, Lorem ipsum is a placeholder text.';

const competitionRules = <CompetitionRule>[
  CompetitionRule(
    id: 'fastest_time',
    title: 'Fastest time',
    description: 'Complete the route as quickly as possible. The rider with the shortest total time wins.',
    enabled: true,
  ),
  CompetitionRule(
    id: 'most_waypoints',
    title: 'Most waypoints',
    description: 'Collect as many route waypoints as possible during the ride. Every passed point adds to your score.',
  ),
  CompetitionRule(
    id: 'checkpoint_hunt',
    title: 'Checkpoint hunt',
    description: 'Find and reach hidden checkpoints placed along the map. Some checkpoints may give bonus points.',
  ),
  CompetitionRule(
    id: 'fuel_economy',
    title: 'Fuel economy challenge',
    description: 'Finish the route using the least amount of fuel. Smooth riding and smart speed control matter.',
  ),
];
