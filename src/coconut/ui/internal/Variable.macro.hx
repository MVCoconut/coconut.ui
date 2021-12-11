package coconut.ui.internal;

import haxe.macro.Context.*;
import haxe.macro.Expr;

using haxe.macro.Tools;
using tink.MacroApi;

abstract Variable<T>(Dynamic) {
  static function shouldCheck(e:Expr)
    return switch e {
      case { expr: ECheckType(e, _)} | macro ($e): shouldCheck(e);
      case macro @:skipCheck $_: false;
      default: true;
    }

  static public function make(e:Expr)
    return (switch typeExpr(e) {
      case done = followWithAbstracts(_.t) => TInst(_.get() => { module: 'tink.state.State', name: 'StateObject' }, _):
        storeTypedExpr(done);
      case te:
        while (true)
          switch e {
            case macro (${v}): e = v;
            default: break;
          }
        switch e {
          case macro $i{name}:
            e = macro @:pos(e.pos) this.$name;
          default:
        }
        switch e {
          case macro ${owner}.$name:

            var v = typeExpr(owner);
            if (v.hasThis())
              v = typeExpr(macro @:pos(owner.pos) (function () return $owner)());

            var ret = storeTypedExpr(v);

            if (shouldCheck(e)) {
              var ownerT = v.t,
                  pos = e.pos;

              coconut.data.macros.Models.afterChecking(function () {
                switch coconut.data.macros.Models.check(ownerT) {
                  case []:
                  case v:
                    pos.error('Target not observable: ${v[0]}');
                }
              });
            }

            typeof(macro @:pos(e.pos) $ret.$name = cast null);

            macro @:pos(e.pos) {
              var target = tink.state.Observable.auto(function () return $ret);
              @:pos(e.pos) tink.state.State.compound(
                tink.state.Observable.auto(function () return target.value.$name), // consider using .map here
                function (value) target.value.$name = value
              );
            }

        default:
          e.reject('expression should be a field or of type State (found ${te.t.toString()})');
      }
    });
}