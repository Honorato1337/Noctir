extends RefCounted
# Public names follow the authored silhouettes; keep filenames stable.
const MOBS := ["GOSMA RUBRA", "ESPINHO BOREAL"]
const JUPITER := ["CUBO INVESTIDOR", "CUBO ARTILHEIRO", "CUBO GRAVITACIONAL"]
const BOSSES := ["DEVORADOR DE SUCATA", "LANCEIRO BOREAL", "NÚCLEO DA TORMENTA"]
const SUPERS := ["MANDÍBULA FERRUGEM", "CERVO ABISSAL", "TITÃ DE ÍONS"]
const FINAL := "ARGOS, O OLHO DO CAOS"
static func name_for(kind: int, boss: bool, superboss: bool, god: bool, role: int = 0) -> String:
	if god: return FINAL
	if superboss: return SUPERS[clampi(kind,0,2)]
	if boss: return BOSSES[clampi(kind,0,2)]
	if kind == 2: return JUPITER[clampi(role,0,2)]
	return MOBS[clampi(kind,0,1)]
