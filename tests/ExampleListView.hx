class ExampleListView extends coconut.ui.View<ListModel<{ foo: tink.state.Observable<Int>, bar:Int }>> {
  function render() '
    <div class="foo-list">
      <for {i in items}>
        <Example key={i} {...i} />
      </for>
    </div>
  ';
}