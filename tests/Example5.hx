import coconut.ui.*;

class Example5<T> extends View {
  @:attribute var data:T;
  @:attribute var renderer:{ data: T }->Children;
  function render() '
    <div class="example5">
      {...renderer({ data: data })}
    </div>
  ';

}