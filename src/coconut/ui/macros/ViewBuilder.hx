package coconut.ui.macros;

#if macro
import coconut.data.macros.*;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import tink.priority.Queue;

using haxe.macro.Tools;
using tink.MacroApi;
using tink.CoreApi;

class ViewBuilder {
  static public var afterBuild(default, null):Queue<Callback<{ target: ClassBuilder, attributes:Array<Member>, states:Array<Member> }>> = new Queue();

  static function doBuild(c:ClassBuilder) {
      
    var defaultPos = (macro null).pos,//perhaps just use currentPos()
        classId = Models.classId(c.target);

    function add(t:TypeDefinition) {
      for (f in t.fields)
        c.addMember(f);
      return t.fields;
    }

    if (!c.target.meta.has(':tink'))
      c.target.meta.add(':tink', [], defaultPos);

    switch c.target.superClass.t.get() {
      case { pack: ['coconut', 'ui'], name: 'View' }:
      default: c.target.pos.error('Subclassing views is currently not supported');
    }

    var beforeRender = [],
        tracked = [];

    function scrape(name:String, ?aliases:Array<String>, ?skipCheck:Bool) {
      switch c.memberByName('${name}s') {
        case Success(group):
          var m = group.getVar(true).sure();

          switch m.type {
            case TAnonymous(fields):
              if (m.expr != null) 
                m.expr.reject('initialization not allowed here');
                
              for (f in fields) 
                c.addMember(f).addMeta(':$name');
            default:
              
              var defaults = 
                switch m.expr {
                  case null: new Map();
                  case { expr: EObjectDecl(fields) }: [for (f in fields) f.field => f.expr];
                  case v: v.reject('object literal expected');
                }
              for (f in m.type.toType().sure().getFields().sure()) 
                c.addMember({
                  pos: f.pos,
                  name: f.name,
                  kind: FVar(f.type.toComplex(), defaults[f.name]),
                  meta: f.meta.get(),
                }).addMeta(':$name').addMeta(':skipCheck');
          }
          c.removeMember(group);
        default:
      }

      var tags = [for (a in [name].concat(switch aliases { case null: []; case v: v; })) ':$a' => true];
      var ret = [];

      for (m in c)
        switch [for (m in m.meta) if (tags[m.name]) m] {
          case []:
          case [t]:
            var comparator = macro @:pos(t.pos) null;
            for (p in t.params) {
              switch p {
                case macro comparator = $f: 
                  comparator = f;
                default: p.reject();
              }
            }
            if (m.kind.match(FProp(_, _, _, _)))
              m.pos.error('$name cannot be property');

            if (!skipCheck && !m.extractMeta(':skipCheck').isSuccess())
              switch m.kind {
                case FVar(t, _): 
                  Models.checkLater(m.name, classId);
                default:
              }
            ret.push({
              member: m,
              comparator: comparator,
            });
          case a:
            a[1].pos.error('cannot have ${a[1].name} and ${a[0].name}');
        }

      if (!skipCheck)
        for (f in ret)
          switch f.member.extractMeta(':tracked') {
            case Success({ params: params }):

              var name = f.member.name;
              
              if (params.length == 0)
                tracked.push(macro this.$name);
              else
                for (p in params)
                  tracked.push(p.substitute({ _ : macro @:pos(p.pos) this.$name }));

            default:
          }

      return ret;
    }

    var defaultValues = [],
        defaults = MacroApi.tempName('defaults'),
        defaultFields = [];

    c.addMember({
      name: defaults,
      meta: [{ name: ':noCompletion', params: [], pos: defaultPos }],
      kind: {
        var ct = TAnonymous(defaultFields);
        FProp('default', 'never', ct, macro {(${EObjectDecl(defaultValues).at(defaultPos)}:$ct);});
      },
      pos: defaultPos,
    });

    var slots = [],
        initSlots = [],
        slotFields = [];

    c.addMember({
      name: '__slots',
      meta: [{ name: ':noCompletion', params: [], pos: defaultPos }],
      kind: FProp('default', 'never', TAnonymous(slotFields), EObjectDecl(slots).at(defaultPos)),
      access: [],
      pos: defaultPos,
    });

    var attributes:Array<Member> = [];

    for (attr in scrape('attribute', ['attr', 'children', 'child'])) {

      var a = attr.member,
          comparator = attr.comparator;

      function add(type:ComplexType, expr:Expr) {
        var optional = a.extractMeta(':optional').isSuccess() || expr != null,
            name = a.name;

        if (optional && expr == null)
          expr = macro @:pos(a.pos) null;

        var data = macro @:pos(a.pos) attributes.$name;

        if (optional) {
          defaultFields.push({
            name: a.name,
            pos: expr.pos,
            kind: FProp('default', 'never', macro : coconut.data.Value<$type>)
          });
          defaultValues.push({ field: a.name, expr: expr });//TODO: consider making this readonly
          data = macro @:pos(data.pos) $data.or($i{defaults}.$name);
        }

        initSlots.push(macro @:pos(a.pos) this.__slots.$name.setData($data));

        slots.push({ field: a.name, expr: macro new coconut.ui.tools.Slot<$type>(this, ${attr.comparator}) });
        slotFields.push({
          name: a.name,
          pos: a.pos,
          kind: FVar(macro : coconut.ui.tools.Slot<$type>)
        });

        switch a.pos.getOutcome(type.toType()).reduce() {
          case TDynamic(null):
            a.pos.error('Attribute `${a.name}` must not be Dynamic');
          case TAbstract(_.get() => { pack: [], name: 'Any' }, _):
            a.pos.error('Attribute `${a.name}` must not be Any');
          default:
        }

        attributes.push({
          name: a.name,
          pos: a.pos,
          kind: FVar(macro : coconut.data.Value<$type>),
          meta: 
            a.metaNamed(':children')
              .concat(a.metaNamed(':child'))
              .concat(if (optional) [{ name: ':optional', params: [], pos: expr.pos }] else []),
        });
        
        var isNullable = 
          if (optional) switch expr {
            case macro null: true;
            default: false;
          }
          else switch type {
            case macro : Null<$_>: true;
            default: false;
          }
        a.isPublic = true;
        a.kind = 
          switch a.pos.getOutcome(type.toType()).reduce() {
            case TFun(args, ret) if (!isNullable):
              var args =
                switch a.kind {
                  case FFun(f):
                    f.args;
                  default:
                    [for (i in 0...args.length) {
                      name: 'a$i',
                      type: null,
                      opt: args[i].opt
                    }];
                }

              FFun({
                args: args,
                ret: ret.toComplex(),
                expr: {
                  var callArgs = [for (a in args) macro $i{a.name}];
                  var body = 
                    if (optional) 
                      macro @:pos(a.pos) return this.__slots.$name.value($a{callArgs});
                    else 
                      macro @:pos(a.pos) return switch this.__slots.$name.value {
                        case null: throw 'mandatory attribute ' + $v{name} + ' of <' + $v{c.target.name} + '/> was set to null';
                        case __fn: __fn($a{callArgs});
                      }
                  body;
                },
              });
              
            default:
              var getter = 'get_$name';

              c.addMembers(macro class {
                inline function $getter():$type
                  return return this.__slots.$name.value;
              });
              FProp('get', 'never', type, null);
          }
        
      }

      switch a.kind {
        case FVar(null, _):
          a.pos.error('type required');//TODO: infer if possible
        case FVar(t, e):
          add(t, e);
        case FFun(f):
          add(
            TFunction(
              [for (a in f.args) if (a.opt) TOptional(a.type) else a.type], //TODO: apparently how optional arguments are dealt with doesn't work properly
              switch f.ret {
                case null: macro : Void;
                case v: v;
              }
            ),//TODO: rewrite this to be Callback when suitable
            if (f.expr == null) null
            else f.asExpr(a.pos)
          );
        default: a.pos.error('attributes cannot be properties'); 
      }
    }

    var rendererPos = null;
    var renderer = switch c.memberByName('render') {
      case Success(m): 
        rendererPos = m.pos;
        m.getFunction().sure();
      default:
        c.target.pos.error('missing field render');
    }

    if (renderer.args.length > 0)
      rendererPos.error('argument should not be specified');

    switch renderer.ret {
      case null: renderer.ret = macro : coconut.ui.RenderResult;
      case ct: (macro @:pos(rendererPos) ((null:$ct):coconut.ui.RenderResult)).typeof().sure();
    }

    for (ref in scrape('ref', true)) {
      var f = ref.member;
      var type = f.getVar(true).sure().type;

      f.kind = FProp('default', 'never', type);

      var setter = '_coco_set_${f.name}',
          refHolder = f.name;

      var set = (function () {
        var e = Context.storeTypedExpr(Context.typeExpr(macro this.$refHolder));
        return macro $e = param;
      }).bounce(f.pos);

      f.addMeta(':refSetter', [macro $i{setter}]);
      c.addMembers(macro class {
        @:noCompletion function $setter(param:$type) $set;
      });
    }

    renderer.expr = beforeRender.concat([switch renderer.expr {
      case e = { expr: EConst(CString(s)), pos: p }: macro @:pos(p) return hxx($e);
      case e: e;
    }]).toBlock(renderer.expr.pos);

    var states = [];

    for (state in scrape('state')) {
      var s = state.member;
      states.push(s);
      var v = s.getVar(true).sure();

      if (v.expr == null)
        s.pos.error('@:state requires initial value');
      
      var t = v.type;
      var internal = '__coco_${s.name}',
          get = 'get_${s.name}',
          set = 'set_${s.name}';

      c.addMembers(macro class {
        @:noCompletion private var $internal:tink.state.State<$t> = @:pos(v.expr.pos) new tink.state.State<$t>(${v.expr}, ${state.comparator});
        inline function $get():$t return $i{internal}.value;
        inline function $set(param:$t) {
          $i{internal}.set(param);
          return param;
        }
      });
      
      s.kind = FProp('get', 'set', t, null);
    }

    {
      if (c.hasConstructor())
        c.getConstructor().toHaxe().pos.error('custom constructor not allowed');

      var notFound:Array<Member> = [];

      function processHook(name:String, ?ret:Lazy<ComplexType>, with:Member->Function->Void)
        return
          switch c.memberByName(name) {
            case Success(m): 
              var f = m.getFunction().sure();
              c.removeMember(m);
              m.overrides = false;
              if (m.meta.getValues(':noCompletion').length == 0)
                m.addMeta(':noCompletion');
              
              if (ret != null)
                switch f.ret {
                  case null: 
                    f.ret = ret;
                  case t: 
                    (macro @:pos(m.pos) ((null:$t):$ret)).typeof().sure();
                }

              with(m, f);

              f.asExpr(m.name, m.pos);
            default: 
              notFound.push({
                name: name,
                pos: defaultPos,
                kind: FProp('default', 'never', macro : Dynamic),
                meta: [{ name: ':optional', params: [], pos: defaultPos }]
              });
              macro null;
          }        

      var shouldUpdate = processHook('shouldViewUpdate', macro : Bool, function (m, f) {
        if (f.args.length > 0)
          m.pos.error('${m.name} cannot take arguments');
      });

      var beforeRender = [];
      
      var snapshot = null;

      var getSnapshotBeforeUpdate = processHook('getSnapshotBeforeUpdate', null, function (m, f) {
        if (f.args.length > 0)
          m.pos.error('${m.name} cannot take arguments');
        
        snapshot = switch f.ret {
          case null: m.pos.makeBlankType();
          case v: v;
        }

        beforeRender.push(macro @:pos(m.pos) snapshot = getSnapshotBeforeUpdate());
      });

      var viewDidUpdate = processHook('viewDidUpdate', macro : Void, function (m, f) {
        if (snapshot != null) 
          switch f.args {
            case []: f.args.push({ name: 'snapshot', type: snapshot });
            case [arg]: if (arg.type == null) arg.type = snapshot;
            default: m.pos.error('${m.name} should have one argument');
          }
        else if (f.args.length > 0)
          m.pos.error('${m.name} cannot take arguments');
      });

      if (snapshot != null && !viewDidUpdate.expr.match(EConst(CIdent('null'))))
        viewDidUpdate = macro @:pos(viewDidUpdate.pos) {
          if (false)
            (viewDidUpdate:$snapshot->Void);
          function () viewDidUpdate(snapshot);
        }

      var viewDidMount = processHook('viewDidMount', macro : Void, function (m, f) {
        if (f.args.length > 0)
          m.pos.error('${m.name} cannot take arguments');
      });

      var viewWillUnmount = processHook('viewWillUnmount', macro : Void, function (m, f) {
        if (f.args.length > 0)
          m.pos.error('${m.name} cannot take arguments');
      });

      var getDerivedStateFromAttributes = 
        processHook(
          'getDerivedStateFromAttributes', 
          function () return TAnonymous([
            for (s in states) {
              
              var t = s.getVar().sure().type;

              {
                name: s.name,
                pos: s.pos,
                kind: FProp('default', 'never', macro : $t),
                meta: [{ name: ':optional', params: [], pos: s.pos}],
              }

            }
          ]), 
          function (m, f) {

            if (!m.isStatic)
              m.pos.error('${m.name} should be static');

            var argType = TAnonymous([
              for (m in attributes.concat(states)) {
                name: m.name,
                pos: m.pos,
                kind: FProp('get', 'never', m.getVar().sure().type)
              }
            ]);

            switch f.args {
              case []: f.args.push({ name: 'previous', type: argType });
              case [arg]: 
                if (arg.type != null) 
                  m.pos.error('Argument ${arg.name} should not have its type specified');
                else 
                  arg.type = argType;
              default: m.pos.error('${m.name} must have one argument');
            }

            var applyChanges = [for (s in states) {
              var name = s.name;
              macro @:pos(s.pos) if (changed.$name) this.$name = nu.$name;
            }];

            tracked.unshift(
              macro @:pos(m.pos) tink.state.Observable.untracked(function () {
                var nu = getDerivedStateFromAttributes(cast this),
                    changed = tink.Anon.existentFields(nu);

                $b{applyChanges}
              })
            );

          });

      var notFound = TAnonymous(notFound);

      for (m in c)
        if (m.name.charAt(3) != '_' && m.kind.match(FFun(_)) && m.metaNamed(':noCompletion').length == 0)
          switch notFound.getFieldSuggestions(m.name) {
            case '':
            case v: m.pos.warning('Potential typo$v');
          }

      var attributes = TAnonymous(attributes),
          init = '__initAttributes',
          track = 
            if (tracked.length > 0) 
              macro function track() $b{tracked};
            else macro null;

      c.getConstructor((macro @:pos(c.target.pos) function (__coco_data_:$attributes) {
        this.$init(__coco_data_);
        
        var snapshot:$snapshot = null;

        super(
          render, 
          $shouldUpdate, 
          $track,
          ${
            if (snapshot == null) macro null
            else macro function () snapshot = getSnapshotBeforeUpdate()
          },
          $viewDidMount,
          $viewDidUpdate
        );
        
        switch ($viewWillUnmount) {
          case null:
          case v: beforeUnmounting(v);
        }

      }).getFunction().sure()).isPublic = true;

      var self = Context.getLocalType().toComplexType();
      var params = switch self {
        case TPath(t): t.params;
        default: throw 'assert';
      }
      c.addMembers(macro class {
        #if debug
        @:keep function toString() {
          return $v{c.target.name}+'#'+this.viewId;
        }
        #end
        
        @:noCompletion function $init(attributes:$attributes)
          $b{initSlots};
        
      });
    }    

    for (f in c)
      switch [f.kind, f.extractMeta(':computed')] {
        case [FVar(t, e), Success(m)]:
          
          if (m.params.length > 0)
            m.params[0].reject('@:computed does not support parameters');
          
          if (e == null)
            m.pos.error('@:computed field requires expression');

          if (t == null)
            m.pos.error('@:computed field requires type');

          var internal = '__coco_${f.name}',
              get = 'get_${f.name}';

          c.addMembers(macro class {
            @:noCompletion private var $internal:tink.state.Observable<$t> = 
              @:pos(e.pos) tink.state.Observable.auto(function ():$t return $e);
            inline function $get() return $i{internal}.value;
          });

          f.kind = FProp('get', 'never', t);
        default:
      }

    for (cb in afterBuild)
      cb.invoke({
        target: c,
        attributes: attributes,
        states: states,
      });
  }

  static function build() {
    return ClassBuilder.run([doBuild]);
  }
}
#end
