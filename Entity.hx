class Entity extends Drawable {
	public var vel:Vector = new Vector();
	public var directions:Vector;
	public var friction = 50.;
	public var lifeTime = 0.;
	public var orientation = 1;
	public var walkSpeed = 100;
	public var app:Main;

	public function new(app:Main) {
		super(app.s2d);
		app.entities.push(this);
		this.app = app;
	}

	public function pos() {
		return new Vector(x, y);
	}

	public function update(dt:Float) {
		lifeTime += dt;
		if (directions != null) {
			vel = vel.add(directions.multiply(walkSpeed));
			directions = null;
		}
		x += vel.x * dt;
		y += vel.y * dt;

		vel = vel.multiply(Math.max(0., 1. - dt * friction));
		if (vel.x != 0.)
			orientation = vel.x < 0 ? -1 : 1;

		scaleX = orientation;
	}

	public function dispose() {
		app.entities.remove(this);
		remove();
	}

	public function checkCollision(missile:Missile):Bool {
		return false;
	}
} 