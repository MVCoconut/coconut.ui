package coconut.ui.macros;

import haxe.macro.*;

class Helper {

  static public macro function parseChildren(e) {

    function check(ct)
      return Context.storeTypedExpr(Context.typeExpr(macro @:pos(e.pos) ($e:$ct)));

    return 
      try check(macro : coconut.ui.Children)
      catch (e:Dynamic) check(macro : coconut.ui.RenderResult);
  }

}