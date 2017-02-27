package ;

import tink.state.*;
import js.Browser.*;
import vdom.VDom.*;
import coconut.data.*;
import coconut.ui.macros.HXX.hxx;
using tink.CoreApi;
// import Test;

class Tests extends haxe.unit.TestCase {

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

    var e = hxx('<Example2 {...model} />');
    mount(e);
    
    assertEquals('4', q('.foo').innerHTML);
    assertEquals('4', q('.bar').innerHTML);
    assertEquals('0', q('.baz').innerHTML);

    model.foo = 5;
    Observable.updateAll();
    assertEquals('5', q('.foo').innerHTML);
    assertEquals('5', q('.bar').innerHTML);

    e.baz = 42;
    Observable.updateAll();
    assertEquals('42', q('.baz').innerHTML);
  }  

  function testModelViewReuse() {

    var models = [for (i in 0...10) new Foo({ foo: i })];
    var list = new FooList({ items: models });
    
    var redraws = Example2.redraws;

    var before = Example2.created.length;
    mount(hxx('<FooListView {...list} />'));
    assertEquals(before + 10, Example2.created.length);

    var before = Example2.created.length;
    list.items = models;
    Observable.updateAll();
    assertEquals(before, Example2.created.length);

    list.items = models.concat(models);
    Observable.updateAll();
    assertEquals(before + 10, Example2.created.length);
    assertEquals(redraws + 20, Example2.redraws);

    
  }

  static function main() {
    var runner = new haxe.unit.TestRunner();
    runner.add(new Tests());
    travix.Logger.exit(
      if (runner.run()) 0
      else 500
    ); 
  }

}

class FooList implements Model {
  @:editable var items:List<Foo>;
}

class FooListView extends coconut.ui.View<FooList> {
  function render() '
    <div class="foo-list">
      <for {i in items}>
        <Example2 {...i} />
      </for>
    </div>
  ';
}