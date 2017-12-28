package ;

import tink.state.*;
import vdom.VDom.*;
import coconut.ui.*;
import coconut.Ui.hxx;
import Tests;
using tink.CoreApi;

class Tests2 extends haxe.unit.TestCase {
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