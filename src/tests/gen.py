from os import system
import pandas as pd
import hashlib

make = [
    "AMC Concord",
    "AMC Pacer",
    "AMC Spirit",
    "Buick Century",
    "Buick Electra",
    "Buick LeSabre",
    "Buick Opel",
    "Buick Regal",
    "Buick Riviera",
    "Buick Skylark",
    "Cad. Deville",
    "Cad. Eldorado",
    "Cad. Seville",
    "Chev. Chevette",
    "Chev. Impala",
    "Chev. Malibu",
    "Chev. Monte Carlo",
    "Chev. Monza",
    "Chev. Nova",
    "Dodge Colt",
    "Dodge Diplomat",
    "Dodge Magnum",
    "Dodge St. Regis",
    "Ford Fiesta",
    "Ford Mustang",
    "Linc. Continental",
    "Linc. Mark V",
    "Linc. Versailles",
    "Merc. Bobcat",
    "Merc. Cougar",
    "Merc. Marquis",
    "Merc. Monarch",
    "Merc. XR-7",
    "Merc. Zephyr",
    "Olds 98",
    "Olds Cutl Supr",
    "Olds Cutlass",
    "Olds Delta 88",
    "Olds Omega",
    "Olds Starfire",
    "Olds Toronado",
    "Plym. Arrow",
    "Plym. Champ",
    "Plym. Horizon",
    "Plym. Sapporo",
    "Plym. Volare",
    "Pont. Catalina",
    "Pont. Firebird",
    "Pont. Grand Prix",
    "Pont. Le Mans",
    "Pont. Phoenix",
    "Pont. Sunbird",
    "Audi 5000",
    "Audi Fox",
    "BMW 320i",
    "Datsun 200",
    "Datsun 210",
    "Datsun 510",
    "Datsun 810",
    "Fiat Strada",
    "Honda Accord",
    "Honda Civic",
    "Mazda GLC",
    "Peugeot 604",
    "Renault Le Car",
    "Subaru",
    "Toyota Celica",
    "Toyota Corolla",
    "Toyota Corona",
    "VW Dasher",
    "VW Diesel",
    "VW Rabbit",
    "VW Scirocco",
    "Volvo 260"
]

sums = [
    "md5",
    "sha1",
    "sha224",
    "sha256",
    "sha384",
    "sha512"
]

maxlen = 0
for m in make:
    maxlen = max(maxlen, len(m))

maxlen += 1

# Once
# ----

dfHash = pd.DataFrame(make)
for cs in sums:
    colhash = []
    for m in make:
        pad = (maxlen - len(m)) * '\0' + '\0'
        colhash += [getattr(hashlib, cs)((m + pad).encode("utf-8")).hexdigest()]

    dfHash = pd.concat((dfHash, pd.DataFrame(colhash)), axis = 1)

dfHash.columns = ["make"] + sums
dfHash.to_csv("make_hashes_pad.csv", index = False)

dfHash  = pd.DataFrame(make)
for cs in sums:
    colhash = []
    for m in make:
        colhash += [getattr(hashlib, cs)(m.encode("utf-8")).hexdigest()]

    dfHash = pd.concat((dfHash, pd.DataFrame(colhash)), axis = 1)

dfHash.columns = ["make"] + sums
dfHash.to_csv("make_hashes.csv", index = False)

# Twice
# -----

dfHash = pd.DataFrame(make)
for cs in sums:
    colhash = []
    for m in make:
        pad = (maxlen - len(m)) * '\0'
        msg = m + pad + m + pad + '\0'
        colhash += [getattr(hashlib, cs)(msg.encode("utf-8")).hexdigest()]

    dfHash = pd.concat((dfHash, pd.DataFrame(colhash)), axis = 1)

dfHash.columns = ["make"] + sums
dfHash.to_csv("make2_hashes_pad.csv", index = False)

dfHash = pd.DataFrame(make)
for cs in sums:
    colhash = []
    for m in make:
        colhash += [getattr(hashlib, cs)((m + m).encode("utf-8")).hexdigest()]

    dfHash = pd.concat((dfHash, pd.DataFrame(colhash)), axis = 1)

dfHash.columns = ["make"] + sums
dfHash.to_csv("make2_hashes.csv", index = False)

# printf 'Volvo 260\\\\\\\\\Volvo 260\\\\\\\\\\' | md5sum
# printf 'Volvo 260\0\0\0\0\0\0\0\0\0Volvo 260\0\0\0\0\0\0\0\0\0\0' | md5sum
