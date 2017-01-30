package coconut.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
using tink.CoreApi;
using tink.MacroApi;

private typedef FieldContext = {
  var name(default, null):String;
  var pos(default, null):Position;
  var type(default, null):ComplexType;
  var expr(default, null):Null<Expr>;
  var meta(default, null):MetadataEntry;
}

private enum Init {
  Skip;
  Value(e:Expr);
  Arg;
  OptArg(defaultsTo:Expr);
}

private typedef Result = {
  var getter(default, null):Expr;
  @:optional var setter(default, null):Expr;
  @:optional var stateful(default, null):Bool;
  var init(default, null):Init;
}

private class ModelBuilder {

  var fieldDirectives:Array<Named<FieldContext->Result>>;

  var c:ClassBuilder;

  public function new(c) {

    this.c = c;

    if (c.target.isInterface) return;

    fieldDirectives = [
      new Named(':constant'  , constantField),
      new Named(':computed'  , computedField),
      new Named(':editable'  , editableField),
      new Named(':observable', observableField),
    ];

    
    if (!c.target.meta.has(':tink'))
      c.target.meta.add(':tink', [], c.target.pos);

    //trace(c.target.name + ' -> ' + c.target.meta.has(':tink'));
    
    if (c.hasConstructor())
      c.getConstructor().toHaxe().pos.error('Custom constructors not allowed in models');

    var dataFields = [],
        argFields = [],
        dataInit = [];

    var dataType = TAnonymous(dataFields),
        argType = TAnonymous(argFields);

    var cFunc = (macro function (?initial:$argType) {
      this.__cocostate__ = new tink.state.State(${EObjectDecl(dataInit).at(c.target.pos)});
    }).getFunction().sure();
    var constr = c.getConstructor(cFunc);
    constr.publish();

    for (member in c) 
      if (!member.isStatic)
        switch member.kind {
          case FProp(_, _, _, _): 
          
            member.pos.error('Custom properties not allowed in models');

          case FVar(t, e):

            if (t == null) 
              member.pos.error('Field requires explicit type');
            
            var found = None;

            for (directive in fieldDirectives) 
              found = 
                switch [found, member.extractMeta(directive.name)] {
                  case [None, Success(m)]: Some({ apply: directive.value, meta: m });
                  case [Some({ meta: { name: previous } }), Success({ pos: pos, name: conflicting })]:
                    pos.error('Conflicting directives @:$previous and @:$conflicting');
                  case [v, _]: v;
                }

            switch found {
              case None: 
                member.pos.error('Plain fields not allowed on models');
              case Some(v):
                var name = member.name;
                var res = v.apply({
                  name: name,
                  type: t,
                  expr: switch e {
                    case null: null;
                    default: macro @:pos(e.pos) ($e : $t);
                  },
                  pos: member.pos,
                  meta: v.meta,
                });

                c.addMember(Member.getter(name, res.getter, t));

                var setter = 
                  switch res.setter {
                    case null:
                      'never';
                    case v:
                      c.addMember(Member.setter(name, v, t));
                      'set';
                  }

                member.kind = FProp('get', setter, t, null);
                member.publish();

                function addArg(?meta)
                  argFields.push({
                    name: name,
                    pos: member.pos,
                    meta: meta,
                    kind: FProp('default', 'null', t),
                  });

                function getValue() 
                  return switch res.init {
                    case Value(e): e;
                    case Arg: 
                      cFunc.args[0].opt = false;
                      addArg();
                      macro initial.$name;

                    case OptArg(e):
                      
                      addArg([{ name: ':optional', params: [], pos: member.pos }]);
                      macro switch initial.$name {
                        case null: $e;
                        case v: v;
                      }

                    case Skip: 
                      null;
                  }

                if (res.stateful) {
                  switch getValue() {
                    case null:
                    case e: 
                      dataInit.push({ field: name, expr: e });
                  }

                  dataFields.push({
                    name: name,
                    pos: member.pos,
                    kind: FVar(t)
                  });
                }
                else switch getValue(){
                  case null:
                  case v:
                    constr.init(name, member.pos, Value(v), { bypass: true });
                }
            }

            switch member.extractMeta(':transition') {
              case Success(m):
                m.pos.error('@:transition not allowed on fields');
              default:
            }

          case FFun(f):

            switch member.extractMeta(':transition') {
              case Success({ params: [] }):
                member.publish();
                f.expr = macro @:pos(f.expr.pos) coconut.macros.Models.transition(${f.expr});
              case Success({ params: v }): 
                v[0].reject("@:transition does not accept arguments");
              default:
            }

            for (d in fieldDirectives)
              switch member.extractMeta(d.name) {
                case Success({ pos: p, name: n }):
                  p.error('@:$n not allowed on functions');
                default:
              }
                
        }

    add(macro class {
      @:noCompletion var __cocostate__:tink.state.State<$dataType>;//access this thing directly and you will suffer!!!
    });
  }

  function add(td:TypeDefinition)
    for (f in td.fields)
      c.addMember(f);  

  function constantField(ctx:FieldContext):Result {
    var name = ctx.name;
    
    return {
      getter: macro @:pos(ctx.pos) this.$name,
      init: switch ctx.expr {
        case null: Arg;
        case macro @byDefault $v: OptArg(v);
        case v: Value(v);
      },
    }
  }

  function computedField(ctx:FieldContext):Result
    return {
      getter: ctx.expr,
      init: Skip,
    }

  function editableField(ctx:FieldContext):Result {
    var name = ctx.name,
        ret = observableField(ctx);
    
    return {
      getter: ret.getter,
      stateful: true,
      init: ret.init,
      setter: Models.buildTransition(macro this.$name = param),
    }
  }

  function observableField(ctx:FieldContext):Result {
    var name = ctx.name;
    return {
      getter: macro @:pos(ctx.pos) this.__cocostate__.value.$name,
      stateful: true,
      init: switch ctx.expr {
        case null: Arg;
        case macro @byDefault $v: OptArg(v);
        case v: Value(v);
      },
    }
  }
}
#end 

class Models {
  #if macro 
  static public function build() 
    return ClassBuilder.run([function (c) new ModelBuilder(c)]);

  static public function isAssignment(op:Binop)
    return switch op {
      case OpAssign | OpAssignOp(_): true;
      default: false; 
    }

  static public function buildTransition(e:Expr) {
    
    function process(e:Expr)
      return switch e.map(process) {
        case { expr: EBinop(op, macro this.$name, b)} if (isAssignment(op)):

          EBinop(op, macro @:pos(e.pos) __nextstate__.$name, b).at(e.pos);

        case { expr: EBinop(op, macro $i{name}, b)} if (isAssignment(op)):

          (function () {
            return 
              if (Context.getLocalVars().exists(name)) e;
              else EBinop(op, macro @:pos(e.pos) __nextstate__.$name, b).at(e.pos);
          }).bounce(e.pos);

        case v:
          v;
      }

    return (macro @:pos(e.pos) {
      var __nextstate__ = this.__cocostate__.value;
      ${process(e)};
      this.__cocostate__.set(__nextstate__);
    });
  }
  #end
  macro static public function transition(e) 
    return buildTransition(e);
}