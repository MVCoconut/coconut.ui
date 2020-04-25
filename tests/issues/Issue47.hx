package issues;

class Issue47 extends View {
  @:attr var foo:String->Void;
  static function main() {}
  function render() '<div/>';
  static function getDerivedStateFromAttributes(attrs) return {}
}