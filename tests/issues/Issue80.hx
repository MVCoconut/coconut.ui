package issues;

class Issue80 extends cases.Base {
  public function test() {
    asserts.assert(WithConstructor.constructed == 0);
    var w:WithConstructor = null;
    mount(
      hxx('
        <WithConstructor ref=$w value=${123} />
      ')
    );
    asserts.assert(w.firstValue == 123);
    asserts.assert(WithConstructor.constructed == 1);
    return asserts.done();
  }
}

private class WithConstructor extends View {
  static public var constructed(default, null):Int = 0;
  @:attribute var value:Int;
  public var firstValue:Int;
  function new() {
    constructed++;
    firstValue = 123;
  }
  function render() '<div />';
}
