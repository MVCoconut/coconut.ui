package views;

class ExampleListView extends View {
  @:attr var list:ListModel<{ var foo(default, never):tink.state.Observable<Int>; var bar(default, never):Int; }>;
  #if haxe4
  function render()
    <div class="foo-list">
      {for (item in list.items) <Example key={item} foo={item.foo} {...item} />}
    </div>
  ;
  #else
  function render() '
    <div class="foo-list">
      <for {i in list.items}>
        <Example key={i} foo={i.foo} {...i} />
      </for>
    </div>
  ';
  #end
}