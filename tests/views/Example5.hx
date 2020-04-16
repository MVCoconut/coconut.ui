package views;

class Example5<T> extends View {
  @:attribute var data:T;
  @:attribute var renderData:{ data: T }->Children;
  @:computed var content:RenderResult = hxx('
    <div class="example5">
      {...renderData({ data: data })}
    </div>
  ');
  function render() return content;
}