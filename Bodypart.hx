class Bodypart extends Drawable {
	public var initialPos:Vector;
	public var recoil = new Vector();
	public var equipment:Equipment;
	public var cooldown = 0.;
	public var mob:Mob;
	public var bitmap:Bitmap;

	public function applyRecoil(recoilVec:Vector) {
		recoil.x += recoilVec.x * mob.torso.scaleX;
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
		recoil = recoil.multiply(Math.max(0, 1 - Math.min(1, dt * (equipment == null?5:equipment.recoilRecovery))));
		//recoil.x *= mob.torso.scaleX;
		var p = initialPos.add(recoil);
		x = p.x;
		y = p.y;

		if (cooldown > 0.) {
			cooldown = Math.max(0, cooldown - dt);
			if(equipment.cooldown>=1.)
				this.alpha = 0.5;
			if(cooldown == 0 && equipment.onCooldownEnd != null){
				equipment.onCooldownEnd(this);
			}
		} else {
			this.alpha = 1;
		}
	}

	public function pickupItem(){
		var item = mob.app.closestPossibleItem(mob.pos());
		if(item != null && item.distance(mob) < 100){
			if(item.equipment is Boots && !(this.equipment is Boots)){
				return mob.leg1.pickupItem();
			}
			item.equipment.equipOn(mob, this);
			item.endFabrication();
			return true;
		}
		return false;
	}

	public function execute() {
		if (this.cooldown > 0)
			return;
		if (equipment != null && mob.spawning==0.) {
			equipment.execute(this);
			cooldown = equipment.cooldown;
		}
	}

	public function firingDirection(){
		return new Vector(Math.cos(rotation), Math.sin(rotation)).multiply(scaleX);
	}
}


