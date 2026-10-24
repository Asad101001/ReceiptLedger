import json
from pathlib import Path

TAXONOMY = [
  # ─────────────────────────────────────────────────────────────────────────
  # FLOUR, GRAINS & RICE
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Wheat Flour (Atta)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "atta", "chakki atta", "fine atta", "flour", "chki ata", "ata",
      "wheat flour", "aata", "chakki aata", "gehun atta", "safaid atta",
      "rozana atta", "sunehri atta", "whole wheat flour", "ashirwad atta",
      "sunridge atta", "deshi atta", "lal atta", "wheat flr", "flr atta",
      "wheat flour 10kg", "atta 10kg", "atta 5kg", "chakki flr"
    ]
  },
  {
    "canonical_name": "All Purpose Flour (Maida)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "maida", "all purpose flour", "fine maida", "white flour",
      "super maida", "baking flour", "plain flour", "refined wheat flour",
      "pastry flour", "maida 1kg", "maida 500g"
    ]
  },
  {
    "canonical_name": "Semolina (Suji)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "suji", "sooji", "semolina", "rawa", "rawa flour", "coarse semolina",
      "suji halwa", "fine suji", "sooji 500g", "suji 1kg"
    ]
  },
  {
    "canonical_name": "Gram Flour (Besan)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "besan", "baisan", "gram flour", "chickpea flour", "chana flour",
      "pure besan", "chana atta", "besan 1kg", "besan 500g", "pakora besan"
    ]
  },
  {
    "canonical_name": "Corn Flour & Starch",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "corn flour", "cornflour", "corn starch", "cornstarch", "makai atta",
      "rafhan corn flour", "maize starch", "makki ka atta"
    ]
  },
  {
    "canonical_name": "Basmati Rice",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "rice", "basmati", "basmati rice", "chawal", "sela rice", "irri rice", "super basmati",
      "kainat rice", "guard rice", "kernel basmati", "long grain rice", "sela chawal",
      "white rice", "brown rice", "falak rice", "al kabeer rice", "mughal rice",
      "1121 rice", "kainat 1121", "tota chawal", "broken rice", "khichdi rice",
      "steamed rice", "parboiled rice", "basmati chawal", "super kernel", "jasmine rice"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # COOKING OILS & GHEE
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Cooking Oil",
    "category": "Groceries & Food",
    "standard_unit": "ltr",
    "aliases": [
      "oil", "cooking oil", "dalda", "habib oil", "canola oil", "sunflower oil",
      "vegetable oil", "corn oil", "sufi oil", "mezan oil", "eva oil",
      "kisan oil", "olive oil", "tel", "khana tel", "mustard oil", "sarson ka tel",
      "cokin oil", "cokin on", "coking oil", "cokin", "cookinon oil", "cookinon",
      "dalda cooking oil", "habib canola", "sufi canola", "mezan canola",
      "eva cooking oil", "extra virgin olive oil", "pomace olive oil", "soybean oil",
      "sarson tel", "zaitoon tel", "cooking oil 1l", "cooking oil 5l", "oil pouch", "oil tin"
    ]
  },
  {
    "canonical_name": "Banaspati Ghee",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "ghee", "banaspati ghee", "dalda ghee", "habib ghee", "sufi ghee", "mezan ghee",
      "tullo ghee", "kisan ghee", "vanaspati", "banaspati", "vegetable ghee",
      "ghee 1kg", "ghee pouch", "ghee tin", "dalda banaspati"
    ]
  },
  {
    "canonical_name": "Desi Ghee",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "desi ghee", "deshi ghee", "asli ghee", "pure desi ghee", "cow desi ghee",
      "buffalo desi ghee", "organic desi ghee", "nurpur desi ghee", "punjab pure ghee",
      "clarified butter", "desi ghee 1kg", "desi ghee 500g"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # SUGAR, SWEETENERS & SALT
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Sugar",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "sugar", "cheeni", "chini", "shakar", "white sugar", "refined sugar",
      "cane sugar", "crystal sugar", "castor sugar", "brown sugar", "icing sugar",
      "bura cheeni", "sugar 1kg", "cheeni 1kg", "cheeni 5kg", "sugar 5kg"
    ]
  },
  {
    "canonical_name": "Jaggery & Raw Sugar (Gur)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "gur", "gurr", "jaggery", "desi gur", "shakar gur", "organic jaggery",
      "masala gur", "gur shakkar", "shakkar", "brown cane sugar"
    ]
  },
  {
    "canonical_name": "Artificial Sweetener",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "canderel", "equal", "stevia", "sweetener", "sugar free", "diet sweetener",
      "zero calorie sweetener", "canderel tablets", "canderel powder"
    ]
  },
  {
    "canonical_name": "Salt",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "salt", "namak", "iodized salt", "pink salt", "himalayan salt",
      "rock salt", "sea salt", "table salt", "lahori namak", "national salt",
      "kala namak", "black salt", "coarse salt", "refined salt", "national iodized salt",
      "shan salt", "himalayan pink salt 800g"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # PULSES & LENTILS (DAAL / DAL)
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Split Bengal Gram (Daal Chana)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "dal chana", "daal chana", "chana dal", "chana daal", "split bengal gram",
      "yellow dal", "daal chana 1kg", "dal chana 1kg", "deal chana", "deal"
    ]
  },
  {
    "canonical_name": "Red Lentils (Daal Masoor)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "dal masoor", "daal masoor", "masoor dal", "masoor daal", "red lentils",
      "masoor dhuli", "sabut masoor", "whole masoor", "orange lentils", "daal masoor 1kg"
    ]
  },
  {
    "canonical_name": "Yellow & Green Moong (Daal Moong)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "dal moong", "daal moong", "moong dal", "moong daal", "yellow moong",
      "moong dhuli", "moong chhilka", "sabut moong", "green gram", "daal moong 1kg"
    ]
  },
  {
    "canonical_name": "Black & White Gram (Daal Mash)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "dal mash", "daal mash", "mash dal", "mash daal", "urad dal", "urad daal",
      "mash dhuli", "mash chhilka", "black gram", "white urad", "daal mash 1kg"
    ]
  },
  {
    "canonical_name": "Pigeon Pea (Daal Toor / Arhar)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "dal toor", "daal toor", "toor dal", "toor daal", "arhar dal", "arhar daal",
      "pigeon pea", "yellow toor"
    ]
  },
  {
    "canonical_name": "White Chickpeas (Safaid Chana)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "safaid chana", "safed chana", "white chickpeas", "kabuli chana", "chickpeas",
      "chana", "safaid channa", "chole", "garbanzo beans", "kabuli channa", "white chana"
    ]
  },
  {
    "canonical_name": "Black Chickpeas (Kala Chana)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "kala chana", "black chana", "black chickpeas", "desi chana", "brown chickpeas",
      "kala channa"
    ]
  },
  {
    "canonical_name": "Kidney Beans (Lobia / Rajma)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "lobia", "safaid lobia", "lal lobia", "white lobia", "red lobia",
      "rajma", "red kidney beans", "kidney beans", "black eyed beans", "black eyed peas"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # SPICES & RECIPE MIXES
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Cumin Seeds & Powder (Zeera)",
    "category": "Groceries & Food",
    "standard_unit": "g",
    "aliases": [
      "zeera", "safaid zeera", "white cumin", "cumin", "cumin seeds",
      "zeera powder", "kala zeera", "black cumin", "cumin powder", "sabut zeera"
    ]
  },
  {
    "canonical_name": "Red Chilli & Flakes (Lal Mirch)",
    "category": "Groceries & Food",
    "standard_unit": "g",
    "aliases": [
      "lal mirch", "red chilli", "chilli powder", "red chilli powder", "lal mirch powder",
      "kuti lal mirch", "chilli flakes", "crushed chilli", "kashmiri mirch", "degi mirch",
      "sabut lal mirch", "whole red chilli"
    ]
  },
  {
    "canonical_name": "Turmeric (Haldi)",
    "category": "Groceries & Food",
    "standard_unit": "g",
    "aliases": [
      "haldi", "turmeric", "turmeric powder", "haldi powder", "pisi haldi",
      "sabut haldi", "whole turmeric"
    ]
  },
  {
    "canonical_name": "Coriander Seeds & Powder (Dhania)",
    "category": "Groceries & Food",
    "standard_unit": "g",
    "aliases": [
      "dhaniya", "dhania", "coriander powder", "dhaniya powder", "dhania powder",
      "sabut dhania", "sabut dhaniya", "coriander seeds", "sukha dhania"
    ]
  },
  {
    "canonical_name": "Black Pepper (Kali Mirch)",
    "category": "Groceries & Food",
    "standard_unit": "g",
    "aliases": [
      "kali mirch", "black pepper", "black pepper powder", "kali mirch powder",
      "sabut kali mirch", "peppercorn", "black peppercorns"
    ]
  },
  {
    "canonical_name": "Garam Masala",
    "category": "Groceries & Food",
    "standard_unit": "g",
    "aliases": [
      "garam masala", "garam masala powder", "sabut garam masala", "pisa garam masala",
      "all spice", "mixed whole spices"
    ]
  },
  {
    "canonical_name": "Whole Spices & Aromatics",
    "category": "Groceries & Food",
    "standard_unit": "g",
    "aliases": [
      "ilaichi", "elaichi", "chhoti elaichi", "green cardamom", "badi elaichi",
      "black cardamom", "daarchini", "darchini", "cinnamon", "cinnamon sticks",
      "laung", "cloves", "badiyan", "star anise", "jaifil", "javitri", "nutmeg",
      "mace", "tez paat", "bay leaves", "ajwain", "carom seeds", "methi dana",
      "fenugreek seeds", "kalonji", "nigella seeds", "saunf", "fennel seeds", "kasuri methi"
    ]
  },
  {
    "canonical_name": "Chaat Masala",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "chaat masala", "chat masala", "national chaat masala", "shan chaat masala",
      "fruit chaat masala", "dahi bara masala"
    ]
  },
  {
    "canonical_name": "Biryani Recipe Mix",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "biryani masala", "shan biryani masala", "national biryani masala", "bombay biryani",
      "sindhi biryani", "biryani mix", "chicken biryani masala", "beef biryani masala",
      "pulao biryani masala", "shan bombay biryani", "national bombay biryani"
    ]
  },
  {
    "canonical_name": "Curry & Meat Recipe Mix",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "qorma masala", "korma masala", "karahi masala", "nihari masala",
      "haleem mix", "haleem masala", "paya masala", "achar gosht masala",
      "kofta masala", "shan korma", "national karahi", "shan nihari",
      "kunna masala", "handi masala", "white karahi masala"
    ]
  },
  {
    "canonical_name": "BBQ & Tikka Recipe Mix",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "tikka masala", "chicken tikka masala", "seekh kabab masala", "chapli kabab masala",
      "fish masala", "tandoori masala", "bihari kabab masala", "malai boti masala",
      "shan tikka", "national tikka"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # FRESH VEGETABLES (SABZI)
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Potatoes (Aloo)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "potatoes", "aloo", "alu", "potato", "fresh potatoes", "baby potatoes",
      "new potatoes", "sweet potato", "shakarkandi", "aloo 1kg"
    ]
  },
  {
    "canonical_name": "Onions (Pyaz)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "onions", "pyaz", "piaz", "onion", "red onion", "white onion",
      "dried onion", "spring onion", "fresh onion", "pyaz 1kg"
    ]
  },
  {
    "canonical_name": "Tomatoes (Tamatar)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "tomatoes", "tamatar", "tomato", "fresh tomatoes", "cherry tomatoes",
      "red tomatoes", "tamatar 1kg"
    ]
  },
  {
    "canonical_name": "Ginger & Garlic",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "adrak", "lehsan", "lehsun", "ginger", "garlic", "adrak lehsan",
      "ginger garlic", "ginger garlic paste", "fresh ginger", "fresh garlic",
      "peeled garlic", "adrak paste", "lehsan paste"
    ]
  },
  {
    "canonical_name": "Fresh Herbs & Chillies",
    "category": "Groceries & Food",
    "standard_unit": "g",
    "aliases": [
      "hari mirch", "green chilli", "green chillies", "hara dhania", "kothmir",
      "fresh coriander", "pudina", "fresh mint", "curry patta", "curry leaves"
    ]
  },
  {
    "canonical_name": "Spinach & Greens (Palak)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "spinach", "palak", "fresh spinach", "spinach per kg", "desi palak",
      "saag", "sarson ka saag", "mustard greens", "fresh methi", "bathua"
    ]
  },
  {
    "canonical_name": "Cauliflower & Cabbage (Gobhi)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "gobhi", "phool gobhi", "cauliflower", "band gobhi", "patta gobhi",
      "cabbage", "chinese cabbage", "broccoli"
    ]
  },
  {
    "canonical_name": "Capsicum & Bell Peppers",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "shimla mirch", "shimla", "capsicum", "bell pepper", "green capsicum",
      "red capsicum", "yellow bell pepper"
    ]
  },
  {
    "canonical_name": "Okra & Eggplant (Bhindi & Baingan)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "bhindi", "okra", "lady finger", "fresh bhindi", "baingan", "eggplant",
      "brinjal", "aubergine", "gol baingan", "lambey baingan"
    ]
  },
  {
    "canonical_name": "Gourds & Summer Veg",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "karela", "bitter gourd", "lauki", "kaddu", "bottle gourd", "tori", "turai",
      "ridge gourd", "ghia", "tinda", "arvi", "colocasia", "zucchini"
    ]
  },
  {
    "canonical_name": "Carrots, Radish & Turnips",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "gajar", "carrot", "red carrot", "fresh carrots", "mooli", "radish",
      "white radish", "shalgam", "turnip", "beetroot", "chukandar"
    ]
  },
  {
    "canonical_name": "Green Peas (Matar)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "matar", "green peas", "fresh peas", "shelled peas", "frozen peas",
      "phaliyan", "french beans", "green beans"
    ]
  },
  {
    "canonical_name": "Cucumbers & Lemons",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "kheera", "cucumber", "fresh cucumber", "kakdi", "lemon", "lemun",
      "nimbu", "lime", "fresh lemon", "desi lemun"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # FRESH FRUITS (PHAL)
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Bananas (Kela)",
    "category": "Groceries & Food",
    "standard_unit": "dzn",
    "aliases": [
      "banana", "bananas", "kela", "kele", "dozen banana", "fresh banana",
      "sindhi kela", "dhakka kela"
    ]
  },
  {
    "canonical_name": "Apples (Seb)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "apple", "apples", "seb", "red apple", "green apple", "kala kulu",
      "gacha apple", "golden apple", "fresh apple"
    ]
  },
  {
    "canonical_name": "Mangoes (Aam)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "mango", "mangoes", "aam", "chaunsa", "sindhri", "anwar ratol",
      "langra", "dussehri", "white chaunsa", "fresh mango"
    ]
  },
  {
    "canonical_name": "Melons & Watermelons",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "sweet melon", "mitha", "mitha per kg", "kharbooza", "melon",
      "cantaloupe", "sarda", "garma", "tarbooz", "watermelon",
      "fresh melon", "red watermelon"
    ]
  },
  {
    "canonical_name": "Citrus & Oranges",
    "category": "Groceries & Food",
    "standard_unit": "dzn",
    "aliases": [
      "orange", "oranges", "kinnow", "kinnu", "malta", "mosambi",
      "sweet orange", "red blood orange", "grapefruit", "fruiter"
    ]
  },
  {
    "canonical_name": "Pomegranates & Grapes",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "anaar", "anar", "pomegranate", "qandhari anaar", "bedana anaar",
      "angoor", "grapes", "green grapes", "sundarkhani grapes", "black grapes"
    ]
  },
  {
    "canonical_name": "Guava & Papaya",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "amrood", "guava", "safaid amrood", "papita", "papaya", "fresh papaya"
    ]
  },
  {
    "canonical_name": "Peaches, Plums & Apricots",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "aarrh", "peach", "fresh peach", "aloo bukhara", "plum", "fresh plum",
      "khubani", "apricot", "nashpati", "pear", "babu gosha"
    ]
  },
  {
    "canonical_name": "Dates (Khajoor)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "khajoor", "dates", "aseel khajoor", "ajwa", "ajwa dates", "medjool",
      "irani khajoor", "mabroom", "kalmi", "khajoor 500g"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # DAIRY & EGGS
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Milk",
    "category": "Groceries & Food",
    "standard_unit": "ltr",
    "aliases": [
      "milk", "doodh", "milk pack", "whole milk", "fresh milk", "nestle milk", "olper milk",
      "haleeb milk", "good milk", "dairy milk", "skimmed milk", "tetra pack milk",
      "uht milk", "pasteurized milk", "olpers", "milkpak", "tarang", "tea whitener",
      "tea max", "everyday", "nestle everyday", "doodh 1l", "khula doodh", "cow milk"
    ]
  },
  {
    "canonical_name": "Yogurt (Dahi)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "yogurt", "dahi", "curd", "plain yogurt", "fresh dahi", "set yogurt",
      "low fat yogurt", "milk yogurt", "packaged dahi", "nestle dahi",
      "yogurt 500g", "yoourt 500g", "yoourt", "meetha dahi", "raita dahi"
    ]
  },
  {
    "canonical_name": "Butter",
    "category": "Groceries & Food",
    "standard_unit": "g",
    "aliases": [
      "butter", "makhan", "unsalted butter", "salted butter", "lurpak",
      "country butter", "table butter", "nurpur butter", "adams butter",
      "butter 200g", "putter 200g", "putter", "blue band", "margarine"
    ]
  },
  {
    "canonical_name": "Dairy Cream",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "cream", "dairy cream", "olpers cream", "milkpak cream", "fresh cream",
      "whipping cream", "heavy cream", "tetra pack cream", "nestle cream", "haleeb cream"
    ]
  },
  {
    "canonical_name": "Cheese & Paneer",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "cheese", "cheddar cheese", "mozzarella cheese", "adams cheese", "happy cow",
      "paneer", "cottage cheese", "cheese slices", "puck cheese", "cream cheese",
      "pizza cheese", "almarai cheese"
    ]
  },
  {
    "canonical_name": "Eggs",
    "category": "Groceries & Food",
    "standard_unit": "dzn",
    "aliases": [
      "eggs", "anda", "andey", "dozen eggs", "farm eggs", "brown eggs",
      "white eggs", "organic eggs", "egg tray", "desi andey", "eggs 1 dozen",
      "anday 1dz", "bay 1 dozen", "egg", "anday", "egg crate", "eggs tray"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # BAKERY & BREADS
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Bread",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "bread", "double roti", "toast bread", "white bread", "brown bread",
      "sandwich bread", "dawn bread", "wonder bread", "bake parlor bread",
      "bread large", "bread small", "bran bread", "milky bread", "multigrain bread"
    ]
  },
  {
    "canonical_name": "Buns & Rolls",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "burger bun", "burger buns", "hot dog buns", "dinner rolls", "pav", "pao",
      "sweet buns", "dawn buns", "sandwich bun", "slider buns"
    ]
  },
  {
    "canonical_name": "Traditional Breads (Naan & Roti)",
    "category": "Groceries & Food",
    "standard_unit": "pcs",
    "aliases": [
      "roti", "naan", "tandoori roti", "roghani naan", "khamiri roti", "chapati",
      "sheermal", "taftan", "paratha", "puri", "garlic naan", "cheese naan",
      "plain naan", "kulcha", "poori"
    ]
  },
  {
    "canonical_name": "Rusk & Bakery Snacks",
    "category": "Snacks & Beverages",
    "standard_unit": "pkt",
    "aliases": [
      "rusk", "cake rusk", "plain rusk", "zeera rusk", "nankhatai", "nan khatai",
      "bakery biscuits", "khatai", "bakery patties", "chicken patties", "beef patties",
      "vegetable patties", "samosa", "samosay", "spring roll", "chicken roll"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # MEAT, POULTRY & SEAFOOD
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Chicken Meat",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "chicken", "murgh", "murghi", "broiler chicken", "farm chicken", "whole chicken",
      "chicken pieces", "chicken breast", "chicken legs", "boneless chicken",
      "tikka pieces", "karahi chicken", "chicken mince", "desi murgh",
      "chicken karahi cut", "chicken drumsticks", "chicken wings", "chicken boti"
    ]
  },
  {
    "canonical_name": "Mutton & Goat Meat",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "mutton", "gosht", "lamb", "goat meat", "bakra gosht", "baqra gosht",
      "mutton chops", "chaamp", "mutton raan", "mutton dasti", "mutton mix",
      "mutton karahi cut", "desi gosht"
    ]
  },
  {
    "canonical_name": "Beef & Veal",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "beef", "bada gosht", "cow meat", "veal", "pasanday", "bong",
      "nihari gosht", "beef boti", "beef undercut", "beef bone marrow",
      "haddi guddi", "beef paya", "beef paye"
    ]
  },
  {
    "canonical_name": "Minced Meat (Qeema)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "qeema", "keema", "mince", "beef qeema", "chicken qeema", "mutton qeema",
      "beef mince", "chicken mince", "mutton mince", "qeema machine", "hath ka qeema"
    ]
  },
  {
    "canonical_name": "Fish & Seafood",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "fish", "machli", "rahu", "rahoo", "pomfret", "paplet", "surmai",
      "finger fish", "boneless fish", "mushka", "sea fish", "river fish",
      "jheenga", "prawns", "shrimp", "tiger prawns"
    ]
  },
  {
    "canonical_name": "Frozen Ready-to-Cook",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "nuggets", "chicken nuggets", "k&n", "k&ns", "dawn frozen", "menu frozen",
      "sabroso", "seekh kabab", "shami kabab", "sausages", "burger patties",
      "dawn paratha", "plain paratha", "sufi nuggets", "mon salwa", "chicken poppers"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # SAUCES, CONDIMENTS & SPREADS
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Tomato Ketchup",
    "category": "Groceries & Food",
    "standard_unit": "bottle",
    "aliases": [
      "ketchup", "tomato ketchup", "tomato sauce", "national ketchup",
      "shangrila ketchup", "mitchells ketchup", "heinz ketchup",
      "ketchup pouch", "ketchup 500g", "ketchup 1kg"
    ]
  },
  {
    "canonical_name": "Chilli Garlic & Hot Sauces",
    "category": "Groceries & Food",
    "standard_unit": "bottle",
    "aliases": [
      "chili garlic sauce", "chilli garlic sauce", "chilli garlic",
      "garlic sauce", "hot sauce", "shangrila chilli garlic", "national chilli garlic",
      "sriracha", "habanero sauce"
    ]
  },
  {
    "canonical_name": "Mayonnaise",
    "category": "Groceries & Food",
    "standard_unit": "bottle",
    "aliases": [
      "mayonnaise", "mayo", "youngs mayo", "youngs mayonnaise", "national mayonnaise",
      "garlic mayo", "mayo pouch", "mayo 1kg", "mayo 500g"
    ]
  },
  {
    "canonical_name": "Soya Sauce & Vinegar",
    "category": "Groceries & Food",
    "standard_unit": "bottle",
    "aliases": [
      "soya sauce", "soy sauce", "vinegar", "sirka", "synthetic vinegar",
      "white vinegar", "apple cider vinegar", "dark soy sauce", "shangrila vinegar"
    ]
  },
  {
    "canonical_name": "Pickles (Achar)",
    "category": "Groceries & Food",
    "standard_unit": "jar",
    "aliases": [
      "achar", "pickles", "pickle", "mixed achar", "mango achar", "aam ka achar",
      "lemon achar", "green chilli achar", "national achar", "shan achar",
      "mitchells achar", "ahmed achar", "hyderabadi achar"
    ]
  },
  {
    "canonical_name": "Jam, Marmalade & Honey",
    "category": "Groceries & Food",
    "standard_unit": "jar",
    "aliases": [
      "jam", "apple jam", "mango jam", "mixed fruit jam", "mitchells jam", "shezan jam",
      "honey", "shehad", "marhaba honey", "langnese honey", "salman honey", "marmalade",
      "peanut butter", "chocolate spread", "nutella", "hazelnut spread"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # PASTA, NOODLES & CEREALS
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Pasta & Macaroni",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "macaroni", "pasta", "spaghetti", "kolson macaroni", "bake parlor macaroni",
      "lasagna", "penne pasta", "fusilli", "elbow macaroni", "spiral macaroni"
    ]
  },
  {
    "canonical_name": "Instant Noodles",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "noodles", "maggi", "maggi noodles", "knorr noodles", "shoop noodles",
      "chatpatta noodles", "chicken noodles", "indomie", "ramen", "instant noodles"
    ]
  },
  {
    "canonical_name": "Breakfast Cereals & Oats",
    "category": "Groceries & Food",
    "standard_unit": "pkt",
    "aliases": [
      "cornflakes", "fauji cornflakes", "kelloggs cornflakes", "quaker oats",
      "oats", "oatmeal", "dalia", "wheat porridge", "chocos"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # TEA, COFFEE & BEVERAGES
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Tea (Chai Patti)",
    "category": "Snacks & Beverages",
    "standard_unit": "g",
    "aliases": [
      "tea", "chai patti", "chay pati", "pati", "chai", "lipton tea", "tapal tea",
      "supreme tea", "brooke bond tea", "danedar", "tapal danedar", "tez dum tea",
      "black tea", "loose tea", "tea bags", "vital tea", "isb tea", "tate tea",
      "tapal", "lipton yellow label", "danedar 450g", "danedar 950g", "tea bag 100"
    ]
  },
  {
    "canonical_name": "Green Tea & Herbal Tea",
    "category": "Snacks & Beverages",
    "standard_unit": "pkt",
    "aliases": [
      "green tea", "kehwa", "kahwa", "jasmine green tea", "lemon green tea",
      "mint green tea", "tapal green tea", "lipton green tea", "peshawari kahwa"
    ]
  },
  {
    "canonical_name": "Coffee",
    "category": "Snacks & Beverages",
    "standard_unit": "jar",
    "aliases": [
      "coffee", "nescafe", "instant coffee", "classic coffee", "gold coffee",
      "cappuccino", "cold coffee", "coffee sachet", "espresso", "nescafe classic",
      "nescafe gold", "3 in 1 coffee"
    ]
  },
  {
    "canonical_name": "Soft Drink",
    "category": "Snacks & Beverages",
    "standard_unit": "ltr",
    "aliases": [
      "soft drink", "cola", "pepsi", "coke", "coca cola", "7up", "sprite",
      "mountain dew", "fanta", "miranda", "mirinda", "rc cola", "drink",
      "soda", "dew", "7 up", "pakola", "shandy", "marinda", "sting",
      "sting energy drink", "red bull", "diet coke", "coke zero", "pepsi max",
      "can", "drink can", "pepsi 1.5l", "coke 1.5l", "7up 1.5l", "sprite 1.5l"
    ]
  },
  {
    "canonical_name": "Juice & Syrups",
    "category": "Snacks & Beverages",
    "standard_unit": "ltr",
    "aliases": [
      "juice", "fruit juice", "mango juice", "nestle juice", "shezan juice",
      "country pure juice", "fresh juice", "tropicana", "minute maid",
      "orange juice", "apple juice", "rooh afza", "jam e shirin", "tang",
      "fruit drink", "slice juice", "frooto", "juice 1l", "juice 1 ltr",
      "fruita vitals", "chaunsa juice", "quice", "mitchells squash"
    ]
  },
  {
    "canonical_name": "Mineral Water",
    "category": "Snacks & Beverages",
    "standard_unit": "ltr",
    "aliases": [
      "mineral water", "water", "aquafina", "nestle water", "dasani", "sufi water",
      "pure life", "drinking water", "bottled water", "water 1.5l", "water 500ml",
      "water bottle", "nestle pure life", "spring water"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # SNACKS, BISCUITS & CONFECTIONERY
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Biscuits & Cookies",
    "category": "Snacks & Beverages",
    "standard_unit": "pkt",
    "aliases": [
      "biscuits", "biscuit", "cookies", "rio biscuits", "peek freans",
      "oreo", "marie biscuits", "prince biscuits", "digestive", "cracker",
      "saltine", "sooper", "tictac", "cup cake", "pound cake", "fruit cake",
      "tuc", "tuc biscuits", "tuc crackers", "gala biscuits", "wheatables",
      "butter puff", "zeera plus", "nan khatai biscuits", "chocolicious"
    ]
  },
  {
    "canonical_name": "Potato Chips & Crisps",
    "category": "Snacks & Beverages",
    "standard_unit": "pkt",
    "aliases": [
      "chips", "lays", "kurkure", "wavy", "cheetos", "nimco", "slims",
      "popcorn", "super crisp", "kolson slanty", "slanty", "oye hoye",
      "lays french cheese", "lays masala", "potato sticks"
    ]
  },
  {
    "canonical_name": "Savory Nimco & Dry Fruits",
    "category": "Snacks & Beverages",
    "standard_unit": "pkt",
    "aliases": [
      "nimco", "daal moth", "sev", "mixed nimco", "chewra", "peanuts",
      "salted peanuts", "moongphali", "kaju", "cashews", "badam", "almonds",
      "pista", "pistachio", "akhrot", "walnuts", "chana nimco"
    ]
  },
  {
    "canonical_name": "Chocolates & Candies",
    "category": "Snacks & Beverages",
    "standard_unit": "pcs",
    "aliases": [
      "chocolate", "dairy milk", "kitkat", "snickers", "mars", "cocomo",
      "candyland", "toffee", "gantt", "bubble gum", "bounty", "perk",
      "chilli milli", "fanty", "ding dong", "eclairs"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # HOUSEHOLD & CLEANING
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Washing Powder / Detergent",
    "category": "Household & Cleaning",
    "standard_unit": "kg",
    "aliases": [
      "washing powder", "detergent", "surf excel", "ariel", "tide",
      "bonus", "brite", "express powder", "cap", "rin", "wheel",
      "washing liquid", "laundry powder", "kapra dhone ka powder",
      "detergent powder", "surf", "excel", "bonus tristar", "ariel 1kg", "surf 1kg"
    ]
  },
  {
    "canonical_name": "Fabric Care & Bleach",
    "category": "Household & Cleaning",
    "standard_unit": "bottle",
    "aliases": [
      "bleach", "robin bleach", "robin blue", "neel", "clorox", "fabric conditioner",
      "comfort", "comfort fabric softener", "stain remover", "vanish"
    ]
  },
  {
    "canonical_name": "Dishwash Liquid & Soap",
    "category": "Household & Cleaning",
    "standard_unit": "ml",
    "aliases": [
      "dishwash", "dish wash", "vim", "pril", "fairy", "dishwashing liquid",
      "dish soap", "bartan saaf", "dish cleaner", "max dishwash", "lemon max",
      "lemon max bar", "lemon max liquid", "vim bar"
    ]
  },
  {
    "canonical_name": "Toilet & Floor Cleaner",
    "category": "Household & Cleaning",
    "standard_unit": "ml",
    "aliases": [
      "toilet cleaner", "harpic", "lavatory cleaner", "bathroom cleaner",
      "flush cleaner", "toilet gel", "commode cleaner", "phenyl", "finis",
      "floor cleaner", "dettol liquid", "dettol surface cleaner", "colin",
      "glass cleaner", "finis phenyl"
    ]
  },
  {
    "canonical_name": "Insecticide & Pest Control",
    "category": "Household & Cleaning",
    "standard_unit": "can",
    "aliases": [
      "mortein", "kingtox", "mosquito spray", "insect spray", "coopex",
      "pest killer", "cockroach spray", "mosquito coil", "mortein led",
      "baygon", "coopex powder"
    ]
  },
  {
    "canonical_name": "Tissue Paper & Paper Towels",
    "category": "Household & Cleaning",
    "standard_unit": "pkt",
    "aliases": [
      "tissue", "tissues", "rose petal", "face tissue", "kitchen towel",
      "toilet paper", "napkins", "party napkins", "soft tissue",
      "tissue box", "rose petal maxob", "pop up tissue", "toilet roll"
    ]
  },
  {
    "canonical_name": "Packaging Wraps & Garbage Bags",
    "category": "Household & Cleaning",
    "standard_unit": "roll",
    "aliases": [
      "aluminium foil", "foil", "cling film", "butter paper", "garbage bags",
      "trash bags", "dustbin bags", "baking paper"
    ]
  },
  {
    "canonical_name": "Matches & Candles",
    "category": "Household & Cleaning",
    "standard_unit": "pkt",
    "aliases": [
      "matchbox", "matches", "machees", "candle", "candles", "mombatti",
      "safety matches"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # PERSONAL CARE & HYGIENE
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Soap & Handwash",
    "category": "Personal Care",
    "standard_unit": "pcs",
    "aliases": [
      "soap", "sabun", "bath soap", "lux", "lifebuoy", "dove soap",
      "imperial leather", "dettol soap", "safeguard", "palmolive",
      "toilet soap", "body wash", "hand wash", "dettol hand wash",
      "lifebuoy hand wash", "safeguard soap", "capri soap"
    ]
  },
  {
    "canonical_name": "Shampoo & Hair Care",
    "category": "Personal Care",
    "standard_unit": "ml",
    "aliases": [
      "shampoo", "head and shoulders", "pantene", "sunsilk", "dove shampoo",
      "clear shampoo", "loreal shampoo", "hair shampoo", "anti dandruff shampoo",
      "conditioner", "hair oil", "amla oil", "coconut oil", "parachute oil",
      "bajaj almond oil", "hair gel", "hair color", "black rose mehndi"
    ]
  },
  {
    "canonical_name": "Toothpaste & Oral Care",
    "category": "Personal Care",
    "standard_unit": "g",
    "aliases": [
      "toothpaste", "colgate", "close up", "sensodyne", "pepsodent",
      "dental cream", "tooth gel", "manjan", "toothbrush", "mouthwash",
      "listerine", "colgate total", "medicam"
    ]
  },
  {
    "canonical_name": "Skin Care & Lotions",
    "category": "Personal Care",
    "standard_unit": "pcs",
    "aliases": [
      "face wash", "cream", "fair and lovely", "glow and lovely", "ponds",
      "nivea", "body lotion", "sunblock", "vaseline", "petroleum jelly",
      "talcum powder", "tibet snow", "ponds cream", "nivea soft"
    ]
  },
  {
    "canonical_name": "Shaving Products",
    "category": "Personal Care",
    "standard_unit": "pcs",
    "aliases": [
      "shaving foam", "shaving cream", "shaving gel", "razor", "gillette",
      "gillette razor", "gillette mach 3", "treet blade", "blades", "aftershave"
    ]
  },
  {
    "canonical_name": "Deodorants & Fragrances",
    "category": "Personal Care",
    "standard_unit": "bottle",
    "aliases": [
      "deodorant", "body spray", "axe", "fogg", "rexona", "nivea deodorant",
      "perfume", "attar", "cologne", "brut"
    ]
  },
  {
    "canonical_name": "Sanitary & Feminine Care",
    "category": "Personal Care",
    "standard_unit": "pkt",
    "aliases": [
      "sanitary pads", "sanitary napkins", "always", "butterfly",
      "butterfly breathables", "pantyliners"
    ]
  },
  {
    "canonical_name": "Baby Care & Diapers",
    "category": "Personal Care",
    "standard_unit": "pkt",
    "aliases": [
      "pampers", "diapers", "canbebe", "molfix", "baby wipes", "baby powder",
      "baby soap", "cerelac", "baby formula", "baby shampoo", "johnson baby"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # HEALTH & PHARMACY (OTC)
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Pain & Fever Relief",
    "category": "Health & Pharmacy",
    "standard_unit": "pkt",
    "aliases": [
      "panadol", "panadol extra", "panadol cf", "disprin", "paracetamol",
      "calpol", "brufen", "ponstan", "febrol", "aspirin", "panadol drops",
      "brufen syrup", "disprin cv"
    ]
  },
  {
    "canonical_name": "Cough, Cold & Flu",
    "category": "Health & Pharmacy",
    "standard_unit": "bottle",
    "aliases": [
      "arinac", "arinac forte", "sancos", "sancos syrup", "cough syrup",
      "hydryllin", "hydryllin syrup", "pulmonol", "corenza c", "actifed",
      "strepsils", "strepsils honey lemon", "vicks", "vicks vaporub", "vicks inhaler"
    ]
  },
  {
    "canonical_name": "Digestion & Stomach Relief",
    "category": "Health & Pharmacy",
    "standard_unit": "pkt",
    "aliases": [
      "eno", "ors", "hydrite", "flagyl", "entamizole", "risek", "gaviscon",
      "gaviscon syrup", "digene", "ispaghol", "hashmi ispaghol", "psyllium husk"
    ]
  },
  {
    "canonical_name": "Vitamins & Supplements",
    "category": "Health & Pharmacy",
    "standard_unit": "pkt",
    "aliases": [
      "surbex z", "cac 1000", "cac 1000 plus", "neurobion", "becotin",
      "vitamin c", "ascorbic acid", "evion", "sangobion", "multivitamin"
    ]
  },
  {
    "canonical_name": "First Aid & Antiseptics",
    "category": "Health & Pharmacy",
    "standard_unit": "pcs",
    "aliases": [
      "dettol antiseptic", "pyodine", "polyfax", "sunnyplast", "band aid",
      "bandage", "crepe bandage", "surgical mask", "face mask", "cotton buds",
      "medical cotton", "antiseptic"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # PREPARED FOOD, RESTAURANTS & DINING
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Cooked Biryani & Rice Meals",
    "category": "Groceries & Food",
    "standard_unit": "plate",
    "aliases": [
      "biryani", "chicken biryani", "beef biryani", "mutton biryani", "nalli biryani",
      "sada biryani", "biryani single", "biryani double", "pulao", "chicken pulao"
    ]
  },
  {
    "canonical_name": "Cooked Nihari & Traditional Stews",
    "category": "Groceries & Food",
    "standard_unit": "plate",
    "aliases": [
      "nihari", "nihari single", "nihari double", "nalli nihari", "maghaz nihari",
      "special nihari", "javed nihari", "haleem", "chicken haleem", "beef haleem"
    ]
  },
  {
    "canonical_name": "Cooked Karahi & Handi",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": [
      "chicken karahi", "mutton karahi", "shinwari karahi", "white karahi",
      "chicken handi", "paneer handi", "karahi full", "karahi half"
    ]
  },
  {
    "canonical_name": "BBQ & Kababs",
    "category": "Groceries & Food",
    "standard_unit": "pcs",
    "aliases": [
      "chicken tikka", "tikka chest", "tikka leg", "seekh kabab", "malai boti",
      "chicken boti", "reshmi kabab", "bihari kabab", "chapli kabab"
    ]
  },
  {
    "canonical_name": "Dining Disposables",
    "category": "Household & Cleaning",
    "standard_unit": "pcs",
    "aliases": [
      "disposable glass", "disposable glasses", "paper cups", "plastic cups",
      "disposable plate", "plastic plates", "plastic spoon", "plastic fork", "disposibe gass"
    ]
  },

  # ─────────────────────────────────────────────────────────────────────────
  # UTILITIES & BILLS
  # ─────────────────────────────────────────────────────────────────────────
  {
    "canonical_name": "Electricity Bill",
    "category": "Utilities & Bills",
    "standard_unit": "pcs",
    "aliases": [
      "electricity bill", "bijli bill", "wapda", "kesc", "k electric", "ke bill",
      "hesco", "lesco", "mepco", "iesco", "electric bill", "power bill", "units consumed"
    ]
  },
  {
    "canonical_name": "Gas Bill",
    "category": "Utilities & Bills",
    "standard_unit": "pcs",
    "aliases": [
      "gas bill", "sui gas", "sngpl", "ssgc", "natural gas", "gas charges"
    ]
  },
  {
    "canonical_name": "Water & Municipal Bill",
    "category": "Utilities & Bills",
    "standard_unit": "pcs",
    "aliases": [
      "water bill", "kwsb", "wasa", "water charges", "sewerage bill", "conservancy"
    ]
  },
  {
    "canonical_name": "Mobile Top-Up & Internet",
    "category": "Utilities & Bills",
    "standard_unit": "pcs",
    "aliases": [
      "top up", "topup", "recharge", "jazz", "zong", "ufone", "telenor",
      "warid", "mobile recharge", "scratch card", "sms package", "data package",
      "internet package", "easyload", "nayatel", "stormfiber", "ptcl"
    ]
  },
  {
    "canonical_name": "Delivery & Service Charges",
    "category": "Utilities & Bills",
    "standard_unit": "pcs",
    "aliases": [
      "delivery charges", "delivery fee", "service charges", "service fee",
      "handling fee", "courier charges", "rider tip"
    ]
  }
]

out_path = Path(r"c:\Users\Asad\Desktop\ReceiptLedger\data\local_taxonomy.json")
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(TAXONOMY, f, indent=2, ensure_ascii=False)

print(f"Successfully generated {len(TAXONOMY)} taxonomy entries into {out_path}!")
