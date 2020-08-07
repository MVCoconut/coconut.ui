package coconut.ui.internal;

import haxe.macro.Context.*;
using haxe.macro.Tools;
using tink.MacroApi;
using tink.CoreApi;

@:pure
abstract Children({}) {

  static function ofOther(e) {

    function childType(t)
      return switch follow(t) {
        case TAbstract(_.get() => { pack: ['coconut', 'ui', 'internal'], name: 'Children' }, [t]):
          Some(t);
        default:
          None;
      }

    var expected = getExpectedType(),
        found = typeExpr(e).t;

    return
      switch childType(expected) {
        case Some(child):
          if (unify(found, child)) {
            var ct = child.toComplex();
            macro @:pos(e.pos) [($e : $ct)];
          }
          else switch childType(found) {
            case Some(t):
              macro @:pos(e.pos) cast $e;
            default:
              e.pos.error('${follow(found).toString()} should be ${expected.toString()}');
          }
        case v:
          e.pos.error('Something went quite horribly wrong. Please isolate and report issue to https://github.com/MVCoconut/coconut.ui/');
      }
  }
}
