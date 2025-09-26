extends Resource
class_name LootTable

@export var tables: Dictionary = {
	"plains": [
		{"subtype": "plains", "weight": 5, "min_count": 1, "max_count": 1},
		{"subtype": "forest", "weight": 2, "min_count": 1, "max_count": 1}
	],
}

# ==============================
# Roll a random loot from a table
# ==============================
func roll(table_name: String) -> String:
	if not tables.has(table_name):
		return ""
	var entries = tables[table_name]
	if entries.size() == 0:
		return ""
	# Total weight
	var total_weight = 0
	for e in entries:
		total_weight += e["weight"]
	# Pick random number
	var r = randi() % total_weight
	for e in entries:
		r -= e["weight"]
		if r < 0:
			return e["subtype"]
	return ""
