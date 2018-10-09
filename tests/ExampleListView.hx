class ExampleListView extends coconut.ui.View {
  @:attr var list:ListModel<{ var foo(default, never):coconut.data.Value<Int>; var bar(default, never):Int; }>;
  function render() '
    <div class="foo-list">
      <for {i in list.items}>
        <Example key={i} {...i} />
      </for>
    </div>
  ';
}