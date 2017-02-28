class ExampleListView extends coconut.ui.View<ListModel<{ var foo(default, never):tink.state.Observable<Int>; var bar(default, never):Int; }>> {
  function render() '
    <div class="foo-list">
      <for {i in items}>
        <Example key={i} {...i} />
      </for>
    </div>
  ';
}