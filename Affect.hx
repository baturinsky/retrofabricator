enum Slot {
  Slowed;
}

class Affect {
  public var duration:Float;
  public var magnitude:Float;
  public function slot():Slot{return null;};

  public function new(duration:Float, magnitude:Float){
  }

  public function onStart(entity:Entity){
  }

  public function onEnd(entity:Entity){    
  }

}

class Slowed extends Affect{
  override public function slot():Slot{return Slowed;};

  override public function onStart(entity:Entity){
    entity.speed /= magnitude;
  }

  override public function onEnd(entity:Entity){    
    entity.speed *= magnitude;
  }
}