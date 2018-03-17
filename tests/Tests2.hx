package ;

import tink.state.*;
import vdom.VDom.*;
import coconut.ui.*;
import coconut.Ui.hxx;
import js.Browser.*;
// import Tests;
using tink.CoreApi;

class Tests2 extends haxe.unit.TestCase {

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
    
    Observable.updateAll();
    
    var beforeOuter = Nestor.redraws,
        beforeInner = Example4.redraws;

    s.set('bar');
    
    Observable.updateAll();
    
    assertEquals(beforeOuter, Nestor.redraws);
    assertEquals(beforeInner + 1, Example4.redraws);
  }  
  static function main() {
    var runner = new haxe.unit.TestRunner();
    runner.add(new Tests2());
    // var s = new State("42");

    // function render(value:String):RenderResult
    //   return value;

    // hxx('
    //   <Example5 data={s.value}>
    //     <renderer>
    //       {render(data)}
    //     </renderer>
    //   </Example5>
    // ');
    // var a = [0,1,2,3];
    // hxx('
    //   <div>
    //     <for {i in a}>{i}</for>
    //   </div>
    // ');
    travix.Logger.exit(
      if (runner.run()) 0
      else 500
    ); 
  }

}