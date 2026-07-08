/// Mirrors the `Tag` union type from the web app's src/types/index.ts.
enum Tag {
  informatique('Informatique'),
  mathematiques('Mathématiques'),
  gestionDeProjet('Gestion de projet'),
  iaMl('IA / ML'),
  droit('Droit'),
  langues('Langues'),
  sciences('Sciences'),
  marketing('Marketing'),
  stageAlternance('Stage / Alternance'),
  autre('Autre');

  const Tag(this.label);

  final String label;

  static Tag fromLabel(String label) =>
      Tag.values.firstWhere((t) => t.label == label, orElse: () => Tag.autre);
}
