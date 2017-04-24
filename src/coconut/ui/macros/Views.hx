package coconut.ui.macros;

#if macro
import tink.hxx.Parser;
import tink.macro.BuildCache;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
using StringTools;
using tink.MacroApi;
using tink.CoreApi;

class Views {

  static function buildType() 
    return BuildCache.getType('coconut.ui.View', function (ctx:BuildContext):TypeDefinition {
      
      var name = ctx.name,
          type = ctx.type.toComplex();
      
      var ret = 
        switch ctx.type.reduce() {
          case TAnonymous(_.get().fields => fields):

            var plain = [];

            var pt = TAnonymous(plain);
            
            for (f in fields) {
              var t = f.type.toComplex(),
                  name = f.name,
                  opt = f.meta.has(':optional');
              
              switch coconut.data.macros.Models.check(f.type) {
                case []:
                case v: ctx.pos.error(v[0]+ ' for field $name');
              }              

              var meta = if (opt) [{ name: ':optional', params: [], pos: f.pos }] else [];
              plain.push({
                name: name,
                pos: f.pos,
                kind: FProp('default', 'never', t),
                meta: meta,
              });           
            }
            
            macro class $name extends coconut.ui.BaseView implements coconut.ui.tools.PropView<$pt> {
              public function new(data:tink.state.Observable<$pt>, render) {
                super(data, function (data:tink.state.Observable<$pt>) return render(data.value));
              }
            }; 

          default:
            Context.typeof(macro @:pos(ctx.pos) ((null : Null<$type>) : coconut.data.Model));
            switch coconut.data.macros.Models.check(ctx.type) {
              case []:
              case v: ctx.pos.error(v[0]);
            }
            macro class $name extends coconut.ui.BaseView implements coconut.ui.tools.ModelView {
              public function new(data:$type, render) {
                super(data, render);
              }
            }; 
        }
          
      switch ctx.type {
        case TInst(_, params), TEnum(_, params), TAbstract(_, params), TType(_, params) if (params.length > 0):
          ret.params = [];
          for (p in params)
            switch p {
              case TInst(_.get() => { name: name, kind: KTypeParameter(constraints) }, []):
                ret.params.push({
                  name: name,
                  constraints: [for (c in constraints) c.toComplex()],
                });
              default:
            }
        default:
      }
      ret.meta = [{ name: ':autoBuild', params: [macro coconut.ui.macros.Views.buildClass()], pos: ctx.pos }];
      
      return ret;
    });

  static function buildClass():Array<Field> {
    return ClassBuilder.run([function (c:ClassBuilder) {

      if (!c.target.meta.has(':tink'))
        c.target.meta.add(':tink', [], haxe.macro.Context.currentPos());

      var superClass = c.target.superClass.t.get();
      var hasSuperClass = false;
      var data =   
        switch superClass.fields.get().filter(function (f) return f.name == 'render') {
          case [render]:
            hasSuperClass = true;
            switch render.type {
              case TFun([_.t => t], _): t;
              default: throw 'assert';
            }
          case []:
            switch c.target.superClass.t.get().constructor.get().type.reduce() {
              case TFun(_[1].t.reduce() => TFun(_[0].t => ret, _), _): ret;
              default: throw "super class constructor has unexpected shape";
            }
          default: 
            throw 'unreachable';
        }

      function add(t:TypeDefinition)
        for (f in t.fields)
          c.addMember(f);

      
      if (!hasSuperClass) {
        if (c.hasConstructor())
          c.getConstructor().toHaxe().pos.error('Custom constructors not allowed on views');

        c.getConstructor((macro function (data) {
          super(data, render);
        }).getFunction().sure()).publish();
      }

      for (member in c)
        switch member.extractMeta(':state') {
          case Success(m):

            switch member.getVar(true).sure() {
              case { type: null }: member.pos.error('Field requires type');
              case { expr: null }: member.pos.error('Field requires initial value');
              case { expr: e, type: t }:
                
                member.kind = FProp('get', 'set', t);

                var get = 'get_' + member.name,
                    set = 'set_' + member.name,
                    state =  '__coco_${member.name}__';
                
                add(macro class {

                  @:noCompletion var $state(default, never):tink.state.State<$t> = new tink.state.State($e);

                  @:noCompletion inline function $get():$t 
                    return this.$state.value;

                  @:noCompletion inline function $set(param:$t) {
                    this.$state.set(param);
                    return param;
                  }

                });
            }
            
          default:
        }  

      var render = switch c.memberByName('render') {
        case Success(f): f;
        case Failure(_): 
          if (hasSuperClass) return;
          c.target.pos.error('View requires render method');
      }
      var impl = render.getFunction().sure();

      switch impl.args {
        case []:

          impl.args.push({
            name: '__data__',
            type: data.toComplex(),
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

        case [v]:
          if (v.type == null)
            v.type = data.toComplex();
          else 
            render.pos.getOutcome(v.type.toType(render.pos).sure().isSubTypeOf(data));
        case v: 
          render.pos.error("The render function should have one argument at most");
      }

    }]);
  }
}
#end
