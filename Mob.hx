class Mob extends Entity {
	public var torso:Bodypart;
	public var head:Bodypart;
	public var leg1:Bodypart;
	public var leg2:Bodypart;
	public var hand1:Bodypart;
	public var hand2:Bodypart;

	public var lookingAt:Vector;
	public var collider:RoundRect;
	public var allParts:Array<Bodypart>;

	var logCyclePosition = 0.;
	var legAplitude = new Vector(3, 3);

	public function new(app:Main) {
		super(app);
		collider = new RoundRect(0, -32, 82, 144, 0);
		getScene().addChildAt(this, 1);

		var shadow = new Bodypart(this, new Vector(0, 45), Res.images.blob);
		shadow.scaleY = 0.5;
		shadow.scaleX = 1.5;
		torso = new Bodypart(this, new Vector(0, -0), Res.images.ubody);
		head = new Bodypart(this, new Vector(6, -42), Res.images.uhead);
		hand1 = new Bodypart(this, new Vector(-18, -6), Res.images.uhand);
		hand2 = new Bodypart(this, new Vector(18, -6), Res.images.uhand);
		leg1 = new Bodypart(this, new Vector(-18, 42), Res.images.uleg);
		leg2 = new Bodypart(this, new Vector(18, 42), Res.images.uleg);
		allParts = [hand1, hand2, torso, head, leg1, leg2];
	}

	public function input() {
		directions = new Vector((Key.isDown(Key.D) ? 1 : 0) - (Key.isDown(Key.A) ? 1 : 0), (Key.isDown(Key.S) ? 1 : 0) - (Key.isDown(Key.W) ? 1 : 0));
		lookingAt = new Vector(app.s2d.mouseX, app.s2d.mouseY);

		if (Key.isDown(Key.MOUSE_LEFT))
			hand1.execute();

		if (Key.isDown(Key.MOUSE_RIGHT))
			hand2.execute();
	}

	public function relativeLookingAt() {
		return lookingAt.sub(pos());
	}

	override function update(dt:Float) {
		super.update(dt);

		if (this == app.u) {
			input();
		} else {
			var uRelPos = app.u.pos().sub(pos());

			if (uRelPos.length() > cast(hand1.equipment, Weapon).range * 0.75) {
				directions = uRelPos.normalized();
			} else {
				directions = new Vector();
				hand1.execute();
				hand2.execute();
			}
			lookingAt = app.u.pos();
		}

		torso.scaleX = orientation;
		leg1.scaleX = leg2.scaleX = head.scaleX = torso.scaleX;
		head.x = head.initialPos.x * torso.scaleX;

		scaleX = 1;

		var pace = Math.atan(this.vel.length());
		logCyclePosition += dt * pace;

		for (ind => leg in [leg1, leg2]) {
			var a = (logCyclePosition * 10 + ind * Math.PI) * orientation;
			leg.x = leg.initialPos.x - Math.sin(a) * legAplitude.x * pace;
			leg.y = leg.initialPos.y + Math.cos(a) * legAplitude.y * pace;
		}

		if (lookingAt != null)
			for (part in [head, hand1, hand2]) {
				var mouseDelta = lookingAt.sub(new Vector(part.absX, part.absY)).normalized();

				if (part == head)
					mouseDelta.y /= 10;

				var angle = Math.atan2(mouseDelta.y, mouseDelta.x);
				part.rotation = angle;

				if (mouseDelta.x > 0) {
					part.rotation = angle;
					part.scaleX = 1;
				} else {
					part.rotation = angle + Math.PI;
					part.scaleX = -1;
				}
			}

		for (part in allParts) {
			part.update(dt);
		}

		this.collider.x = this.absX;
		this.collider.y = this.absY - 30;
	}

	override public function checkCollision(missile:Missile) {
		if (this != missile.owner && missile.armed && this.collider.contains(new Point(missile.x, missile.y))) {
			missile.hit();
			var recoil = missile.vel.normalized().multiply(missile.weapon.momentum);
			this.torso.applyRecoil(recoil.multiply(10));
			this.head.applyRecoil(recoil.multiply(15));
			this.hand1.applyRecoil(recoil.multiply(5));
			this.hand2.applyRecoil(recoil.multiply(5));
			return true;
		} else {
			return false;
		}
	}
}
