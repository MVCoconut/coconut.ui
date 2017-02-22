package ;

class Example extends coconut.ui.View<{ foo: tink.state.Observable<Int>, bar:Int, ?opt:Float }> {
  static public var redraws = 0;
  @:state public var baz:Int = 0;
  function render() '
    <div>
      {redraws++}
      <span class="foo">{foo.value}</span>
      <span class="bar">{bar}</span>
      <span class="baz">{baz}</span>
    </div>
  ';
}