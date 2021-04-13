function setFields(o:Any, d:Dynamic) {
	for (field in Reflect.fields(d)) {
		Reflect.setField(o, field, Reflect.field(d, field));
	}
}

/*var weapons:Dynamic<Weapon> = {};
	for(field in Reflect.fields(weaponsRaw))
	Reflect.setField(weapons, field, new Weapon(Reflect.field(weaponsRaw, field)); */
@:access(h2d.Scene)
class Main extends App {
	public var u:Mob;
	public var entities:Array<Entity> = [];
	public var h = 2048;
	public var w:Int;
	public var pause = false;

	var win:sdl.Window;

	override function init() {
		Res.initLocal();
		win = @:privateAccess hxd.Window.getInstance().window;

		// Window.getInstance().displayMode = sdl.Window.DisplayMode.Borderless;
		w = int(h * Math.sin(Math.PI / 3) * 2);

		engine.backgroundColor = 0xFFAAAAAA;

		s2d.renderer.defaultSmooth = true;
		Res.images.ubody.toTile().center();
		var blob = Res.images.cursor.toBitmap();
		s2d.events.defaultCursor = Cursor.Custom(new Cursor.CustomCursor([blob], 0, 4, 4));

		s2d.scaleMode = ScaleMode.LetterBox(w, h);
		win.resize(int(w / 2), int(h / 2));
		win.title = "Retrofabricator";
		win.center();

		/*var tf = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
			tf.text = "Hello Hashlink !"; */
		var controlsMark = new Bitmap(Res.images.controls_big.toTile(), s2d);
		// controlsMark.setPosition(w / 2, h / 2);
		controlsMark.setScale(2);

		u = new Mob(this);
		u.setPosition(500, 500);

		var weapons:Dynamic<Weapon> = {
			revolver: new Weapon({image: Res.images.revolver, missile: Res.images.bullet, trail: Res.images.trail}),
			l9ll: new Weapon({
				image: Res.images.l9ll,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				cooldown: 0.1,
				range: 5000,
				damage: 2,
				contramotion: true
			}),
			mac: new Weapon({
				image: Res.images.mac,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				cooldown: 0.05,
				damage: 1
			}),
			uzi: new Weapon({
				image: Res.images.uzi,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				cooldown: 0.05,
				damage: 1,
			}),
			pistol: new Weapon({
				image: Res.images.pistol,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				cooldown: 0.1
			}),
			long_revolver: new Weapon({
				image: Res.images.long_revolver,
				missile: Res.images.bullet,
				trail: Res.images.trail
			}),
			claw: new Weapon({image: Res.images.uhand, recoil: -30, range: 80})
		};

		var boots:Dynamic<Boots> = {
			uboots: new Boots({image: Res.images.uleg}),
			zlegs: new Boots({image: Res.images.uleg, speed: 50}),
		}

		weapons.uzi.equip(u, 1);
		weapons.l9ll.equip(u, 2);
		new Armor({image: Res.images.ubody}).equip(u);

		u.torso.applyRecoil(new Vector(100, 0));

		new Bitmap(Res.images.cog.toTile(), s2d);
		new Bitmap(Res.images.cube.toTile().center(), s2d).setPosition(w / 2, h / 2);

		var enemy = new Mob(this);
		enemy.setPosition(2000, 1000);
		boots.zlegs.equip(enemy);

		new Helmet({image: Res.images.zomhead2}).equip(enemy);
		weapons.claw.equip(enemy, 1);
		weapons.claw.equip(enemy, 2);
	}

	override function update(dt:Float) {
		if (Key.isPressed(Key.P))
			togglePause();
		if (!pause) {
			for (e in entities)
				e.update(dt);
			s2d.ysort(0);
		}
	}

	public function togglePause() {
		pause = !pause;
	}

	static function main() {
		new Main();
	}
}

class Equipment {
	public var cooldown = 1.;
	public var image:Image;
	public var recoilRecovery = 30.;

	public function execute(bodypart:Bodypart) {};

	public function new(options:Dynamic) {
		setFields(this, options);
	}

	public function equip(mob:Mob, side = 1) {}

	public function equipOn(mob:Mob, part:Bodypart) {
		part.setImage(image);
		part.equipment = this;
	}
}

class Armor extends Equipment {
	override public function equip(mob:Mob, side = 1) {
		equipOn(mob, mob.torso);
	}
}

class Helmet extends Equipment {
	override public function equip(mob:Mob, side = 1) {
		equipOn(mob, mob.head);
	}
}

class Boots extends Equipment {
	public var speed = 100;

	override public function equip(mob:Mob, side = 1) {
		equipOn(mob, mob.leg1);
		equipOn(mob, mob.leg2);
		mob.walkSpeed = speed;
	}
}

class Weapon extends Equipment {
	public var damage = 10.;
	public var recoil = 30.;
	public var missileSpeed = 5000.;
	public var range = 10000.;
	public var missile:Image;
	public var trail:Image;
	public var momentum:Float;
	public var contramotion = false;

	public function missileLifetime() {
		return range / missileSpeed;
	}

	override public function execute(bodypart:Bodypart) {
		if (!contramotion) {
			applyRecoil(bodypart);
		}

		var missile = new Missile(bodypart, this);
		bodypart.removeChild(missile);
	};

	public function applyRecoil(bodypart:Bodypart) {
		var dir = bodypart.mob.relativeLookingAt().normalized();
		bodypart.applyRecoil(dir.multiply(-this.recoil));
	}

	override public function equip(mob:Mob, side = 1) {
		equipOn(mob, side == 1 ? mob.hand1 : mob.hand2);
	}

	override public function new(options:Dynamic) {
		super(options);
		if (options.recoilRecovery == null) {
			recoilRecovery = Math.abs(recoil) / cooldown / 10;
		}
		if (options.momentum == null) {
			momentum = damage / 5;
		}
	}
}


class Bodypart extends Drawable {
	public var initialPos:Vector;
	public var recoil = new Vector();
	public var equipment:Equipment;
	public var cooldown = 0.;
	public var mob:Mob;
	public var bitmap:Bitmap;

	public function applyRecoil(recoilVec:Vector) {
		recoil.x += recoilVec.x;
		recoil.y += recoilVec.y;
	}

	public function setImage(image:Image) {
		if (bitmap != null)
			bitmap.remove();
		if (image == null)
			return;
		bitmap = new Bitmap(image.toTile().center(), this);
	}

	public function new(mob:Mob, pos:Vector, ?image:Image) {
		super(mob);
		setImage(image);
		this.mob = mob;
		if (pos == null)
			pos = new Vector();

		initialPos = pos;

		x = pos.x;
		y = pos.y;
	}

	public function update(dt:Float) {
		if (recoil.length() > 0) {
			recoil = recoil.multiply(Math.max(0, 1 - dt * (equipment == null ? 10 : equipment.recoilRecovery)));
			var p = initialPos.add(recoil);
			x = p.x;
			y = p.y;
		}
		if (cooldown > 0) {
			cooldown = Math.max(0, cooldown - dt);
		}
	}

	public function execute() {
		if (this.cooldown > 0)
			return;
		if (equipment != null) {
			equipment.execute(this);
			cooldown = equipment.cooldown;
		}
	}
}

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
/*class MobTemplate {
	public var head:Image;
	public var torso:Image;
	public var hand1:Image;
	public var hand2:Image;
	public var legs:Image;

	public function new(head:Image, torso:Image, hand1:Image, hand2:Image, legs:Image){
		this.head = head;
		this.torso = torso;
		this.hand1 = hand1;
		this.hand2 = hand2;
		this.legs = legs;
	}

	public function spawn(app:Main) {
		var mob = new Mob(app);
		mob.torso = new Bodypart(this.torso, mob);
		mob.head = new Bodypart(this.head, mob, new Vector(6, -42));
		mob.hand1 = new Bodypart(this.hand1, mob, new Vector(-24, -6));
		mob.hand2 = new Bodypart(this.hand2, mob, new Vector(24, -6));
		mob.leg1 = new Bodypart(this.legs, mob, new Vector(-18, 42));
		mob.leg2 = new Bodypart(this.legs, mob, new Vector(18, 42));
	   
	}
}*/
