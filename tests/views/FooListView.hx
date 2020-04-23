package views;

class FooListView extends View {
  @:attr var list:ListModel<Foo>;
  function render() '
    <div class="foo-list" style="background: blue">
      <for {i in list.items}>
        <Example2 model={i} />
      </for>
    </div>
  ';
}