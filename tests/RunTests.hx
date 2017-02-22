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
    
    assertEquals('4', q('.foo').innerHTML);
    assertEquals('4', q('.bar').innerHTML);

    s.set(5);
    Observable.updateAll();

    assertEquals('5', q('.foo').innerHTML);
    assertEquals('5', q('.bar').innerHTML);
  }

  function testModel() {
    var model = new Foo({ foo: 4 });

    mount(hxx('<Example key={model} {...model.observables} />'));
    
    assertEquals('4', q('.foo').innerHTML);
    assertEquals('4', q('.bar').innerHTML);

    model.foo = 5;
    Observable.updateAll();
    assertEquals('5', q('.foo').innerHTML);
    assertEquals('5', q('.bar').innerHTML);
  }

  function testLifeCycle() {
     var s = new State(4);
     var e = new Example({ foo: s, bar: s, key: 1234 });
     e.baz = 42;
     var r = new coconut.vdom.Renderable(
      Observable.auto(function () return hxx('
        <div>
          <if {s.value == 4}>{e}
          <else>
            <Example foo={123} bar={321} key={1234} />
          </if>
        </div>
      '))
     );
     mount(r);
     assertEquals('4', q('.foo').innerHTML);
     assertEquals('4', q('.bar').innerHTML);
     assertEquals('42', q('.baz').innerHTML);
     s.set(5);
     Observable.updateAll();
     trace(Example.redraws);
     assertEquals('123', q('.foo').innerHTML);
     assertEquals('321', q('.bar').innerHTML);
     assertEquals('42', q('.baz').innerHTML);
     s.set(6);
     Observable.updateAll();
     trace(Example.redraws);
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
  @:editable var foo:Int;
  @:computed var bar:Int = foo;
}