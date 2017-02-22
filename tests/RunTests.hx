package ;

import tink.state.*;
import vdom.VDom.*;
import js.Browser.*;

class RunTests extends haxe.unit.TestCase {

  override function setup() {
    document.body.innerHTML = '';
  }

  static inline function q(s:String)
    return document.querySelector(s);

  static inline function mount(o) {
    document.body.appendChild(o.toElement());
  }

  function testCustom() {
    var s = new State(4);

    mount(new Example({ foo: s, bar: s }));
    
    assertEquals(q('.foo').innerHTML, '4');
    assertEquals(q('.bar').innerHTML, '4');

    s.set(5);

    assertEquals(q('.foo').innerHTML, '5');
    assertEquals(q('.bar').innerHTML, '5');
  }

  function testModel() {
    var model = new Foo({ foo: 4 });

    mount(new Example(model.observables));
    
    assertEquals(q('.foo').innerHTML, '4');
    assertEquals(q('.bar').innerHTML, '4');

    model.foo = 5;

    assertEquals(q('.foo').innerHTML, '5');
    assertEquals(q('.bar').innerHTML, '5');
  }

  function testLifeCycle() {
     var s = new State(4);
     var e = new Example({ foo: s, bar: s, key: 1234 });
     e.baz = 42;
     mount(new coconut.ui.Renderable(
      Observable.auto(function () return hxx('
        <div>
          <if {s.value == 4}>{e}
          <else>
            <Example foo={123} bar={321} key={1234} />
          </if>
        </div>
      '))
     ));
     assertEquals(q('.foo').innerHTML, '4');
     assertEquals(q('.bar').innerHTML, '4');
     assertEquals(q('.baz').innerHTML, '42');
     s.set(5);
     assertEquals(q('.foo').innerHTML, '123');
     assertEquals(q('.bar').innerHTML, '321');
  }

  static function main() {
    var runner = new haxe.unit.TestRunner();
    runner.add(new RunTests());
    travix.Logger.exit(
      if (runner.run()) 0
      else 500
    ); 
  }
  
}

class Foo implements coconut.data.Model {
  @:constant var key:Dynamic = this;
  @:editable var foo:Int;
  @:computed var bar:Int = foo;
}

class Example extends coconut.ui.View<{ foo: Observable<Int>, bar:Int }> {
  @:state public var baz:Int = 0;
  function render() '
    <div>
      <span class="foo">{foo.value}</span>
      <span class="bar">{bar}</span>
      <span class="baz">{baz}</span>
    </div>
  ';
}