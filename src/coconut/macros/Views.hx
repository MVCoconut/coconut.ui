package coconut.macros;

#if macro
import tink.macro.BuildCache;
import haxe.macro.Expr;

class Views {
  
  static function buildType() 
    return BuildCache.getTypeN('coconut.ui.View', function (ctx:BuildContextN):TypeDefinition {
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
            expr: macro super(tink.state.Observable.auto(function () {
              
            }))
          }
        }),
      });
      return ret;
    });

  static function buildClass():Array<Field>
    return null;
}
#end