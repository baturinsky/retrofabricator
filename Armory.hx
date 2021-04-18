import hxd.snd.openal.LowPassDriver;

class Armory {
	public static var weapons:Dynamic<Weapon>;
	public static var zWeapons:Dynamic<Weapon>;
	public static var boots:Dynamic<Boots>;
	public static var armors:Dynamic<Armor>;
	public static var helmets:Dynamic<Helmet>;
	public static var spawnedItems:Array<Equipment>;

	public static function loadArmory() {
		Armory.weapons = {
			revolver: new Weapon({image: Res.images.revolver, missile: Res.images.bullet, trail: Res.images.trail}),
			contra: new Weapon({
				image: Res.images.l9ll,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				cooldown: 0.1,
				range: 3000,
				damage: 2,
				prearmed: false,
				mode: Contramotion
			}),
			mac: new Weapon({
				image: Res.images.mac,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				cooldown: 0.05,
				damage: 1
			}),
			plus_one: new Weapon({
				image: Res.images.plus_one,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				cooldown: 0.05,
				damage: 1,
				mode: PlusOne
			}),
			long_revolver: new Weapon({
				image: Res.images.long_revolver,
				missile: Res.images.bullet,
				trail: Res.images.trail
			}),
			one: new Weapon({
				image: Res.images.one,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				cooldown: 1000,
				damage: 5,
				missileHP: 1e6,
				range: 1e9,
				mode: OneBullet
			}),
			recoilless: new Weapon({
				image: Res.images.recoilless,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				damage: 50,
				recoil: 0,
				mode: Recoilless
			}),
			remote_shotgun: new Weapon({
				image: Res.images.remote_shotgun,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				cooldown: 2,
				damage: 3,
				pellets: 5,
				spread: 0.1,
				recoil: 30
			}),
			angled: new Weapon({
				image: Res.images.angled,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				cooldown: 0.1,
				damage: 2,
				mode: Angled
			}),
			telebomb: new Weapon({
				image: Res.images.explosive,
				missile: Res.images.explosive,
				cooldown: 5,
				damage: 5,
				aoe: 300,
				range: 600,
				thrown: true,
				recoil: 0,
				missileSpeed: 600,
				explosion: Res.images.explosion,
				explosionSize: 400,
				mode: Telebomb
			}),
			miner: new Weapon({
				image: Res.images.implosive,
				missile: Res.images.explosive,
				cooldown: 5,
				damage: 10,
				aoe: 300,
				missileSpeed: 0.2,
				range: 1,
				thrown: true,
				recoil: 0,
				explosion: Res.images.explosion,
				autofire: true
			}),
			claw: new Weapon({image: Res.images.uhand, recoil: -30, range: 80}),
			pistol: new Weapon({
				image: Res.images.pistol,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				cooldown: 3,
				damage: 10,
				missileSpeed: 1500
			}),
			slower: new Weapon({
				image: Res.images.mac,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				cooldown: 0.05,
				damage: 1,
				affect: new Affect.Slowed(10, 2),
			}),
			destabilizer: new Weapon({
				image: Res.images.revolver,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				missileHP: 0.01,
				damage: 10,
				cooldown: 2,
				aoe: 300,
				explosion: Res.images.explosion,
				mode: Destabilizing
			}),
			ntte: new Weapon({
				image: Res.images.long_revolver,
				missile: Res.images.bullet,
				trail: Res.images.trail,
				recoil: 1000,
				damage: 3,
				pellets: 5,
				spread: 0.1,
				cooldown: 1
			}),
		}

		Armory.boots = {
			uboots: new Boots({image: Res.images.uleg}),
			boost: new Boots({
				image: Res.images.boost,
				cooldown: 5,
				onExecute: (bodypart:Bodypart) -> {
					var mob = bodypart.mob;
					var boost = mob.lookingDirection().multiply(20000);
					for (e in mob.app.entities) {
						var dist = e.distance(mob);
						if (dist < 1000)
							e.vel = e.vel.add(boost.multiply(1 - dist / 1000));
					}
				}
			}),
			slide: new Boots({
				image: Res.images.slide,
				friction: 1,
				speed: 50,
				onExecute: (bodypart:Bodypart) -> {
					bodypart.mob.vel = new Vector();
				},
				onCooldownEnd: (bodypart:Bodypart) -> {},
				cooldown: 3
			}),
			swap: new Boots({
				image: Res.images.swap,
				onExecute: (bodypart:Bodypart) -> {
					var mob = bodypart.mob;
					var from = mob.pos();
					var to = mob.lookingAt;
					var delta = to.sub(from);
					for (e in mob.app.entities) {
						var there = e.pos().distance(from) < 200;
						var nearby = e.pos().distance(to) < 200;
						if (there && !nearby) {
							e.setPosition(e.x + delta.x, e.y + delta.y);
						}
						if (!there && nearby) {
							e.setPosition(e.x - delta.x, e.y - delta.y);
						}
					}
				},
				// cooldown:10
			}),
			moveOther: new Boots({
				image: Res.images.move_other,
				cooldown: 10,
				onExecute: (bodypart:Bodypart) -> {
					var mob = bodypart.mob;
					var delta = mob.lookingAt.sub(mob.pos());
					if (delta.length() > 500) {
						delta = delta.normalized().multiply(500);
					}
					for (e in mob.app.entities) {
						if (e != mob) {
							e.setPosition(e.x - delta.x, e.y - delta.y);
						}
					}
				}
			}),
			explosiveport: new Boots({
				image: Res.images.explosiveport,
				cooldown: 10,
				onExecute: (bodypart:Bodypart) -> {
					var mob = bodypart.mob;

					var missile = new Missile(bodypart, new Weapon({damage: 5, aoe: 400, explosion: Res.images.explosion}));
					missile.setPosition(mob.lookingAt.x, mob.lookingAt.y);
					missile.explode();

					mob.setPosition(mob.lookingAt.x, mob.lookingAt.y);
				}
			}),
			zlegs: new Boots({image: Res.images.uleg, speed: 50}),
		};

		Armory.armors = {
			uarmor: new Armor({image: Res.images.ubody}),
			zarmor: new Armor({image: Res.images.zbody, hp: 10}),
		};

		Armory.helmets = {
			zhelmet: new Helmet({image: Res.images.zomhead2})
		};

		// allWeapons = Reflect.fields(weapons).map(name -> Reflect.field(weapons, name));

		spawnedItems = [
			weapons.contra, weapons.one, weapons.plus_one, weapons.recoilless, weapons.angled, weapons.remote_shotgun, weapons.telebomb, weapons.miner,
			weapons.destabilizer, weapons.ntte, boots.boost, boots.slide, boots.swap, boots.moveOther, boots.explosiveport

		];
	}
}
