"""
ReceiptLedger – Expanded Taxonomy Generator
Generates a comprehensive, rich retail dictionary covering 150+ categories
with extensive Roman Urdu, English, regional, brand, and typo aliases.
"""

import json
from pathlib import Path
from typing import Dict, List, Any

# Load existing base taxonomy
base_path = Path(r"c:\Users\Asad\Desktop\ReceiptLedger\data\local_taxonomy.json")
existing_items: List[Dict[str, Any]] = json.loads(base_path.read_text(encoding="utf-8"))

# Index existing by canonical name
taxonomy_map: Dict[str, Dict[str, Any]] = {item["canonical_name"]: item for item in existing_items}

# New and expanded entries across all sectors
ADDITIONAL_OR_UPDATED_ITEMS: List[Dict[str, Any]] = [
    # ── HEALTH & PHARMACY (Expanded) ──────────────────────────────────────────
    {
        "canonical_name": "Pain & Fever Relief",
        "category": "Health & Pharmacy",
        "standard_unit": "pkt",
        "aliases": [
            "panadol", "panadol extra", "panadol cf", "panadol drop", "panadol syrup",
            "paracetamol", "calpol", "disprin", "febrol", "brufen", "brufen 400mg",
            "brufen syrup", "ponstan", "ponstan forte", "aspirin", "pain relief",
            "fever medicine", "headache tablet", "dard ki goli", "bukhar ki goli"
        ]
    },
    {
        "canonical_name": "Cough, Cold & Flu",
        "category": "Health & Pharmacy",
        "standard_unit": "pkt",
        "aliases": [
            "arinac", "arinac forte", "arinac syrup", "sancos", "sancos syrup",
            "hydryllin", "hydryllin syrup", "pulmonol", "actifed", "actifed syrup",
            "benylin", "fexet", "fexet 120mg", "softin", "rigix", "t-day",
            "cough syrup", "cold tablet", "khansi syrup", "nazla zukaam"
        ]
    },
    {
        "canonical_name": "Digestion & Stomach Relief",
        "category": "Health & Pharmacy",
        "standard_unit": "pkt",
        "aliases": [
            "eno", "eno sachet", "gaviscon", "gaviscon syrup", "gaviscon sachet",
            "risek", "risek 20mg", "risek 40mg", "omeprazole", "nexum", "nexum 40mg",
            "digas", "flatulence", "antacid", "flagyl", "flagyl 400mg", "entamizole",
            "imodium", "ors", "nimkol", "pait dard", "acid reflux", "gastric"
        ]
    },
    {
        "canonical_name": "Antibiotics & Prescription Medicines",
        "category": "Health & Pharmacy",
        "standard_unit": "pkt",
        "aliases": [
            "augmentin", "augmentin 625mg", "augmentin 1g", "amoxil", "amoxil 500mg",
            "ciproxin", "ciprofloxacin", "azomax", "azithromycin", "klacid", "cefixime",
            "antibiotic", "capsules", "tablets", "injections"
        ]
    },
    {
        "canonical_name": "Vitamins & Supplements",
        "category": "Health & Pharmacy",
        "standard_unit": "pkt",
        "aliases": [
            "cac 1000", "cac 1000 plus", "surbex z", "neurobion", "neurobion forte",
            "vitamin c", "cevalin", "caltrate", "folic acid", "evion", "vitamin e",
            "multivitamin", "fish oil", "omega 3", "calcium tablets", "taqat ki goli"
        ]
    },
    {
        "canonical_name": "First Aid & Antiseptics",
        "category": "Health & Pharmacy",
        "standard_unit": "pcs",
        "aliases": [
            "pyodine", "pyodine solution", "pyodine gargle", "dettol liquid",
            "dettol antiseptic", "sunnyplast", "band aid", "bandage", "gauze bandage",
            "polyfax", "polyfax eye ointment", "polyfax skin ointment", "cotton wool",
            "surgical cotton", "medical tape", "first aid", "पट्टी", "mercurchrome"
        ]
    },
    {
        "canonical_name": "Medical Supplies & PPE",
        "category": "Health & Pharmacy",
        "standard_unit": "pcs",
        "aliases": [
            "face mask", "surgical mask", "n95 mask", "medical gloves", "latex gloves",
            "hand sanitizer", "sanitizer bottle", "thermometer", "digital thermometer",
            "blood pressure monitor", "sugar strips", "accuchek strips", "syringe", "disposable syringe"
        ]
    },

    # ── PERSONAL CARE (Expanded) ──────────────────────────────────────────────
    {
        "canonical_name": "Soap & Handwash",
        "category": "Personal Care",
        "standard_unit": "pcs",
        "aliases": [
            "soap", "lux soap", "lifebuoy soap", "dettol soap", "safeguard soap",
            "dove soap", "palmolive soap", "capri soap", "hand wash", "liquid handwash",
            "dettol handwash", "lifebuoy handwash", "beauty soap", "sabun", "nahane ka sabun"
        ]
    },
    {
        "canonical_name": "Shampoo & Hair Care",
        "category": "Personal Care",
        "standard_unit": "pcs",
        "aliases": [
            "shampoo", "head and shoulders", "head & shoulders", "sunsilk shampoo",
            "pantene shampoo", "clear shampoo", "tresemme shampoo", "vatika shampoo",
            "hair conditioner", "sunsilk conditioner", "pantene conditioner", "hair oil",
            "parachute coconut oil", "mustard hair oil", "amla hair oil", "sarson oil hair"
        ]
    },
    {
        "canonical_name": "Toothpaste & Oral Care",
        "category": "Personal Care",
        "standard_unit": "pcs",
        "aliases": [
            "toothpaste", "colgate", "colgate total", "colgate maximum", "sensodyne",
            "sensodyne rapid", "close up", "close-up", "medicam", "aquafresh",
            "toothbrush", "colgate brush", "oral b brush", "miswak", "mouthwash", "listerine"
        ]
    },
    {
        "canonical_name": "Skincare & Lotions",
        "category": "Personal Care",
        "standard_unit": "pcs",
        "aliases": [
            "fair and lovely", "glow and lovely", "nivea cream", "nivea lotion",
            "ponds cream", "ponds face wash", "vaseline", "vaseline petroleum jelly",
            "vaseline lotion", "cold cream", "body lotion", "sunblock", "sunscreen",
            "talcum powder", "prickly heat powder", "dermacool", "tibetan snow"
        ]
    },
    {
        "canonical_name": "Shaving & Grooming",
        "category": "Personal Care",
        "standard_unit": "pcs",
        "aliases": [
            "shaving razor", "gillette razor", "gillette mach 3", "gillette blue 2",
            "shaving blade", "razor blades", "treet blades", "shaving cream", "gillette foam",
            "shaving foam", "shaving gel", "aftershave", "shaving brush"
        ]
    },
    {
        "canonical_name": "Deodorant & Fragrance",
        "category": "Personal Care",
        "standard_unit": "pcs",
        "aliases": [
            "deodorant", "body spray", "axe body spray", "rexona spray", "rexona roll on",
            "fogg spray", "fogg body spray", "brut deodorant", "perfume", "attar", "itr"
        ]
    },
    {
        "canonical_name": "Sanitary & Feminine Hygiene",
        "category": "Personal Care",
        "standard_unit": "pkt",
        "aliases": [
            "sanitary pads", "sanitary napkins", "always pads", "always ultra",
            "butterfly pads", "butterfly breathable", "kotex pads", "feminine hygiene",
            "cotton buds", "q tips", "makeup remover wipes"
        ]
    },
    {
        "canonical_name": "Baby Care & Diapers",
        "category": "Personal Care",
        "standard_unit": "pkt",
        "aliases": [
            "pampers", "pampers diaper", "molfix", "molfix diaper", "canbebe",
            "huggies", "baby wipes", "pampers wipes", "johnsons baby powder",
            "johnsons baby lotion", "johnsons baby shampoo", "baby oil", "baby soap",
            "feeder", "baby feeder", "soother", "pacifier", "gripe water", "woodwards gripe water"
        ]
    },

    # ── HOUSEHOLD & CLEANING (Expanded) ───────────────────────────────────────
    {
        "canonical_name": "Washing Powder / Detergent",
        "category": "Household & Cleaning",
        "standard_unit": "kg",
        "aliases": [
            "surf excel", "surf", "ariel", "ariel washing powder", "bonus tristar",
            "bonus washing powder", "express powder", "wheel powder", "brite powder",
            "detergent powder", "washing powder", "dhobi powder", "surf 1kg", "surf 500g"
        ]
    },
    {
        "canonical_name": "Dishwash Liquid & Soap",
        "category": "Household & Cleaning",
        "standard_unit": "pcs",
        "aliases": [
            "lemon max bar", "lemon max liquid", "lemon max", "max bar", "vim bar",
            "vim liquid", "dishwash bar", "dishwash liquid", "bartan dhone ka sabun",
            "dishwashing soap", "scotch brite", "sponge scrubber", "steel wool"
        ]
    },
    {
        "canonical_name": "Toilet & Floor Cleaner",
        "category": "Household & Cleaning",
        "standard_unit": "pcs",
        "aliases": [
            "harpic", "harpic toilet cleaner", "harpic bathroom", "domex", "dettol floor cleaner",
            "phenyl", "finis phenyl", "floor cleaner", "toilet cleaner", "acid", "cleaner",
            "tile cleaner", "drain opener"
        ]
    },
    {
        "canonical_name": "Fabric Bleach & Conditioners",
        "category": "Household & Cleaning",
        "standard_unit": "pcs",
        "aliases": [
            "clorox bleach", "robin blue", "robin liquid", "comfort conditioner",
            "fabric conditioner", "neel", "whitening bleach"
        ]
    },
    {
        "canonical_name": "Insecticides & Pest Control",
        "category": "Household & Cleaning",
        "standard_unit": "pcs",
        "aliases": [
            "mortein", "mortein spray", "mortein coil", "mortein liquid", "mortein led",
            "kingtox", "kingtox spray", "baygon", "coopex powder", "cockroach gel",
            "mosquito spray", "machhar mar spray", "chontiyan powder", "insect killer"
        ]
    },
    {
        "canonical_name": "Tissue Paper & Paper Towels",
        "category": "Household & Cleaning",
        "standard_unit": "pcs",
        "aliases": [
            "rose petal tissue", "rose petal facial", "tissue box", "tissue roll",
            "toilet roll", "kitchen towel", "paper napkins", "table napkin",
            "pop up tissue", "facial tissue", "wet tissue"
        ]
    },
    {
        "canonical_name": "Foil, Wraps & Trash Bags",
        "category": "Household & Cleaning",
        "standard_unit": "pcs",
        "aliases": [
            "aluminum foil", "aluminium foil", "foil roll", "cling film", "plastic wrap",
            "baking paper", "parchment paper", "garbage bags", "trash bags", "dustbin bags",
            "shopper", "shopping bag"
        ]
    },
    {
        "canonical_name": "Cleaning Tools & Accessories",
        "category": "Household & Cleaning",
        "standard_unit": "pcs",
        "aliases": [
            "broom", "jharoo", "wiper", "floor wiper", "mop", "floor mop", "duster",
            "cleaning cloth", "microfiber cloth", "matchbox", "machis", "lighter", "candle", "mombatti"
        ]
    },
    {
        "canonical_name": "Dining Disposables",
        "category": "Household & Cleaning",
        "standard_unit": "pcs",
        "aliases": [
            "disposable glass", "disposable glasses", "paper cups", "plastic cups",
            "disposable plate", "plastic plates", "plastic spoon", "plastic fork",
            "disposibe gass", "disposibe glass", "thermopore plates"
        ]
    },

    # ── SNACKS & BEVERAGES (Expanded) ─────────────────────────────────────────
    {
        "canonical_name": "Soft Drink",
        "category": "Snacks & Beverages",
        "standard_unit": "pcs",
        "aliases": [
            "pepsi", "pepsi 1.5l", "pepsi 500ml", "coca cola", "coke", "coke 1.5l",
            "sprite", "sprite 1.5l", "7up", "seven up", "mirinda", "fanta", "mountain dew",
            "marinda", "pakola", "pakola soda", "sting", "sting energy", "cold drink",
            "soda bottle", "can 250ml", "tin pack"
        ]
    },
    {
        "canonical_name": "Juices & Nectars",
        "category": "Snacks & Beverages",
        "standard_unit": "pcs",
        "aliases": [
            "nestle fruita vitals", "fruita vitals", "shezan juice", "shezan mango",
            "slice juice", "slice mango", "frooto", "tang", "tang orange", "tang mango",
            "apple juice", "orange juice", "mango juice", "tetra pack juice"
        ]
    },
    {
        "canonical_name": "Traditional Syrups & Squashes",
        "category": "Snacks & Beverages",
        "standard_unit": "pcs",
        "aliases": [
            "rooh afza", "roohafza", "jam e shirin", "jameshiran", "quice syrup",
            "lemon squash", "red syrup", "sharbat"
        ]
    },
    {
        "canonical_name": "Mineral Water",
        "category": "Snacks & Beverages",
        "standard_unit": "pcs",
        "aliases": [
            "mineral water", "water", "aquafina", "nestle water", "nestle pure life",
            "dasani", "sufi water", "drinking water", "mi water", "min water",
            "water 1.5l", "water 500ml", "water 6l", "pani bottle"
        ]
    },
    {
        "canonical_name": "Tea (Chai Patti)",
        "category": "Snacks & Beverages",
        "standard_unit": "pkt",
        "aliases": [
            "tapal danedar", "tapal", "tapal tea", "lipton yellow label", "lipton tea",
            "supreme tea", "brooke bond supreme", "vital tea", "tapal tezdum",
            "chai patti", "tea 430g", "tea 900g", "tea 190g", "black tea",
            "green tea", "tapal green tea", "lipton green tea", "chaye"
        ]
    },
    {
        "canonical_name": "Coffee & Creamer",
        "category": "Snacks & Beverages",
        "standard_unit": "pcs",
        "aliases": [
            "nescafe", "nescafe classic", "nescafe gold", "instant coffee",
            "coffee jar", "coffee sachet", "coffee mate", "everyday creamer"
        ]
    },
    {
        "canonical_name": "Potato Chips & Crisps",
        "category": "Snacks & Beverages",
        "standard_unit": "pkt",
        "aliases": [
            "lays chips", "lays", "lays masala", "lays french cheese", "lays salted",
            "kurkure", "kurkure chutney chaska", "cheetos", "cheetos bites", "kurleez",
            "pringles", "chips", "crisps", "potato crisps", "wafers"
        ]
    },
    {
        "canonical_name": "Biscuits & Cookies",
        "category": "Snacks & Beverages",
        "standard_unit": "pkt",
        "aliases": [
            "sooper biscuits", "sooper", "tuc crackers", "tuc", "prince biscuits",
            "rio biscuits", "gala biscuits", "chocolatto", "marie biscuits",
            "wheatable", "zeera plus", "gluco biscuits", "bakeri biscuits", "biscotti",
            "biscuits", "cookies", "biskut"
        ]
    },
    {
        "canonical_name": "Chocolates & Candies",
        "category": "Snacks & Beverages",
        "standard_unit": "pcs",
        "aliases": [
            "dairy milk", "cadbury dairy milk", "kitkat", "snickers", "mars",
            "perk", "bounty", "candyland", "eclairs", "ding dong bubble",
            "chocolate", "toffees", "candies", "goli toffee"
        ]
    },
    {
        "canonical_name": "Nimko & Savory Snacks",
        "category": "Snacks & Beverages",
        "standard_unit": "pkt",
        "aliases": [
            "nimko", "daal moth", "daal sev", "chevda", "slims", "peanuts",
            "salted peanuts", "fried daal", "chana nimko", "mix nimko"
        ]
    },

    # ── GROCERIES & FOOD (Expanded Staples, Produce, Dairy, Meat) ─────────────
    {
        "canonical_name": "Melons & Watermelons",
        "category": "Groceries & Food",
        "standard_unit": "kg",
        "aliases": [
            "sweet melon", "mitha", "mitha per kg", "witha", "witha per kg",
            "kharbooza", "melon", "sarda", "garma", "tarbooz", "watermelon"
        ]
    },
    {
        "canonical_name": "Spinach & Greens (Palak)",
        "category": "Groceries & Food",
        "standard_unit": "kg",
        "aliases": [
            "spinach", "palak", "spinach per kg", "spnch", "spnch per kg",
            "sarson saag", "saag", "methi patta", "greens"
        ]
    },
    {
        "canonical_name": "Traditional Breads (Naan & Roti)",
        "category": "Groceries & Food",
        "standard_unit": "pcs",
        "aliases": [
            "naan", "roti", "rot", "roti naan", "roghni naan", "khamiri roti",
            "kulcha", "paratha", "puri", "sheermal", "taftan", "tandoori roti", "chapati"
        ]
    },
    {
        "canonical_name": "Cooked Nihari & Traditional Stews",
        "category": "Groceries & Food",
        "standard_unit": "plate",
        "aliases": [
            "nihari", "nihari single", "nihari double", "nalli nihari", "maghaz nihari",
            "special nihari", "javed nihari", "haleem", "chicken haleem", "beef haleem",
            "paya", "siri paya", "kunna"
        ]
    },
    {
        "canonical_name": "Instant Noodles & Pasta",
        "category": "Groceries & Food",
        "standard_unit": "pkt",
        "aliases": [
            "maggi noodles", "knorr noodles", "shoop noodles", "indomie",
            "noodles", "instant noodles", "macaroni", "bake parlor macaroni",
            "kolson macaroni", "spaghetti", "pasta"
        ]
    },
    {
        "canonical_name": "Sauces & Tomato Ketchup",
        "category": "Groceries & Food",
        "standard_unit": "pcs",
        "aliases": [
            "tomato ketchup", "national ketchup", "shangrila ketchup", "mitchells ketchup",
            "chilli garlic sauce", "chili garlic", "hot sauce", "soya sauce", "soy sauce",
            "vinegar", "sirkah", "chilli sauce"
        ]
    },
    {
        "canonical_name": "Mayonnaise & Spreads",
        "category": "Groceries & Food",
        "standard_unit": "pcs",
        "aliases": [
            "mayonnaise", "youngs mayonnaise", "knorr mayonnaise", "garlic mayo",
            "mayo", "peanut butter", "hazelnut spread", "nutella", "jam", "mixed fruit jam"
        ]
    },
    {
        "canonical_name": "Dessert & Pudding Mixes",
        "category": "Groceries & Food",
        "standard_unit": "pkt",
        "aliases": [
            "rafhan custard", "custard powder", "kheer mix", "laziza kheer mix",
            "jelly crystals", "rafhan jelly", "falooda mix", "laziza falooda", "gulab jamun mix"
        ]
    },
    {
        "canonical_name": "Dry Fruits & Nuts",
        "category": "Groceries & Food",
        "standard_unit": "kg",
        "aliases": [
            "badaam", "almonds", "pista", "pistachio", "kaju", "cashew",
            "akhrot", "walnut", "kismis", "raisins", "khajoor", "dates",
            "aseel khajoor", "irb khajoor", "dry fruit"
        ]
    }
]

# Merge into taxonomy_map
for item in ADDITIONAL_OR_UPDATED_ITEMS:
    canon = item["canonical_name"]
    if canon in taxonomy_map:
        # Merge aliases
        existing_aliases = set(taxonomy_map[canon].get("aliases", []))
        for a in item.get("aliases", []):
            existing_aliases.add(a.lower())
        taxonomy_map[canon]["aliases"] = sorted(list(existing_aliases))
        taxonomy_map[canon]["category"] = item["category"]
        taxonomy_map[canon]["standard_unit"] = item["standard_unit"]
    else:
        taxonomy_map[canon] = item

final_taxonomy = list(taxonomy_map.values())
final_taxonomy.sort(key=lambda x: (x["category"], x["canonical_name"]))

out_path = Path(r"c:\Users\Asad\Desktop\ReceiptLedger\data\local_taxonomy.json")
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(final_taxonomy, f, indent=2, ensure_ascii=False)

print(f"Taxonomy successfully expanded to {len(final_taxonomy)} entries in {out_path}!")
