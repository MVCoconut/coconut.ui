package coconut.ui.internal;

import haxe.macro.Expr;
using tink.MacroApi;

class ImplicitContext {

 static function with(e:Expr) {
    switch e {
      case macro ($v): e = v;
      default:
    }
    var exprs = switch e.expr { case EArrayDecl(a): a; default: [e]; };
    var entries = [for (e in exprs) switch e {
      case macro $k => $v:
        macro @:pos(e.pos) new coconut.ui.internal.ImplicitContext.SingleImplicit($k, function () return $v);
      default: e.reject('expected key => value, but got ${e.toString()}');
    }];
    return macro new coconut.ui.internal.ImplicitContext.ImplicitValues([$a{entries}]);
  }
}