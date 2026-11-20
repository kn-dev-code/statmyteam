/// Sports StatMyTeam can model. American football ships first; the rest are
/// ready for the same Team / Player / GameStats pipeline. Display names are
/// localized in the UI (`sportName`, `sportMenuName`).
enum Sport {
  basketball,
  football,
  baseball,
  hockey,
  soccer;

  /// Goal-scoring sports report "goals" rather than "points" per game.
  bool get scoresGoals => this == Sport.soccer || this == Sport.hockey;
}
