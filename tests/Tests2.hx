package ;

import tink.state.*;
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
    var wrapper = document.createElement('wrapper-element');
    document.body.appendChild(wrapper);
    coconut.ui.Renderer.mount(wrapper, o);
  }

  static function main() {
    var runner = new haxe.unit.TestRunner();
    runner.add(new Tests2());

    travix.Logger.exit(
      if (runner.run()) 0
      else 500
    ); 
  }

}