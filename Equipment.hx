function setFields(o:Any, d:Dynamic) {
	for (field in Reflect.fields(d)) {
		Reflect.setField(o, field, Reflect.field(d, field));
	}
}

class Equipment {
	public var cooldown = 1.;
	public var image:Image;
	public var recoilRecovery = 5.;
	public var autofire = false;
	public var affect:Affect;
	public var onExecute: (Bodypart)->Void = null;
	public var onCooldownEnd: (Bodypart)->Void = null;

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
	public var hp = 100;
	override public function equip(mob:Mob, side = 1) {
		equipOn(mob, mob.torso);
		mob.maxHP = hp;
	}
}

class Helmet extends Equipment {
	override public function equip(mob:Mob, side = 1) {
		equipOn(mob, mob.head);
	}
}

class Boots extends Equipment {
	public var speed = 100;
	public var friction = 50;

	override public function equip(mob:Mob, side = 1) {
		equipOn(mob, mob.leg1);
		equipOn(mob, mob.leg2);
		mob.friction = friction;
		mob.speed = speed;
	}
	
	override public function execute(bodypart:Bodypart) {
		if(onExecute != null)
			onExecute(bodypart);
		bodypart.mob.leg2.cooldown = this.cooldown;
	};
}

enum WeaponMode{
	NormalShot;
	PlusOne;
	OneBullet;	
	Angled;
	Telebomb;
	Contramotion;
	Destabilizing;
	Recoilless;
	NTTE;
	
	Accumulator;
	Entropy;
}

class Weapon extends Equipment {
	public var damage = 10.;
	public var recoil = 10.;
	public var missileSpeed = 5000.;
	public var missileHP:Float;
	public var range = 10000.;
	public var momentum:Float;
	public var mode = NormalShot;
	public var pellets = 1;
	public var spread = 0.;
	public var prearmed = false;
	public var aoe = 0.;
	public var thrown = false;
	public var explosionSize:Float;
	
	public var missile:Image;
	public var trail:Image;
	public var explosion:Image;

	public function missileLifetime() {
		return range / missileSpeed;
	}


	override public function execute(bodypart:Bodypart) {
		if (mode != Contramotion) {
			applyRecoil(bodypart);
		}
		
		//bodypart.removeChild(missile);

		switch(mode){
			case PlusOne:
				new Missile(bodypart, this);
				var missile = new Missile(bodypart, this);
				missile.lifeTime = -1;
			case Recoilless:
				new Missile(bodypart, this);
				var missile = new Missile(bodypart, this);
				missile.vel = missile.vel.multiply(-1);
			default:				
				if(pellets>1){
					var rot = bodypart.rotation;
					for(i in 0...pellets){
						bodypart.rotation = rot - spread/2 + spread / (pellets-1) * i;
						new Missile(bodypart, this);
					}
					bodypart.rotation = rot;
				} else {
					new Missile(bodypart, this);
				}
		}
	};

	public function applyRecoil(bodypart:Bodypart) {
		var dir = bodypart.mob.relativeLookingAt().normalized();
		bodypart.applyRecoil(dir.multiply( -Math.min(30,this.recoil)));
		
		if(recoil > 10)
			bodypart.mob.vel = bodypart.mob.vel.add(bodypart.firingDirection().multiply(-recoil * 10));
	}

	override public function equip(mob:Mob, side = 1) {
		equipOn(mob, side == 1 ? mob.hand1 : mob.hand2);
	}

	override public function new(options:Dynamic) {
		super(options);
		if (options.recoilRecovery == null) {
			recoilRecovery = Math.abs(recoil) / cooldown / 10.;
		}
		if (options.momentum == null) {
			momentum = damage * 0.5;
		}
		if(options.missileHP == null){
			missileHP = damage;
		}
		if(options.explosionSize == null && options.aoe != null){
			explosionSize = options.aoe * 4/3;
		}
	}
}