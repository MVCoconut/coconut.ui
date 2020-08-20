package coconut.ui.macros;

#if macro
import coconut.data.macros.*;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

using haxe.macro.Tools;
using tink.MacroApi;
using tink.CoreApi;

typedef ViewInfo = {
  target: ClassBuilder,
  attributes:Array<Member>,
  states:Array<Member>,
  refs:Array<{
    field:Member,
    setter:Member,
  }>,
  lifeCycle: Array<Member>,
}

class ViewBuilder {

  final config:Config;
  final c:ClassBuilder;
  final fieldInits:Array<Named<Expr>> = [];
  final beforeRender = [];
  final display = Context.defined('display');

  function initField(name, expr)
    this.fieldInits.push(new Named(name, expr));

  static function getComparator(t:MetadataEntry) {
    var comparator = macro @:pos(t.pos) null;

    for (p in t.params)
      switch p {
        case macro comparator = $f:
          comparator = f;
        default: p.reject();
      }

    return { comparator: comparator };
  }

  function new(c, config) {
    this.c = c;
    this.config = config;
  }

  static function noArgs(t:MetadataEntry)
    switch t.params {
      case []:
      case v: v[0].reject('no arguments allowed here');
    }

  function guessType(e:Expr, p:Position) {
    var ret =
      switch e {
        case null:
          if (display) null;
          else p.error('Type or initial value required');
        case { expr: EConst(c) }:
          switch c {
            case CIdent('true' | 'false'): macro : Bool;
            case CInt(_): macro : Int;
            case CFloat(_): macro : Float;
            case CRegexp(_): macro : EReg;
            case CString(_): macro : String;
            default: null;
          }
        default:
          null;
      }

    if (ret == null && !display)
      e.reject('Cannot infer type, please annotate it explicitly.');
    return ret;
  }

  function doBuild() {
    var defaultPos = (macro null).pos,//perhaps just use currentPos()
        classId = Models.classId(c.target);

    function add(t:TypeDefinition) {
      for (f in t.fields)
        c.addMember(f);
      return t.fields;
    }

    c.target.meta.add(':observable', [], defaultPos);

    if (!c.target.superClass.t.get().meta.has(':coconut.viewbase')) {
      c.target.pos.error('Subclassing views is currently not supported');
    }

    var tracked = [];

    function scrape<Meta>(name:String, process:MetadataEntry->Meta, ?aliases:Array<String>, ?skipCheck:Bool) {
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
            if (m.kind.match(FProp(_, _, _, _)))
              m.pos.error('$name cannot be property');

            if (!skipCheck && !m.extractMeta(':skipCheck').isSuccess())
              switch m.kind {
                case FVar(t, _):
                  Models.checkLater(m.name, classId);
                default:
              }
            ret.push({
              pos: t.pos,
              member: m,
              meta: process(t),
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

    var initSlots = [],
        attributes:Array<Member> = [];

    function slotName(name)
      return '__coco_$name';

    function addAttribute(a, expr:Expr, type:ComplexType, publicType:ComplexType, optional:Bool, comparator, ?meta) {
      var name = a.name;
      var data = macro @:pos(a.pos) attributes.$name,
          slotName = slotName(a.name);

      if (!display) {
        initSlots.push(macro @:pos(a.pos) this.$slotName.setData($data));

        if (expr == null)
          expr = macro @:pos(a.pos) null;

        add(macro class {
          @:noCompletion private final $slotName:coconut.ui.internal.Slot<$type, $publicType>;
        });
        initField(slotName, macro new coconut.ui.internal.Slot<$type, $publicType>(this, ${comparator}, $expr));
      }

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
        kind: FVar(publicType),
        meta:
          (if (optional) [{ name: ':optional', params: [], pos: (macro null).pos }] else [])
            .concat(switch meta {
              case null: [];
              case v: v;
            })
      });

    }

    for (attr in scrape('attribute', getComparator, ['attr', 'children', 'child'])) {

      var a = attr.member,
          comparator = attr.meta.comparator;

      function add(type:ComplexType, expr:Expr) {
        var optional = a.extractMeta(':optional').isSuccess() || expr != null,
            name = a.name;

        var slotName = slotName(name);

        if (optional && expr == null)
          expr = macro @:pos(a.pos) null;

        addAttribute(a, expr, type, macro : coconut.data.Value<$type>, optional,
          attr.meta.comparator,
          a.metaNamed(':children')
            .concat(a.metaNamed(':child'))
        );

        var isNullable =
          if (optional) switch expr {
            case macro null: true;
            default: false;
          }
          else switch type {
            case macro : Null<$_>: true;
            default: false;
          }

        a.publish();

        if (display) return;
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
                      type: args[i].t.toComplex(),
                      opt: args[i].opt
                    }];
                }

              FFun({
                args: args,
                ret: ret.toComplex(),
                expr: {
                  var callArgs = [for (a in args) macro $i{a.name}];
                  var body =
                    if (#if debug optional #else true #end)
                      macro @:pos(a.pos) return this.$slotName.value($a{callArgs});
                    else
                      macro @:pos(a.pos) return switch this.$slotName.value {
                        case null: throw 'mandatory attribute ' + $v{name} + ' of <' + $v{c.target.name} + '/> was set to null';
                        case __fn: __fn($a{callArgs});
                      }
                  body;
                },
              });

            default:
              var getter = 'get_$name';

              c.addMembers(macro class {
                @:noCompletion inline function $getter():$type
                  return this.$slotName.value;
              });
              FProp('get', 'never', type, null);
          }

      }

      switch a.kind {
        case FVar(t, e):
          if (t == null)
            t = guessType(e, a.pos);
          add(t, switch [e, t] {
            case [null, macro : Bool]: macro false;
            default: e;
          });
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

    for (c in scrape('controlled', noArgs))
      switch c.member.kind {
        case FVar(t, e):
          if (t == null)
            t = guessType(e, c.pos);
          var optional = switch e {
            case null:
              if (c.member.metaNamed(':optional').length > 0) {
                e = macro @:pos(e.pos) new tink.state.State<$t>(cast null);
                true;
              }
              else false;
            default:
              e = macro @:pos(e.pos) new tink.state.State<$t>($e);
              true;
          }

          addAttribute(c.member, e, t, macro : coconut.data.Variable<$t>, optional, macro @:pos(c.pos) null);

          c.member.kind = FProp('get', 'set', t);

          var name = c.member.name;

          var getter = 'get_$name',
              setter = 'set_$name',
              slotName = slotName(name);

          add(macro class {
            inline function $getter():$t
              return this.$slotName.value;
            function $setter(param:$t):$t {
              switch @:privateAccess this.$slotName.data {//TODO: this is quite hideous
                case null: //should probably never happen
                case v: v.set(param);
              }
              return param;
            }
          });
        case _.match(FFun(_)) => isFunc:
          c.pos.error('controlled attributes cannot be ${if (isFunc) 'functions' else 'properties'}');
      }

    switch scrape('implicit', noArgs) {
      case []:
      case found:

        var implicits =
          switch config.implicits {
            case null: found[0].pos.error('The current backend does not support implicit attributes');
            case v:
              for (f in v.fields)
                c.addMember(f);
              v.name;
          }

        for (i in found)
          switch i.member {
            case m = { kind: FVar(t, e), name: name }:
              if (t == null)
                e.pos.error('type required');

              addAttribute(m, {
                var fallback = switch e {
                  case null:
                    switch m.pos.getOutcome(t.toType()).reduce() {
                      case TEnum(_.get().meta => m, _)
                        | TInst(_.get().meta => m, _):
                        switch m.extract(':default') {
                          case []: i.pos.error(t.toString() + ' has no @:default and $name has no default value');
                          case [{ params: [e] }]: e;
                          default: i.pos.error(t.toString() + ' must have exactly one @:default with exactly one argument');
                        }
                      default:
                        i.pos.error('Only enum values and instances can be implicit');
                    }
                  default: e;
                }

                macro {
                  var fallback = tink.core.Lazy.ofFunc(() -> $fallback);
                  tink.state.Observable.auto(() -> switch $i{implicits}.get($p{t.toString().split('.')}) {
                    case null: fallback.get();
                    case v: v;
                  });
                }
              }, t, macro : coconut.data.Value<$t>, true, macro null);
              m.publish();
              m.kind = FProp('get', 'never', t);

              var getter = 'get_$name',
                  slotName = slotName(name);

              c.addMembers(macro class {
                @:noCompletion inline function $getter():$t
                  return this.$slotName.value;
              });
            default:
              i.pos.error('@:implicit only allowed on plain fields');
          }

    }

    var rendererPos = null;
    var renderer = switch c.memberByName('render') {
      case Success(m):
        rendererPos = m.pos;
        m.addMeta(':noCompletion', (macro null).pos);
        m.getFunction().sure();
      default:
        if (display) {
          rendererPos = (macro null).pos;
          {
            args: [],
            ret: config.renders,
            expr: macro return null,
          }
        }
        else
          c.target.pos.error('missing field render');
    }

    if (renderer.args.length > 0)
      rendererPos.error('argument should not be specified');

    {
      var renders = config.renders;
      switch renderer.ret {
        case null: renderer.ret = macro : $renders;
        case ct: (macro @:pos(rendererPos) ((null:$ct):$renders)).typeof().sure();
      }
    }

    var refs = [];

    for (ref in scrape('ref', noArgs, true)) {
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

      refs.push({
        field: f,
        setter: c.addMembers(macro class {
          @:noCompletion function $setter(param:$type) $set;
        })[0],
      });


    }

    var states = [];

    for (state in scrape('state', getComparator)) {
      if (display) continue;// this is a bit extreme, but should work
      var s = state.member;
      states.push(s);
      var v = s.getVar(true).sure();

      if (v.expr == null)
        if (display) v.expr = macro null;
        else s.pos.error('@:state requires initial value');

      var t = switch v.type {
        case null: guessType(v.expr, s.pos);
        case v: v;
      }

      var internal = '__coco_${s.name}',
          get = 'get_${s.name}',
          set = 'set_${s.name}';

      c.addMembers(macro class {
        @:noCompletion private final $internal:tink.state.State<$t>;
        inline function $get():$t return $i{internal}.value;
        inline function $set(param:$t) {
          $i{internal}.set(param);
          return param;
        }
      });

      initField(internal, macro new tink.state.State<$t>(${v.expr}, ${state.meta.comparator}));

      s.kind = FProp('get', 'set', t, null);
    }

    var lifeCycle = [];

    {
      if (c.hasConstructor())
        c.getConstructor().toHaxe().pos.error('custom constructor not allowed');

      var notFound:Array<Member> = [];

      function processHook(name:String, ?ret:Lazy<ComplexType>, with:Member->Function->Void)
        return
          switch c.memberByName(name) {
            case Success(m):
              var f = m.getFunction().sure();
              lifeCycle.push(m);
              m.overrides = false;
              if (m.metaNamed(':noCompletion').length == 0)
                m.addMeta(':noCompletion');

              if (ret != null)
                switch f.ret {
                  case null:
                    f.ret = ret;
                  case t:
                    (macro @:pos(m.pos) ((null:$t):$ret)).typeof().sure();
                }

              with(m, f);

              macro @:pos(m.pos) $i{m.name};
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

      var afterRender = [];

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

      processHook('viewDidRender', macro : Void, function (m, f) {

        switch f.args {
          case []: f.args.push({ name: 'firstTime', type: macro : Bool });
          case [arg]: if (arg.type == null) arg.type = macro : Bool;
          default: m.pos.error('${m.name} should have one argument');
        }

        afterRender.push(macro @:pos(m.pos) viewDidRender(firstTime));
      });

      processHook('viewDidUpdate', macro : Void, function (m, f) {

        if (snapshot != null)
          switch f.args {
            case []: f.args.push({ name: 'snapshot', type: snapshot });
            case [arg]: if (arg.type == null) arg.type = snapshot;
            default: m.pos.error('${m.name} should have one argument');
          }
        else if (f.args.length > 0)
          m.pos.error('${m.name} cannot take arguments');

        var args = [for (a in f.args) macro @:pos(m.pos) $i{a.name}];

        afterRender.push(macro @:pos(m.pos) if (!firstTime) viewDidUpdate($a{args}));
      });

      processHook('viewDidMount', macro : Void, function (m, f) {
        if (f.args.length > 0)
          m.pos.error('${m.name} cannot take arguments');

        afterRender.push(macro @:pos(m.pos) if (firstTime) viewDidMount());
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

            var argFields = [];
            var argType = TAnonymous(argFields);

            for (m in attributes.concat(states))
              argFields.push({
                name: m.name,
                pos: m.pos,
                kind: switch c.memberByName(m.name).sure().kind {
                  case FFun(f): FFun({
                    expr: null,
                    ret: f.ret,
                    args: f.args,
                    params: f.params
                  });
                  case FProp(_, _, t) | FVar(t): FVar(t);
                }
              });

            var arg = EObjectDecl([for (f in argFields) { field: f.name, expr: macro @:pos(m.pos) $p{['this', f.name]} }]).at(m.pos);

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
                var nu = getDerivedStateFromAttributes($arg),
                    changed = tink.Anon.existentFields(nu);

                $b{applyChanges}
                return null;
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
          ${switch afterRender {
            case []: macro null;
            default: macro function (firstTime:Bool) $b{afterRender};
          }}
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
            @:noCompletion private final $internal:tink.state.Observable<$t>;
            inline function $get() return $i{internal}.value;
          });

          initField(internal, macro @:pos(e.pos) tink.state.Observable.auto(function ():$t return $e));

          if (f.metaNamed(':skipCheck').length == 0)
            Models.checkLater(f.name, classId);

          f.kind = FProp('get', 'never', t);
        default:
      }

    var ctor = c.getConstructor();
    for (f in fieldInits)
      ctor.init(f.name, f.value.pos, Value(hxxExprSugar(f.value)));

    for (f in c)
      f.kind = switch f.kind {
        case FFun(f):
          FFun(
            switch tink.hxx.Sugar.markupOnlyFunctions(f) {
              case _ == f => true:
                {
                  args: f.args,
                  ret: f.ret,
                  params: f.params,
                  expr: hxxExprSugar(f.expr),
                }
              case v: v;
            }
          );
        case FVar(t, e):
          FVar(t, hxxExprSugar(e));
        case FProp(get, set, t, e):
          FProp(get, set, t, hxxExprSugar(e));
      }

    renderer.expr = macro {
      $b{beforeRender};
      ${renderer.expr};
    }

    config.afterBuild.invoke({
      target: c,
      attributes: attributes,
      states: states,
      refs: refs,
      lifeCycle: lifeCycle,
    });
  }

  function hxxExprSugar(e:Expr)
    return e.transform(tink.hxx.Sugar.transformExpr);

  @:persistent static final configs:Map<String, Config> = new Map();

  static public function autoBuild(config:Config)
    return ClassBuilder.run([
      c -> new ViewBuilder(c, config).doBuild(),
      #if hotswap
        hotswap.Macro.lazify
      #end
    ]);

  static function autoBuildWith(configId:String)
    return autoBuild(switch configs[configId] {
      case null: Context.fatalError('please restart the compiler server', Context.currentPos());
      case v: v;
    });

  static function build(e:Expr)
    return
      switch e {
        case macro ($_:$ct):
          buildBase(ct);
        default:
          e.reject();
      }

  static function buildBase(renders:ComplexType, ?fn) {
    var cls = Context.getLocalClass().get();

    cls.meta.add(':observable', [], (macro null).pos);
    cls.meta.add(':coconut.viewbase', [], (macro null).pos);

    if (fn != null)
      fn(cls);

    return Context.getBuildFields().concat(base(renders).fields);
  }

  static public function init(renders:ComplexType, afterBuild:Callback<ViewInfo>)
    return buildBase(renders, function (cls) {
      Context.currentPos().warning('Your coconut backend seems to be out of date');

      var id = '${cls.module}.${cls.name}';

      configs.set(id, { renders: renders, afterBuild: afterBuild });

      cls.meta.add(':autoBuild', [macro coconut.ui.macros.ViewBuilder.autoBuildWith($v{id})], (macro null).pos);
    });


  static function base(renders) return macro class {
    public var viewId(default, null):Int = idCounter++; static var idCounter = 0;

    @:noCompletion final _coco_revision:tink.state.State<Int>;

    public function new(
        render:Void->$renders,
        shouldUpdate:Void->Bool,
        track:Void->Void,
        beforeRerender:Void->Void,
        rendered:Bool->Void
      ) {

      var mounted = if (rendered != null) rendered.bind(true) else null,
          updated = if (rendered != null) rendered.bind(false) else null;

      var firstTime = true,
          last = null,
          hasBeforeRerender = beforeRerender != null,
          hasUpdated = updated != null,
          _coco_revision = new tink.state.State(0);

      var lastRev = _coco_revision.value;

      super(
        tink.state.Observable.auto(
          function renderView() {
            var curRev = _coco_revision.value;
            if (track != null) track();

            if (firstTime) firstTime = false;
            else {
              if (curRev == lastRev && shouldUpdate != null && !shouldUpdate())
                return last;
              var hasCallbacks = __bc.length > 0;
              if (hasBeforeRerender || hasCallbacks)
                tink.state.Observable.untracked(function () {
                  if (hasBeforeRerender) beforeRerender();
                  if (hasCallbacks) for (c in __bc.splice(0, __bc.length)) c.invoke(false);
                  return null;
                });
            }
            lastRev = curRev;
            return last = render();
          }
        ),
        mounted,
        function () {
          var hasCallbacks = __au.length > 0;
          if (hasUpdated || hasCallbacks)
            tink.state.Observable.untracked(function () {
              if (hasUpdated) updated();
              if (hasCallbacks) for (c in __au.splice(0, __au.length)) c.invoke(Noise);
              return null;
            });
        },
        function () {
          last = null;
          firstTime = true;
          __beforeUnmount();
        }
      );

      this._coco_revision = _coco_revision;
    }

    @:noCompletion var __bu:Array<tink.core.Callback.CallbackLink> = [];
    @:noCompletion function __beforeUnmount() {
      for (c in __bu.splice(0, __bu.length)) c.cancel();
      for (c in __bc.splice(0, __bu.length)) c.invoke(true);
    }

    @:extern inline function untilUnmounted(c:tink.core.Callback.CallbackLink):Void __bu.push(c);
    @:extern inline function beforeUnmounting(c:tink.core.Callback.CallbackLink):Void __bu.push(c);

    @:noCompletion var __bc:Array<tink.core.Callback<Bool>> = [];

    @:extern inline function untilNextChange(c:tink.core.Callback<Bool>):Void __bc.push(c);
    @:extern inline function beforeNextChange(c:tink.core.Callback<Bool>):Void __bc.push(c);

    @:noCompletion var __au:Array<tink.core.Callback<tink.core.Noise>> = [];

    @:extern inline function afterUpdating(callback:Void->Void) __au.push(callback);

    function forceUpdate(?callback) {
      _coco_revision.set(_coco_revision.value + 1);
      if (callback != null) afterUpdating(callback);
    }
  }
}

private typedef Config = {
  final renders:ComplexType;
  final ?implicits:{
    final name:String;
    final fields:Array<Field>;
  }
  final afterBuild:Callback<ViewInfo>;
}
#end
