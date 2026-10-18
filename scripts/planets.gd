extends RefCounted

# One source of truth for pacing and visual identity. Gas giants use platforms.
const DATA = [
	{"name": "MARTE", "subtitle": "Colônia Ferrugem", "floor": Color("291e29"), "accent": Color("f39b70"), "enemy": Color("ed765e"), "kind": 0, "speed": 76.0, "hazard": "CRATERAS • use os pilares como cobertura"},
	{"name": "NETUNO", "subtitle": "Plataforma Boreal", "floor": Color("12283c"), "accent": Color("78cef5"), "enemy": Color("a5e6ff"), "kind": 1, "speed": 65.0, "hazard": "GEADA • áreas sinalizadas congelam; use o dash para escapar"},
	{"name": "JÚPITER", "subtitle": "Plataforma Olho da Tempestade", "floor": Color("272236"), "accent": Color("b0a3ff"), "enemy": Color("c8a0f5"), "kind": 2, "speed": 92.0, "hazard": "TEMPESTADE • o vento empurra seu traje"},
	{"name": "NEXO", "subtitle": "Trono da Convergência", "floor": Color("171529"), "accent": Color("e4b5ff"), "enemy": Color("f1c4ff"), "kind": 3, "speed": 100.0, "hazard": "CONVERGÊNCIA • todos os inimigos e o Deus Alienígena"}
]

const UPGRADES = [
	{"name": "PRISMA", "desc": "+2 projéteis em leque\nDano por projétil -15%", "key": "spread"},
	{"name": "REATOR", "desc": "Cadência +25%\nMovimento -5%", "key": "rate"},
	{"name": "TRAJE", "desc": "+1 de vida máxima\nRecupera 2 de vida", "key": "health"},
	{"name": "PROPULSOR", "desc": "Movimento +18%\nDash recarrega mais rápido", "key": "speed"},
	{"name": "PLASMA", "desc": "Dano +35%\nProjéteis maiores", "key": "damage"},
	{"name": "ESTABILIZADOR", "desc": "+8 segundos por arena\nRecupera 1 de vida", "key": "time"}
]
