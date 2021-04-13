class Missile extends Entity {
	public var weapon:Weapon;
	public var launcher:Bodypart;
	public var owner:Mob;
	public var image:Bitmap;
	public var trail:Bitmap;
	public var armed = true;

	public function new(launcher:Bodypart, weapon:Weapon) {
		super(launcher.mob.app);
		this.weapon = weapon;
		this.owner = launcher.mob;
		this.launcher = launcher;

		getScene().addChildAt(this, 2);

		if (weapon.missile != null)
			image = new Bitmap(weapon.missile.toTile().center(), this);
		if (weapon.trail != null) {
			trail = new Bitmap(weapon.trail.toTile(), this);
			this.addChildAt(trail, 0);
			trail.scaleX = 0;
			trail.scaleY = image.getSize().height * 0.5;
			trail.y = -trail.scaleY / 2;	
		}

		rotation = launcher.rotation;		
		friction = 0;
		var dir = new Vector(Math.cos(rotation), Math.sin(rotation)).multiply(launcher.scaleX);
		vel = dir.multiply(weapon.missileSpeed);

		if (weapon.contramotion) {
			scaleX = vel.x>0?1:-1;
			lifeTime = weapon.missileLifetime();
			var interval = 0.01;
			(() -> {
				var i = 0.;
				var max = weapon.missileLifetime();
				while (i < max) {
					x = launcher.absX + i * vel.x;
					y = launcher.absY + i * vel.y;
					for (mob in owner.app.entities) {
						if (mob.checkCollision(this)) {
							lifeTime = i;
							return;
						}
					}
					i += interval;
				}
			})();
		} else {
			setPosition(launcher.absX, launcher.absY);
		}
	}

	override public function update(dt:Float) {
		if (weapon.contramotion)
			contramotionUpdate(dt);
		else {
			super.update(dt);
			if (this.lifeTime > weapon.missileLifetime())
				this.dispose();
			for (e in app.entities) {
				e.checkCollision(this);
			}
		}
		updateTrail();
	}

	public function contramotionUpdate(dt:Float) {
		lifeTime -= dt;
		x = launcher.absX + lifeTime * vel.x;
		y = launcher.absY + lifeTime * vel.y;
		if (this.lifeTime < 0) {
			this.dispose();
			weapon.applyRecoil(this.launcher);
		}
		for (e in app.entities) {
			e.checkCollision(this);
		}
	}

	function updateTrail() {
		if (trail != null) {
			var trailLength = Math.min(500, this.lifeTime * this.weapon.missileSpeed);
			trail.scaleX = trailLength / 30;
			trail.x = -trailLength;
		}
	}

	public function hit() {
		this.armed = false;
		if (!weapon.contramotion) {
			this.dispose();
		}
	}
}
