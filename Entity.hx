class Entity extends Drawable {
	public var vel:Vector = new Vector();
	public var directions = new Vector();
	public var friction = 50.;
	public var lifeTime = 0.;
	public var orientation = 1.;
	public var speed = 100.;
	public var damage = 0.;
	public var app:Main;
	public var maxAge = 1e9;
	public var maxHP = 1.;
	public var affects = new Array<{kind:Affect, lifeTime:Float}>();

	public function new(app:Main) {
		super(app.s2d);
		app.entities.push(this);
		this.app = app;
	}

	public function pos() {
		return new Vector(x, y);
	}

	public function apply(affect:Affect){
		if(affect.slot != null){
			var other = Lambda.find(affects, a -> a.kind.slot == affect.slot);
			if(other != null){
				endAffect(other);
			}
		}
		affect.onStart(this);
		affects.push({kind:affect, lifeTime:0});		
	}

	public function endAffect(affect:{kind:Affect, lifeTime:Float}){
		this.affects.remove(affect);
		affect.kind.onEnd(this);
	}

	public function update(dt:Float) {
		lifeTime += dt;
		if (directions != null) {
			vel = vel.add(directions.multiply(speed));
			directions = null;
		}
		
		x += vel.x * dt;
		y += vel.y * dt;


		vel = vel.multiply(Math.max(0., 1. - dt * friction / Math.pow(vel.length(), 0.1)));

		if (vel.x != 0.)
			orientation = vel.x < 0 ? -1 : 1;

		scaleX = orientation;

		if(lifeTime>=maxAge)
				dispose();

		for(affect in affects){
			affect.lifeTime += dt;
			if(affect.lifeTime >= affect.kind.duration){
				endAffect(affect);
			}
		}

		affects = Lambda.filter(affects, affect -> affect.lifeTime < affect.kind.duration);
	}

	public function dispose() {
		app.entities.remove(this);
		remove();
	}

	public function checkCollision(missile:Missile):Bool {
		return false;
	}

	public function moveTo(e:Entity){
		directions = e.pos().sub(pos()).normalized();
	}

	public function distance(other){
		return pos().distance(other.pos());
	}
	

	public function hitBy(missile:Missile):Float{
		return 0.;
	}	
} 