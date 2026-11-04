/// Sports StatMyTeam can model. American football ships first; the rest are
/// ready for the same Team / Player / GameStats pipeline.
enum Sport {
  basketball,
  football,
  baseball,
  hockey,
  soccer;

  String get label => switch (this) {
        Sport.basketball => 'Basketball',
        Sport.football => 'Football',
        Sport.baseball => 'Baseball',
        Sport.hockey => 'Hockey',
        Sport.soccer => 'Soccer',
      };

  String get shortLabel => switch (this) {
        Sport.basketball => 'NBA',
        Sport.football => 'NFL',
        Sport.baseball => 'MLB',
        Sport.hockey => 'NHL',
        Sport.soccer => 'SOC',
      };
}
