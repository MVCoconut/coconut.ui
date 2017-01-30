package coconut.macros;

#if macro
import tink.macro.BuildCache;
import haxe.macro.Expr;
using tink.MacroApi;

class Views {
  
  static function buildType() 
    return BuildCache.getType('coconut.ui.View', function (ctx:BuildContext):TypeDefinition {
      var name = ctx.name;
      var ret = macro class $name extends coconut.ui.Renderable {}; 
      ret.meta = [{ name: ':autoBuild', params: [macro coconut.macros.Views.buildClass()], pos: ctx.pos }];
      ret.fields.push({
        name: 'new',
        pos: ret.pos,
        access: [APublic],
        kind: FFun({
          var args = [];
          {
            args: [],
            ret: macro : Void,
            expr: macro super(tink.state.Observable.auto(function ():vdom.VNode {
              return '';
            }))
          }
        }),
      });
      return ret;
    });

  static function buildClass():Array<Field> {
    return ClassBuilder.run([function (c) {
      if (!c.target.meta.has(':tink'))
        c.target.meta.add(':tink', [], haxe.macro.Context.currentPos());

      var render = c.memberByName('render').sure();
      var impl = render.getFunction().sure();
      switch impl.args {
        case []:
          throw "not implemented";
        case [v]:
        case v: 
          render.pos.error("The render function should have one argument at most");
      }
    }]);
  }
}
#end