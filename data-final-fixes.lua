---@type {[string]: uint8}
local tiers = {}

local last_tier = 0
local function add_tier(packs)
	last_tier = last_tier + 1
	for _, pack in pairs(packs) do
		if pack ~= nil then
			tiers[pack] = last_tier
		end
	end
end

add_tier({ "automation-science-pack" })
add_tier({ "logistic-science-pack" })
add_tier({ "military-science-pack", "chemical-science-pack" })
add_tier({ "production-science-pack", "utility-science-pack", "space-science-pack" })
add_tier({
	"space-science-pack",
	"agricultural-science-pack",
	"metallurgic-science-pack",
	"electromagnetic-science-pack",
	"kr-advanced-tech-card",
})
add_tier({ "kr-matter-tech-card", "cryogenic-science-pack", "fu_space_probe_science" })
add_tier({ "kr-singularity-tech-card" })
add_tier({ "promethium-science-pack" })

local backfill = {
	"automation-science-pack",
	"logistic-science-pack",
	"chemical-science-pack",
}

function ifib(n)
	local a, b = 1, 1
	for _ = 3, n do
		a, b = b, a + b
	end
	return b
end

local function cost_mult(tier, max_tier)
	local diff = max_tier - tier
	return ifib(diff + 2)
end

---@param tech data.TechnologyPrototype
local function process_tech(tech)
	if tech.unit == nil then
		return
	end

	local seen = {}

	local max_tier = 0
	for _, unit in pairs(tech.unit.ingredients) do
		seen[unit[1]] = true
		local tier = tiers[unit[1]]
		if tier ~= nil and tier > max_tier then
			max_tier = tier
		end
	end

	if max_tier == 0 then
		return
	end

	for _, tech_id in pairs(backfill) do
		local tier = tiers[tech_id]
		if tier == nil then
			error("Backfill science " .. tech_id .. " doesn't have tier assigned")
		end
		if tier < max_tier and not seen[tech_id] then
			table.insert(tech.unit.ingredients, { tech_id, 1 })
		end
	end

	for _, unit in pairs(tech.unit.ingredients) do
		local tier = tiers[unit[1]]
		if tier ~= nil then
			unit[2] = math.min(unit[2] * cost_mult(tier, max_tier), 65535)
		end
	end
end

for tier = 1, last_tier do
	---@type data.ItemSubGroup
	local science_group = {
		type = "item-subgroup",
		group = mods["science-tab"] and "science" or "intermediate-products",
		name = "tiered-science-subgroup-" .. tier,
		order = "tech-tier-" .. tier,
	}

	data:extend({ science_group })
end

for tech, tier in pairs(tiers) do
	local item = data.raw["tool"][tech]
	if item ~= nil then
		item.subgroup = "tiered-science-subgroup-" .. tier
	end
end

for _, tech in pairs(data.raw["technology"]) do
	process_tech(tech)
end
