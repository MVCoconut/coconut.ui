class ExampleListView extends coconut.ui.View {
  @:attr var list:ListModel<{ var foo(default, never):tink.state.Observable<Int>; var bar(default, never):Int; }>;
  function render() '
    <div class="foo-list">
      <for {i in list.items}>
        <Example key={i} foo={Observable.const(i.foo)} {...i} />
      </for>
    </div>
  ';
}