package coconut.ui.macros;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

using haxe.macro.Tools;
using tink.MacroApi;

class ViewBuilder {
  static function build() {
    return ClassBuilder.run([function (c:ClassBuilder) {
      
      function add(t:TypeDefinition)
        for (f in t.fields)
          c.addMember(f);
      
      if (c.hasConstructor())
        c.getConstructor().toHaxe().pos.error('Custom constructors not allowed for views');

      if (!c.target.meta.has(':tink'))
        c.target.meta.add(':tink', [], c.target.pos);

      var superClass = c.target.superClass.t.get();
      var root = superClass;
      var params = c.target.superClass.params;
      
      while (root.module != 'coconut.ui.View') {
        var next = root.superClass;
        params = [for (p in next.params) p.applyTypeParameters(root.params, params)];
        root = next.t.get();
      }

      var isRoot = superClass.module == 'coconut.ui.View';
      if (isRoot && !c.hasOwnMember('render'))
        c.target.pos.error('Missing render function');

      var rawType =
        switch root.fields.get().filter(function (f) return f.name == 'render') {
          case [v]: 
            switch v.type.applyTypeParameters(root.params, params).reduce() {
              case TFun([{ t: type }], _): type;
              default: throw 'assert';
            }
          default: throw 'assert';
        }      

      function checked(type, ?f) 
        return 
          switch coconut.data.macros.Models.check(type) {
            case []: type;
            case _[0] => error: c.target.pos.error(if (f == null) error else f(error));
          }

      function getPublicFields(type:Type)
        return [for (f in type.getFields().sure()) if (f.isPublic) f.name];

      function makeRender(ct:ComplexType, getFields:Void->Array<String>) {
        switch c.memberByName('render') {
          case Success(f): 
            var impl = f.getFunction().sure();
            if (isRoot)
              f.overrides = true;
              
            if (impl.expr == null)
              f.pos.error('function body required');

            if (impl.args.length == 0) {
              
              impl.args.push('__data__'.toArg());

              var statements = [
                if (impl.expr.getString().isSuccess()) 
                  macro @:pos(impl.expr.pos) return hxx(${impl.expr});
                else
                  impl.expr
              ];

              for (name in getFields())
                statements.unshift(macro var $name = __data__.$name);

              impl.expr = statements.toBlock(impl.expr.pos);
            } 


            if (impl.args[0].type == null)
              impl.args[0].type = ct;
          default:
        }
      }

      function make(input:ComplexType, renderer, data, getFields) {
        makeRender(data, getFields);
        c.getConstructor((macro function (data:$input) {
          super(data, $renderer);
        }).getFunction().sure()).publish();        
      }

      function process(type:Type, isParam:Bool)
        switch type.reduce() {
          case TInst(_.get().kind => KTypeParameter(constraints), _) if (!isParam):
            switch constraints {
              case []: c.target.pos.error('Cannot render unconstrainted type parameter `${type.toString()}`');
              case [v]: process(v, true);
              default: c.target.pos.error('Too many constraints for `${type.toString()}`');
            }
          case TAnonymous(a):
            var data =               
              if (isParam) {
                checked(type, function (s) return 'Bad constraint for `${rawType.toString()}` because $s').toComplex();
              }
              else TAnonymous([for (f in a.get().fields) {
                name: f.name, 
                pos: f.pos, 
                kind: FProp('default', 'never', checked(f.type).toComplex()),
                meta: f.meta.get(),
              }]);

            make(
              macro : tink.state.Observable<$data>,
              macro function (data:tink.state.Observable<$data>) return render(data.value),
              data,
              getPublicFields.bind(type)
            );
            
          case v:
            v.isSubTypeOf(Context.getType('coconut.data.Model')).sure();
            var data = checked(v).toComplex();
            make(data, macro render, data, getPublicFields.bind(v));
        }

      process(rawType, false);

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
    }]);
  }
}