import coconut.ui.*;

class Example5<T> extends View<{ data:T, renderer:{ data: T }->RenderResult }> {
  function render() '
    <div class="example5">
      {renderer({ data: data })}
    </div>
  ';
}