package ;

import tink.state.*;
import js.Browser.*;
import vdom.VDom.*;
import coconut.ui.*;
import coconut.data.*;
import coconut.Ui.hxx;
using tink.CoreApi;
import coconut.ui.tools.Compare;

class Tests2 extends haxe.unit.TestCase {

  
  static function main() {
    var runner = new haxe.unit.TestRunner();
    // runner.add(new Tests());
    // hxx('
    //   <Container>
    //     <div>Test</div>
    //     <div>Test</div>
    //     <div>Test</div>
    //   </Container>
    // ');
    travix.Logger.exit(
      if (runner.run()) 0
      else 500
    ); 
  }

}

class Container extends View<{ ?className:String, children: RenderResult }> {

  function render() '
    <div class={className}>{children}</div>
  ';
}