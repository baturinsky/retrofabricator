import haxe.ds.StringMap;

enum Faction {
	US;
	THEM;
	BERSERKER;
}

@:allow(Equipment)
class Mob extends Entity {
	public var torso:Bodypart;
	public var head:Bodypart;
	public var leg1:Bodypart;
	public var leg2:Bodypart;
	public var hand1:Bodypart;
	public var hand2:Bodypart;

	public var lookingAt:Vector;
	public var collider:RoundRect;
	public var bodyparts:Array<Bodypart>;
	public var spawning = 0.;
	public var faction = THEM;

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
		leg1 = new Bodypart(this, new Vector(-18, 42), Res.images.uleg);
		leg2 = new Bodypart(this, new Vector(18, 42), Res.images.uleg);
		hand1 = new Bodypart(this, new Vector(-18, -6), Res.images.uhand);
		hand2 = new Bodypart(this, new Vector(18, -6), Res.images.uhand);
		bodyparts = [hand1, hand2, torso, head, leg1, leg2];
	}

	public function input() {
		directions = new Vector((Key.isDown(Key.D) ? 1 : 0) - (Key.isDown(Key.A) ? 1 : 0), (Key.isDown(Key.S) ? 1 : 0) - (Key.isDown(Key.W) ? 1 : 0));
		lookingAt = new Vector(app.s2d.mouseX, app.s2d.mouseY);

		if (Key.isPressed(Key.MOUSE_LEFT))
			if(hand1.pickupItem())
				return;

		if (Key.isPressed(Key.MOUSE_RIGHT))
			if(hand2.pickupItem())
				return;

		if (Key.isDown(Key.MOUSE_LEFT) || (lifeTime>1 && hand1.equipment.autofire))
			hand1.execute();

		if (Key.isDown(Key.MOUSE_RIGHT) || (lifeTime>1 && hand2.equipment.autofire))
			hand2.execute();

		if (Key.isDown(Key.SPACE))
			leg1.execute();
	}

	public function relativeLookingAt() {
		return lookingAt.sub(pos());
	}

	public function alive() {
		return damage < maxHP;
	}

	public function moveToOrAttack(e:Entity) {
		var uRelPos = e.pos().sub(pos());

		lookingAt = e.pos();
		if (lookingAt == null)
			lookingAt = new Vector();

		if (uRelPos.length() > cast(hand1.equipment, Weapon).range * 0.75) {
			directions = uRelPos.normalized();
		} else {
			directions = new Vector();
			hand1.execute();
			hand2.execute();
		}
	}

	override function update(dt:Float) {
		if(!alive())
			return;

		if (x < 50) {
			x = 50;			
			directions.x = Math.max(0, directions.x);
			vel.x = Math.min(Math.abs(vel.x), 30);
		}

		if (y < 50) {
			y = 50;
			directions.y = Math.max(0, directions.y);
			vel.y = Math.min(Math.abs(vel.y), 30);
		}

		if (x > app.w - 50) {
			x = app.w - 50;
			directions.x = Math.min(0, directions.x);
			vel.x = Math.max(-Math.abs(vel.x), -30);
		}

		if (y > app.h - 50) {
			y = app.h - 50;
			directions.y = Math.min(0, directions.y);
			vel.y = Math.max(-Math.abs(vel.y), -30);
		}

		if (spawning > 0) {
			spawning = Math.max(0, spawning - dt);
			x += vel.x;
			y += vel.y;
			alpha = 1. - spawning;
			// scaleX = 1. - spawning;
			// scaleY = 1. - spawning;
		} else {
			super.update(dt);
		}

		if (this == app.u) {
			input();
		} else {
			if (app.u.alive())
				moveToOrAttack(app.u);
		}

		torso.scaleX = orientation;
		leg1.scaleX = leg2.scaleX = head.scaleX = torso.scaleX;
		head.x = head.initialPos.x * torso.scaleX;

		scaleX = 1;

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

		for (part in bodyparts) {
			part.update(dt);
		}

		var pace = Math.atan(this.vel.length());
		logCyclePosition += dt * pace;

		for (ind => leg in [leg1, leg2]) {
			var a = (logCyclePosition * 10 + ind * Math.PI) * orientation;
			leg.x = leg.initialPos.x - Math.sin(a) * legAplitude.x * pace;
			leg.y = leg.initialPos.y + Math.cos(a) * legAplitude.y * pace;
		}

		this.collider.x = this.absX;
		this.collider.y = this.absY - 30;
	}

	override public function checkCollision(missile:Missile) {
		return (this.faction != missile.owner.faction && missile.armed && this.collider.contains(new Point(missile.x, missile.y)));
	}

	override public function hitBy(missile:Missile):Float {
		var recoil = missile.vel.normalized().multiply(missile.weapon.momentum);
		torso.applyRecoil(recoil.multiply(10));
		head.applyRecoil(recoil.multiply(15));
		hand1.applyRecoil(recoil.multiply(5));
		hand2.applyRecoil(recoil.multiply(5));
		damage += missile.weaponDamage;
		filter = Effects.tear(damage / maxHP);
		if (alive()) {
			switch(missile.weapon.mode){
				case Telebomb:
					x = Math.random(app.w);
					y = Math.random(app.h);
				default:
			}
		} else {
			die();
			if(missile.weapon.mode == Destabilizing){
				missile.weaponDamage = damage - maxHP;
				return missile.maxHP*2;
			}
		}
		return missile.weaponDamage + Math.max(0, maxHP - damage);
	}

	public function die() {
		for (b in bodyparts) {
			new Gibs(b);
		}
		var item = app.closestCraftingItem(pos());
		if (item != null) {
			var loot = Math.random() * 0.1;
			var m1 = new Matter(this, loot);
			var m2 = new Matter(item, loot);
			m1.link(m2);
			item.completeness -= loot;
			if (item.completeness < 0) {
				item.dispose();
			}
		}
		dispose();
	}

	public function lookingDirection(){
		return lookingAt.sub(pos()).normalized();
	}

}

class Gibs extends Entity {
	public var part:Bodypart;

	var rotationSpeed:Float;

	public function new(part:Bodypart) {
		super(part.mob.app);
		friction = 0;
		rotationSpeed = 20. * (Math.random(2) - 1.);
		this.part = part;
		var pos = part.getAbsPos();
		setPosition(pos.x, pos.y);
		part.remove();
		addChild(part);
		vel = new Vector(Math.random(part.x), Math.random(part.y - 50)).normalized().multiply(300);
		part.setPosition(0, 0);
		maxAge = 1;
		filter = part.mob.filter;
	}

	override public function update(dt:Float) {
		super.update(dt);
		this.rotate(dt * rotationSpeed);
		vel.y += dt * 1000;
		this.alpha = 1 - lifeTime;
	}

}
