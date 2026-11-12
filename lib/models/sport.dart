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

  /// Longer name used on the sport picker.
  String get menuLabel => switch (this) {
        Sport.football => 'American Football',
        Sport.soccer => 'Soccer',
        _ => label,
      };

  String get shortLabel => switch (this) {
        Sport.basketball => 'NBA',
        Sport.football => 'NFL',
        Sport.baseball => 'MLB',
        Sport.hockey => 'NHL',
        Sport.soccer => 'MLS',
      };

  /// Scoring-rate label on team rows, e.g. PPG vs GPG.
  String get scoringLabel => switch (this) {
        Sport.soccer => 'GPG',
        Sport.hockey => 'GPG',
        _ => 'PPG',
      };
}
