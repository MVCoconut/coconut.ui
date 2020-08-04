package issues;

class Issue68 extends View {
  @:attr var f:(value:String, ?event:Int)->Void;
  function render() return null;
  static function fail() {
    var f:(value:String, ?event:Int)->Void = null;
    hxx('<Issue68 f=${f}/>');
  }
}