import coconut.ui.*;

class Example5<T> extends View {
  @:attribute var data:T;
  @:attribute var renderer:{ data: T }->Children;
  @:computed var content:RenderResult = hxx('
    <div class="example5">
      {...renderer({ data: data })}
    </div>
  ');
  function render() return content;
}