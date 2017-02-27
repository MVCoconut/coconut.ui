package coconut.ui.macros;

#if macro
import tink.hxx.Parser;
import tink.macro.BuildCache;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
using tink.MacroApi;
using tink.CoreApi;

class Views {

  static function buildType() 
    return BuildCache.getType('coconut.ui.View', function (ctx:BuildContext):TypeDefinition {
      
      var name = ctx.name,
          type = ctx.type.toComplex();
      
      var ret = 
        switch ctx.type.reduce() {
          case TAnonymous(_.get().fields => fields) if (false):
            var key = ctx.pos.makeBlankType();

            var plain = [],
                lifted = (macro class { var key(default, never):$key; }).fields,
                transplant = [];

            var pt = TAnonymous(plain),
                lt = TAnonymous(lifted),
                obj = EObjectDecl(transplant).at();

            var model = Context.getType('coconut.data.Model');
            
            for (f in fields) {
              var t = f.type.toComplex(),
                  name = f.name,
                  opt = f.meta.has(':optional');
              
              var meta = if (opt) [{ name: ':optional', params: [], pos: f.pos }] else [];
              plain.push({
                name: name,
                pos: f.pos,
                kind: FProp('default', 'never', t),
                meta: meta,
              });

              var isModel = f.type.isSubTypeOf(model).isSuccess();

              var isObservable = !isModel && {
                var blank = f.pos.makeBlankType();
                (macro ((null : Null<$t>) : tink.state.Observable.ObservableObject<$blank>).poll().value).typeof().isSuccess();
              }

              var isFunction = !isModel && !isObservable && 
                switch f.type.reduce() {
                  case TFun(_, _): true;
                  default: false;
                }
                
              transplant.push({
                field: name,
                expr: 
                  if (opt && isObservable)
                    macro switch data.$name {
                      case null: null;
                      case v: v.value;
                    }
                  else
                    macro data.$name,
              });

              lifted.push({
                name: name,
                pos: f.pos,
                meta: meta,
                kind: FProp('default', 'never', {
                  if (isObservable || isModel || isFunction) t;
                  else macro: tink.state.Observable<$t>;
                }),
              });              
            }
            
            macro class $name extends coconut.ui.ViewBase<$lt, $pt> {
              public function new(data:$lt, render:$pt->vdom.VNode) {
                super(data, function (data) return $obj, coconut.ui.tools.Compare.shallow, render, data.key);
              }
            }; 
          default:
            Context.typeof(macro @:pos(ctx.pos) ((null : Null<$type>) : coconut.data.Model));

            macro class $name extends coconut.ui.BaseView implements coconut.ui.tools.ModelView {
              public function new(data:$type, render:$type->vdom.VNode) {
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
      
      var data =           
        switch c.target.superClass.t.get().constructor.get().type.reduce() {
          case TFun(_[1].t.reduce() => TFun(_[0].t => ret, _), _): ret;
          default: throw "super class constructor has unexpected shape";
        }

      function add(t:TypeDefinition)
        for (f in t.fields)
          c.addMember(f);

      if (!c.target.meta.has(':tink'))
        c.target.meta.add(':tink', [], haxe.macro.Context.currentPos());

      if (c.hasConstructor())
        c.getConstructor().toHaxe().pos.error('Custom constructors not allowed on views');
      
      var postConstruct = [];

      c.getConstructor((macro function (data) {
        super(data, render);
        $b{postConstruct};
        
      }).getFunction().sure()).publish();

      var states = [];

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
                    state =  '__coco_${member.name}__',
                    get_state = 'get_$state';

                states.push(state); 
                
                add(macro class {

                  @:noCompletion var $state(get, null):tink.state.State<$t>;
                    @:noCompletion function $get_state()
                      return switch this.$state {
                        case null: 
                          this.$state = new tink.state.State($e);
                        case v: v;
                      }

                  @:noCompletion inline function $get():$t {
                    return this.$state.value;
                  }

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
        case Failure(_): c.target.pos.error('View requires render method');
      }
      var impl = render.getFunction().sure();

      switch impl.args {
        case []:

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

        case [v]:
          if (v.type == null)
            v.type = data.toComplex({ direct: true });
          else 
            render.pos.getOutcome(v.type.toType(render.pos).sure().isSubTypeOf(data));
        case v: 
          render.pos.error("The render function should have one argument at most");
      }

    }]);
  }
}
#end
