package ;

import tink.state.*;
import js.Browser.*;
import vdom.VDom.*;
import coconut.ui.*;
import coconut.data.*;
import coconut.Ui.hxx;
using tink.CoreApi;
import coconut.ui.tools.Compare;

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

  function testNested() {
    var s = new State('foo');
    var foobar = new FooBar();
    mount(hxx('<Nestor plain="yohoho" inner={s.value} {...foobar} />'));
    var beforeOuter = Nestor.redraws,
        beforeInner = Example4.redraws;
    
    s.set('bar');
    Observable.updateAll();
    assertEquals(beforeOuter, Nestor.redraws);
    assertEquals(beforeInner + 1, Example4.redraws);
  }

  function testSlot() {
    var s = new coconut.ui.tools.Slot(),
        s1 = new State(0),
        s2 = new State(1000);
    var log = [];
    s.observe().bind(log.push);
    s.setData(42);
    assertEquals('', log.join(','));
    Observable.updateAll();
    assertEquals('42', log.join(','));
    s.setData(0);
    Observable.updateAll();
    assertEquals('42,0', log.join(','));
    s.setData(s1);
    Observable.updateAll();
    assertEquals('42,0', log.join(','));
    s1.set(1000);
    Observable.updateAll();
    assertEquals('42,0,1000', log.join(','));
    s.setData(s2);
    Observable.updateAll();
    assertEquals('42,0,1000', log.join(','));    

    s1.set(1001);
    s2.set(1002);
    Observable.updateAll();
    assertEquals('42,0,1000,1002', log.join(','));    
  }  

  function testCustom() {
    var s = new State(4);

    mount(hxx('<Example key={s} foo={s} bar={s} />'));
    mount(hxx('<Example foo={s} bar={s} />'));
    
    assertEquals('4', q('.foo').innerHTML);
    assertEquals('4', q('.bar').innerHTML);

    s.set(5);
    Observable.updateAll();

    assertEquals('5', q('.foo').innerHTML);
    assertEquals('5', q('.bar').innerHTML);
  }
  
  // function testOnlyCache() {
  //   var s = new State('42');
  //   var cache = new coconut.ui.tools.ViewCache();
  //   function make()
  //     return Example4.forKey(this, Observable.auto(function () return {
  //       value: Std.string(Math.random())
  //     }));

  //   assertFalse(make() == make());
  //   assertTrue(cache.cached(make) == cache.cached(make));
  // }

  function testCache() {
    
    var s = new State('42');

    function render(value:String)
      return hxx('<Example4 key={"42"} value={value} />');

    mount(hxx('
      <Example5 data={s.value}>
        <renderer>
          {render(data)}
        </renderer>
      </Example5>
    '));
    var id = q('.example4').getAttribute('data-id');
    assertTrue(id != null);
    assertEquals('42', q('.example4').innerHTML);
    s.set('321');
    Observable.updateAll();
    assertEquals('321', q('.example4').innerHTML);
    assertEquals(id, q('.example4').getAttribute('data-id'));
    
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
  
  function testModelInCustom() {
    
    var variants = [
      function (model:Foo) return hxx('<Example {...model} />'), 
      function (model:Foo) return hxx('<Example {...model} bar={model.bar} />')
    ];
    for (render in variants) {
      var model = new Foo({ foo: 4 });
      mount(render(model));
      
      assertEquals('4', q('.foo').innerHTML);
      assertEquals('4', q('.bar').innerHTML);

      model.foo = 5;
      Observable.updateAll();
      assertEquals('5', q('.foo').innerHTML);
      assertEquals('5', q('.bar').innerHTML);
      
      setup();
    }
  }  
  

  function testTodo() {
    new TodoListView(null);
    new TodoItemView({ description: 'foo', completed: true, onedit: function (_) {}, ontoggle: function (_) {}});

    var desc = new State('test'),
        done = new State(false);

    mount(hxx('<TodoItemView completed={done} description={desc} onedit={desc.set} ontoggle={done.set} />'));
    var toggle:js.html.InputElement = cast q('input[type="checkbox"]');
    var edit:js.html.InputElement = cast q('input[type="text"]');
    assertFalse(toggle.checked);
    toggle.click();
    assertTrue(done);
    assertEquals('test', edit.value);
    desc.set('foo');
    assertEquals('test', edit.value);
    Observable.updateAll();
    assertEquals('foo', edit.value);
    edit.value = "bar";
    edit.dispatchEvent(new js.html.Event("change"));//gotta love this
    assertEquals('bar', desc);
  }
  
  function testPropViewReuse() {
    var states = [for (i in 0...10) new State(i)];
    var models = [for (s in states) { foo: s.observe() , bar: s.value }];
    var list = new ListModel({ items: models });
    
    var redraws = Example.redraws;

    var before = Example.created.length;
    mount(hxx('<ExampleListView {...list} />'));
    assertEquals(before + 10, Example.created.length);

    var before = Example.created.length;
    list.items = models;
    Observable.updateAll();
    assertEquals(before, Example.created.length);

    list.items = models.concat(models);
    Observable.updateAll();
    assertEquals(before + 10, Example.created.length);
    assertEquals(redraws + 20, Example.redraws);    

    states[0].set(100);
    Observable.updateAll();
    
    assertEquals(redraws + 22, Example.redraws);    

    list.items = models;
    Observable.updateAll();    

    assertEquals(redraws + 22, Example.redraws);    
  }
  
  function testModelViewReuse() {

    var models = [for (i in 0...10) new Foo({ foo: i })];
    var list = new ListModel({ items: models });
    
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

class FooListView extends coconut.ui.View<ListModel<Foo>> {
  function render() '
    <div class="foo-list">
      <for {i in items}>
        <Example2 {...i} />
      </for>
    </div>
  ';
}

typedef WindowConfig = { 
  var className(default, never):String;
  var title(default, never):RenderResult;
  var content(default, never):RenderResult;
  var parts(default, never):Iterable<Int>;
}

class Container extends View<{ ?className:String, children: RenderResult }> {
  function render() '
    <div class={className}>{children}</div>
  ';
}

class Window<C:WindowConfig> extends View<C> {
  @:signal var closed;
  function render() '
    <div class={className}>
      <for {p in parts}>
      </for>
    </div>
  ';
}

class Lift extends View<{ foo: Iterable<String> }> {
  override function render(data) '
    <div>{[for (v in data.foo) v].join("-")}</div>
  ';
}

class Sub extends Window<WindowConfig> {
  function foo()
    _closed.trigger(Noise);
}

class SubSub extends Sub {
  override function render() '
    <div class={"test"}></div>
  ';
}

// class CtorSub extends Sub { //TODO: this should be made to compile
//   public function new() {
//     @hxx '
//       <super class="super" title="yo" content="yeah" parts={[0,1,2]} />
//     ';
//   }
// }

class FooBar {
  public function new() {}
  public function foo() {}
  public function bar() {}
}

class Nestor extends View<{ plain:String, inner: Observable<String>, foo:Void->Void, bar:Void->Void }> {
  
  static public var redraws(default, null):Int = 0;

  function render() {
    redraws++;
    return @hxx '
      <Div class="nestor">
        <span class="plain">{plain}</span>
        <Example4 key={this} value={inner} />
      </Div>
    ';
  }

  static function Div(attr, ?children)
    return div(attr, children);

}