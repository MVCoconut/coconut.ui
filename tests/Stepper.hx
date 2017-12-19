class Stepper extends coconut.ui.View {
  @:attribute var step:Int = 1;
  @:attribute function onconfirm(value:Int):Void;
  @:state var value:Int = 0;
  function render() '
    <div class="counter">
      <button onclick={value -= step}>-</button>
      <span>{value}</span>
      <button onclick={value += step}>+</button>
      <button onclick={onconfirm(value)}>OK</button>
    </div>
  ';
}