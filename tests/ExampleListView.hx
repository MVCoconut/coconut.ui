class ExampleListView extends coconut.ui.View<ListModel<{ foo: Int, bar:Int }>> {
  function render() '
    <div class="foo-list">
      <for {i in items}>
        <Example key={i} {...i} />
      </for>
    </div>
  ';
}