package views;

class Blargh extends View {
  @:attribute function blub(attr:{ foo:String }):Children;
  @:state public var hidden:Bool = false;
  function render() '
    <if {!hidden}>
      <>
        <div>1</div>
        <div>2</div>
        {...blub({ foo: "yeah" })}
        <button class="hide-blargh" onclick={hidden = true}>Hide</button>
      </>
    </if>
  ';
}