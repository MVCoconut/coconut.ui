package coconut.macros;

#if macro
import tink.macro.BuildCache;
import haxe.macro.Expr;
using tink.MacroApi;

class Views {
  
  static function buildType() 
    return BuildCache.getType('coconut.ui.View', function (ctx:BuildContext):TypeDefinition {

      var name = ctx.name,
          type = ctx.type.toComplex();

      var ret = macro class $name extends coconut.ui.Renderable {
        public function new(data:$type, render:$type->vdom.VNode)
          super(tink.state.Observable.auto(function ():vdom.VNode {
            return render(data);
          }), data);
      }; 

      ret.meta = [{ name: ':autoBuild', params: [macro coconut.macros.Views.buildClass()], pos: ctx.pos }];
      
      return ret;
    });

  static function buildClass():Array<Field> {
    return ClassBuilder.run([function (c:ClassBuilder) {
      
      if (!c.target.meta.has(':tink'))
        c.target.meta.add(':tink', [], haxe.macro.Context.currentPos());

      if (c.hasConstructor())
        c.getConstructor().toHaxe().pos.error('Custom constructors not allowed on views');

      c.getConstructor((macro function (data) {
        super(data, render);
      }).getFunction().sure()).publish();

      var render = c.memberByName('render').sure();
      var impl = render.getFunction().sure();

      switch impl.args {
        case []:

          switch c.target.superClass.t.get().constructor.get().type.reduce() {
            case TFun(_[0].t => data, _):

              impl.args.push({
                name: '__data__',
                type: data.toComplex({ direct: true }),
              });
              
              var statements = [
                if (impl.expr.getString().isSuccess()) 
                  macro @:pos(impl.expr.pos) return hxx(${impl.expr});
                else
                  impl.expr
              ];

              for (v in data.getFields().sure()) if (v.isPublic) {
                var name = v.name;
                statements.unshift(macro var $name = __data__.$name);
              }

              impl.expr = statements.toBlock(impl.expr.pos);

            default: throw 'assert';
          }

        case [v]:
        case v: 
          render.pos.error("The render function should have one argument at most");
      }
    }]);
  }
}
#end