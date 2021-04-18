import Effects.Explosion;
import hxsl.Types.Vec;
import Equipment.Weapon;

class Missile extends Entity {
	public var weapon:Weapon;
	public var launcher:Bodypart;
	public var owner:Mob;
	public var bitmap:Bitmap;
	public var trail:Bitmap;
	public var armed = true;
	public var kind = 0;
	public var weaponDamage:Float;

	public var insideOf:Array<Entity> = [];

	public function new(launcher:Bodypart, weapon:Weapon) {
		super(launcher.mob.app);
		this.weapon = weapon;
		this.owner = launcher.mob;
		this.launcher = launcher;

		maxAge = weapon.missileLifetime();
		maxHP = weapon.missileHP;
		weaponDamage = weapon.damage;

		getScene().addChildAt(this, 2);

		if (weapon.missile != null)
			bitmap = new Bitmap(weapon.missile.toTile().center(), this);
		if (weapon.trail != null) {
			trail = new Bitmap(weapon.trail.toTile(), this);
			this.addChildAt(trail, 0);
			trail.scaleX = 0;
			trail.scaleY = bitmap.getSize().height * 0.5;
			trail.y = -trail.scaleY / 2;
		}

		rotation = launcher.rotation;
		friction = 0;
		var dir = launcher.firingDirection();
		vel = dir.multiply(weapon.missileSpeed);

		switch (weapon.mode) {
			case Contramotion:
				scaleX = vel.x > 0 ? 1 : -1;
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
								mob.hitBy(this);
								lifeTime = i;
								return;
							}
						}
						i += interval;
					}
				})();
				armed = false;
			case Angled:
				var d = launcher.mob.lookingAt.distance(new Vector(launcher.x, launcher.y));
				var a = Math.random(Math.PI * 2);
				var v = new Vector(Math.cos(a), Math.sin(a));
				var pos = launcher.mob.lookingAt.add(v.multiply(d));
				setPosition(pos.x, pos.y);
				vel = v.multiply(-weapon.missileSpeed);
			default:
				var pos = new Vec(launcher.absX, launcher.absY);
				if(weapon.image != null)
					pos = pos.add(vel.normalized().multiply(weapon.image.getSize().width / 2));
				setPosition(pos.x, pos.y);
		}
		if (weapon.thrown) {
			armed = false;
			maxAge = Math.min(weapon.range, launcher.mob.pos().distance(launcher.mob.lookingAt)) / weapon.missileSpeed;
		}
	}

	override public function update(dt:Float) {
		switch (weapon.mode) {
			case PlusOne:
				if (lifeTime < 0) {
					lifeTime += dt;
					bitmap.alpha = 1 + Math.atan(lifeTime * 5);
				} else {
					defaultUpdate(dt);
				}
			case Contramotion:
				contramotionUpdate(dt);
				updateTrail();
			case OneBullet:
				var n = 2;
				if (pos().distance(launcher.mob.lookingAt) > 1000) {
					var dir = app.u.lookingAt.sub(this.pos()).normalized();
					vel = dir.multiply(weapon.missileSpeed);
				}
				defaultUpdate(dt);
			default:
				defaultUpdate(dt);
		}
	}

	function defaultUpdate(dt:Float) {
		super.update(dt);
		rotation = Math.atan2(vel.y, vel.x) + (vel.x < 0 ? Math.PI : 0);
		checkHits();
		updateTrail();
	}

	function checkHits() {
		var collidingNowBuf:Array<Entity> = null;
		for (e in app.entities) {
			if (e.checkCollision(this)) {
				if (collidingNowBuf == null)
					collidingNowBuf = new Array<Entity>();
				collidingNowBuf.push(e);
			}
		}
		if (collidingNowBuf != null) {
			for (e in collidingNowBuf) {
				if (!insideOf.contains(e)) {
					hitFor(e.hitBy(this));
				}
			}
		}
		if (collidingNowBuf == null) {
			if (insideOf.length > 0)
				insideOf = [];
		} else {
			insideOf = collidingNowBuf;
		}
	}

	public function contramotionUpdate(dt:Float) {
		lifeTime -= dt;
		x = launcher.absX + lifeTime * vel.x;
		y = launcher.absY + lifeTime * vel.y;
		if (this.lifeTime < 0) {
			this.dispose();
			weapon.applyRecoil(this.launcher);
		}
		/*for (e in app.entities) {
			if(e.checkCollision(this)){
				hitFor(e.hitBy(this));
			}
		}*/
	}

	function updateTrail() {
		if (trail != null) {
			var trailLength = Math.min(500, this.lifeTime * this.weapon.missileSpeed);
			trail.scaleX = trailLength / 30;
			trail.x = -trailLength;
		}
	}

	public function hitFor(hitDamage:Float) {
		if (weapon.mode != Contramotion) {
			damage += hitDamage;
			if (damage > maxHP){
				dispose();			
			}
		}
	}

	override public function dispose() {
		explode();
		super.dispose();
	}

	public function explode(){
		if (weapon.explosion != null) {
			new Explosion(weapon.explosion, this, weapon.explosionSize);
		}
		if(weapon.aoe>0){
			for (mob in owner.app.entities) {
				if (mob.distance(this)<weapon.aoe) {
					mob.hitBy(this);
				}
			}
		}
	}
}
