package ;

import tink.state.*;
using tink.CoreApi;

class Tests2 extends haxe.unit.TestCase {

  static function main() {
    var runner = new haxe.unit.TestRunner();
    runner.add(new Tests2());
    
    travix.Logger.exit(
      if (runner.run()) 0
      else 500
    ); 
  }

}