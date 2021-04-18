class Matter extends Entity {
	public var bitmap:Bitmap;
	public var other:Matter;
	public var size = 1.;

	public function new(spawner:Entity, size = 1.) {
		super(spawner.app);
		this.size = size;
		friction = 0.1;
		speed = 2;
		setPosition(spawner.x, spawner.y);
		bitmap = new Bitmap(Res.images.matter.toTile().center(), this);
		bitmap.scale(Math.pow(size, 0.5)*2);
		rotation = Math.random(Math.PI/6);		
	}

	override public function update(dt:Float) {
		super.update(dt);
		moveTo(other);
		/*friction = Math.atan(lifeTime)*0.2;
		speed = Math.atan(lifeTime);*/
		if(distance(other) < 30){
			dispose();
			other.dispose();
		}
	}

	public function link(other:Matter){
		this.other = other;
		vel = new Vector(Math.random()-0.5, Math.random()-0.5).add(other.pos().sub(this.pos()).normalized()).multiply(100.);
		other.other = this;
		other.speed = 10;
		//other.vel = vel.multiply(-1);
		bitmap.color=new Vector(Math.random(), Math.random(), Math.random(), 1);
		other.bitmap.color = bitmap.color;
	}
	

}