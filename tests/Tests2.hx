package ;

import tink.state.*;
import vdom.VDom.*;
import coconut.ui.*;
import coconut.Ui.hxx;
using tink.CoreApi;

class Tests2 extends haxe.unit.TestCase {
  static function main() {
    var runner = new haxe.unit.TestRunner();
    runner.add(new Tests2());
    var s = new State("42");
    hxx('<Nestor2 inner={s.value} />');
    
    travix.Logger.exit(
      if (runner.run()) 0
      else 500
    ); 
  }

}


class Nestor2 extends View {
  var attributes:{ inner: Observable<String> };
  function render() return null;
}