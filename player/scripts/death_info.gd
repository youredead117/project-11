extends Resource
class_name DeathInfo

enum Cause{
	Knife,
	M4,
	Grenade,
	Map,
	Command
}

#"You were killed by {PLAYER} using"
const CAUSE_TEXT = [
	"the bayonet.",
	"the rifle.",
	"a grenade.",
	"",
	"a command."
]

var killer_username: String
var killer_node_name: StringName
var killer_node: Player

var cause: Cause

func construct_death_text() -> String:
	var output: String = "You were killed by "
	
	if cause == Cause.Map:
		output += "the map."
	else:
		output += killer_username
		output += " using "
		output += CAUSE_TEXT[cause]
	
	return output
