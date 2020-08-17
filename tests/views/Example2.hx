package views;

class Example2 extends View {
  @:attribute var model:Foo;
  static public var redraws = 0;
  static public var created(default, null):Array<Example2> = [];

  function viewDidMount()
    Example2.created.push(this);

  @:state public var baz:Int = 0;
  function render() '
    <div>
      {redraws++}
      <span class="foo">{model.foo}</span>
      <span class="bar">{model.bar}</span>
      <span class="baz">{baz}</span>
    </div>
  ';
}