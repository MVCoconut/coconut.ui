package cases;

class Implicits extends Base {

  public function test() {
    {
      var e:Example = null;
      mount(hxx('<Example ref=${e}/>'));
      asserts.assert(e.foo.value == 123);
    }
    {
      var e:Example2 = null;
      mount(hxx('<Example2 ref=${e}/>'));
      asserts.assert(e.foo.value == 42);
    }

    var example:Example = null,
        s1 = new State(new Foo(1337)),
        s2 = new State<Foo>(null);

    mount(hxx('
      <Implicit defaults=${[ Foo => s1.value ]}>
        <Implicit defaults=${[ Foo => s2.value ]}>
          <Example ref=${example}/>
        </Implicit>
      </Implicit>
    '));

    asserts.assert(example.foo.value == 1337);
    s2.set(new Foo(23));
    asserts.assert(example.foo.value == 23);
    s2.set(new Foo(420));
    asserts.assert(example.foo.value == 420);
    Observable.updateAll();

    var before = example.renderCount;

    s1.set(new Foo(0));
    Observable.updateAll();
    asserts.assert(example.renderCount == before);

    s1.set(s2.value);
    s2.set(null);
    Observable.updateAll();

    asserts.assert(example.renderCount == before);// the source context for Foo will have changed, but the value is the same
    s1.set(new Foo(321));
    asserts.assert(example.foo.value == 321);
    s2.set(new Foo(99));
    asserts.assert(example.foo.value == 99);


    return asserts.done();
  }
}

private class Example extends View {
  @:implicit var foo:Foo = new Foo(123);
  public var renderCount(default, null) = 0;
  function render() '
    <div data-render-count=${renderCount++}>${foo.value}</div>
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