package issues;

class Issue19 extends View {
  @:optional @:attribute var foo:String;
  function render() '<div />';
  static function check() '<Issue19/>';
}