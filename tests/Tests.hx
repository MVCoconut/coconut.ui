package ;

import tink.state.*;
import js.Browser.*;
//import vdom.VDom.*;
import coconut.ui.*;
import coconut.data.*;
import coconut.data.Value;
import coconut.Ui.hxx;
using tink.CoreApi;

class Tests extends haxe.unit.TestCase {

  override function setup() {
    document.body.innerHTML = '';
  }

  static inline function q(s:String)
    return document.querySelector(s);

  static inline function mount(o) {
    var wrapper = document.createElement('wrapper-element');
    document.body.appendChild(wrapper);
    coconut.ui.Renderer.mount(wrapper, o);
  }

  // function testNested() {
  //   var s = new State('foo');
  //   var foobar = new FooBar();
  //   mount(hxx('<Nestor plain="yohoho" inner={s.value} {...foobar} />'));
    
  //   Renderer.updateAll();
    
  //   var beforeOuter = Nestor.redraws,
  //       beforeInner = Example4.redraws;

  //   s.set('bar');
    
  //   Renderer.updateAll();
    
  //   assertEquals(beforeOuter, Nestor.redraws);
  //   assertEquals(beforeInner + 1, Example4.redraws);
  // }

  function testSlot() {
    var s = new coconut.ui.tools.Slot(this),
        s1 = new State(0),
        s2 = new State(1000);
    var log = [];
    s.observe().bind(log.push);
    s.setData(Observable.const(42));
    assertEquals('', log.join(','));
    Renderer.updateAll();
    assertEquals('42', log.join(','));
    s.setData(Observable.const(0));
    Renderer.updateAll();
    assertEquals('42,0', log.join(','));
    s.setData(s1);
    Renderer.updateAll();
    assertEquals('42,0', log.join(','));
    s1.set(1000);
    Renderer.updateAll();
    assertEquals('42,0,1000', log.join(','));
    s.setData(s2);
    Renderer.updateAll();
    assertEquals('42,0,1000', log.join(','));    

    s1.set(1001);
    s2.set(1002);
    Renderer.updateAll();
    assertEquals('42,0,1000,1002', log.join(','));    
  }  

  function testCustom() {
    var s = new State(4);

    mount(hxx('<Example key={s} foo={s} bar={s} />'));
    mount(hxx('<Example foo={s} bar={s} />'));
    
    assertEquals('4', q('.foo').innerHTML);
    assertEquals('4', q('.bar').innerHTML);

    s.set(5);
    Renderer.updateAll();

    assertEquals('5', q('.foo').innerHTML);
    assertEquals('5', q('.bar').innerHTML);
  }
  
  // function _testOnlyCache() {
  //   var s = new State('42');
  //   var cache = new coconut.ui.tools.ViewCache();
  //   function make()
  //     return Example4.forKey(this, Observable.auto(function () return {
  //       value: Std.string(Math.random())
  //     }));

  //   assertFalse(make() == make());
  //   assertTrue(cache.cached(make) == cache.cached(make));
  // }

  function testSlotCache() {
    var s = new State(42);
    mount(hxx('
      <Example6>
        <div data-id={s.value}>
          <Example6>
            <if {s.value > 12}>
              <Example4 value={Std.string(s.value)} />
            </if>
          </Example6>
        </div>
      </Example6>
    '));     
    var elt = q('.example4');
    var id = elt.getAttribute('data-id');
    assertTrue(id != null);
    s.set(17);
    Renderer.updateAll();
    assertEquals(elt, q('.example4'));
    assertEquals(id, elt.getAttribute('data-id'));
    assertEquals('17', elt.innerHTML);
  }

  function testCache() {
    
    var s = new State('42');

    function render(value:String):RenderResult
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
    Renderer.updateAll();
    assertEquals('321', q('.example4').innerHTML);
    assertEquals(id, q('.example4').getAttribute('data-id'));
    
  }
  
  function testModel() {
    var model = new Foo({ foo: 4 });

    var e = null;
    mount(hxx('<Example2 ref={function (inst) e = inst} model={model} />'));
    
    assertEquals('4', q('.foo').innerHTML);
    assertEquals('4', q('.bar').innerHTML);
    assertEquals('0', q('.baz').innerHTML);

    model.foo = 5;
    Renderer.updateAll();
    assertEquals('5', q('.foo').innerHTML);
    assertEquals('5', q('.bar').innerHTML);

    e.baz = 42;
    Renderer.updateAll();
    assertEquals('42', q('.baz').innerHTML);
  }  
  
  function testModelInCustom() {
    
    var variants = [
      function (model:Foo) return hxx('<Example foo={model.foo} {...model} />'), 
      function (model:Foo) return hxx('<Example foo={model.foo} {...model} bar={model.bar} />')
    ];
    for (render in variants) {
      var model = new Foo({ foo: 4 });
      mount(render(model));
      
      assertEquals('4', q('.foo').innerHTML);
      assertEquals('4', q('.bar').innerHTML);

      model.foo = 5;
      Renderer.updateAll();
      assertEquals('5', q('.foo').innerHTML);
      assertEquals('5', q('.bar').innerHTML);
      
      setup();
    }
  }  
  

  function testTodo() {

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
    Renderer.updateAll();
    assertEquals('foo', edit.value);
    #if !react
    edit.value = "bar";
    edit.dispatchEvent(new js.html.Event("change"));//gotta love this
    assertEquals('bar', desc);
    #end
  }
  
  function testPropViewReuse() {
    var states = [for (i in 0...10) new State(i)];
    var models = [for (s in states) { foo: s.observe() , bar: s.value }];
    var list = new ListModel({ items: models });
    
    var redraws = Example.redraws;

    var before = Example.created.length;
    mount(hxx('<ExampleListView list={list} />'));
    assertEquals(before + 10, Example.created.length);

    var before = Example.created.length;
    list.items = models;
    Renderer.updateAll();
    assertEquals(before, Example.created.length);

    list.items = models.concat(models);
    Renderer.updateAll();
    assertEquals(before + 10, Example.created.length);
    assertEquals(redraws + 20, Example.redraws);    

    states[0].set(100);
    Renderer.updateAll();
    
    assertEquals(redraws + 22, Example.redraws);    

    list.items = models;
    Renderer.updateAll();    

    assertEquals(redraws + 22, Example.redraws);    
  }
  
  function testRootSwitch() {
    mount(hxx('<MyView />'));
    assertEquals('One', q('div').innerHTML);
  }

  function testModelViewReuse() {

    var models = [for (i in 0...10) new Foo({ foo: i })];
    var list = new ListModel({ items: models });
    
    var redraws = Example2.redraws;

    var before = Example2.created.length;
    mount(hxx('<FooListView list={list} />'));
    assertEquals(before + 10, Example2.created.length);

    var before = Example2.created.length;
    list.items = models;
    Renderer.updateAll();
    assertEquals(before, Example2.created.length);

    list.items = models.concat(models);
    Renderer.updateAll();
    assertEquals(before + 10, Example2.created.length);
    assertEquals(redraws + 20, Example2.redraws);
    
  }
  
  static function main() {
    
    travix.Logger.println('yo');

    var runner = new haxe.unit.TestRunner();
    runner.add(new Tests());
    
    travix.Logger.exit(
      if (runner.run()) 0
      else 500
    ); 
  }

}

class FooListView extends coconut.ui.View {
  @:attr var list:ListModel<Foo>;
  function render() '
    <div class="foo-list" style="background: blue">
      <for {i in list.items}>
        <Example2 model={i} />
      </for>
    </div>
  ';
}

class MyView extends View {
  function render() '
    <switch ${int()}>
      <case ${0}>
        <div>Zero</div>
      <case ${1}>
        <div>One</div>
      <case ${_}>
        <div>Default</div>
    </switch>
  ';
  
  function int() return 1;
}

class Issue19 extends View {
  @:optional @:attribute var foo:String;
  function render() '<div />';
  static function check() '<Issue19/>';
}