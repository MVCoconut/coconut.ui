package ;

class Example extends coconut.ui.View {

  @:attribute var foo:tink.state.Observable<Int>;
  @:attribute var bar:Int;
  @:attribute var opt:Float = .5;
  @:attribute @:skipCheck var arr:Array<Int> = [];
  
  static public var redraws = 0;
  static public var created(default, null):Array<Example> = [];
  
  var count:Int = Example.created.push(this);
  
  @:state public var baz:Int = 0;
  function render() {
    return @hxx '
      <div>
        {redraws++}
        <span class="foo">{foo.value}</span>
        <span class="bar">{bar}</span>
        <span class="baz">{baz}</span>
      </div>
    ';
  }
}