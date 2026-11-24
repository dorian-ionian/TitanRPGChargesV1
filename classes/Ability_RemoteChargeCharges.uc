class Ability_RemoteChargeCharges extends RPGAbility;

//extra remote charges that can be placed at once, per level, on top of RFRemoteCharge.MaxGrenades
var config int ChargesPerLevel;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientSyncMaxGrenades;
}

//MaxGrenades is not replicated, but the owning client lays out the charge
//digits from it, so push the raised value to that client
simulated function ClientSyncMaxGrenades(RFRemoteCharge W, int NewMax)
{
	if(W != None)
		W.MaxGrenades = NewMax;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	if(Role == ROLE_Authority)
		SetTimer(2.0, true);
}

//sweep catches charge weapons picked up or bought after the pawn spawned
function Timer()
{
	if(Role == ROLE_Authority && Instigator != None)
		ApplyTo(Instigator);
}

function ModifyPawn(Pawn Other)
{
	Super.ModifyPawn(Other);

	if(Role == ROLE_Authority && Other != None)
		ApplyTo(Other);
}

//raises this player's own weapon instance only, never the class default,
//so the bonus stays per player
function ApplyTo(Pawn P)
{
	local Inventory Inv;
	local RFRemoteCharge W;
	local int Target;

	for(Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		W = RFRemoteCharge(Inv);
		if(W == None)
			continue;

		Target = W.class.default.MaxGrenades + AbilityLevel * ChargesPerLevel;
		if(W.MaxGrenades < Target)
		{
			W.MaxGrenades = Target;
			ClientSyncMaxGrenades(W, Target);
		}
	}
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", string(ChargesPerLevel));
}

defaultproperties
{
	AbilityName="Remote Charge Stockpile"
	StatName="Remote Charge Stockpile"
	Description="Increases the number of remote charges you can place at once by $1 per level."
	MaxLevel=5
	StartingCost=5
	ChargesPerLevel=5
	Category=class'AbilityCategory_Weapons'
}
