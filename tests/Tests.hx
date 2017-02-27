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

  // function testModel() {
  //   var model = new Foo({ foo: 4 });

  //   mount(hxx('<Example2 {...model} />'));
    
  //   assertEquals('4', q('.foo').innerHTML);
  //   assertEquals('4', q('.bar').innerHTML);

  //   model.foo = 5;
  //   Observable.updateAll();
  //   assertEquals('5', q('.foo').innerHTML);
  //   assertEquals('5', q('.bar').innerHTML);
  // }  

  function testModelViewReuse() {
    var models = [for (i in 0...10) new Foo({ foo: i })];
    var list = new FooList({ items: models });

    var before = Example2.created;
    mount(hxx('<FooListView {...list} />'));
    assertEquals(before + 10, Example2.created);

    var before = Example2.created;
    list.items = models;
    Observable.updateAll();
    assertEquals(before, Example2.created);

    list.items = models.concat(models);
    Observable.updateAll();
    assertEquals(before + 10, Example2.created);
    // var a = Example2.new;
    // var b = Example2.new;
    // console.log(a);
    // assertEquals(a, b);
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