package cases;

class Implicits extends Base {

  public function test() {
    mount(hxx('<Example ref=${e -> asserts.assert(e.foo.value == 123)}/>'));
    mount(hxx('<Example2 ref=${e -> asserts.assert(e.foo.value == 42)}/>'));
    return asserts.done();
  }
}

private class Example extends View {
  @:implicit var foo:Foo = new Foo(123);
  function render() '
    <div>${foo.value}</div>
  ';
}

private class Example2 extends View {
  @:implicit var foo:Foo;
  function render() '
    <div>${foo.value}</div>
  ';
}

@:default(cases.Foo.ANSWER)
class Foo {
  static public final ANSWER = new Foo(42);
  public final value:Int;
  public function new(value:Int)
    this.value = value;
}