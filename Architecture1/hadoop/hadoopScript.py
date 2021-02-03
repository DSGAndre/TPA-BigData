from pyspark.shell import sc

def cleanString(s):
    string = s.replace(u'\xa0', u' ')
    return string.split(u'\u20ac')[0].replace(" ", "")

def mapBrands(x):
    splitx = x.split(",")
    brand = splitx[1].replace('"', '').split(" ")[0]
    detailsIndex = len(splitx) - 3
    details = splitx[detailsIndex:]
    dataObject = {
      "bonusMalus": cleanString(details[0]).encode("utf-8"),
      "CO2Rejects": cleanString(details[1]).encode("utf-8"),
      "energyCost": cleanString(details[2]).encode("utf-8")
    }
    countObject = {
      "bonusMalus": 1,
      "CO2Rejects": 1,
      "energyCost": 1
    }
    data = {"data": dataObject, "count": countObject}
    return (''.join(brand)).encode("utf-8"), data

def mapWithAverage(x):
    bonusMalusAverage = int(x["data"]["bonusMalus"]) / x["count"]["bonusMalus"] if x["count"]["bonusMalus"] != 0 and x["data"]["bonusMalus"] != "-" else "N/A";
    CO2RejectsAverage = int(x["data"]["CO2Rejects"]) / x["count"]["CO2Rejects"] if x["count"]["CO2Rejects"] != 0 else "N/A";
    energyCostAverage = int(x["data"]["energyCost"]) / x["count"]["energyCost"] if x["count"]["energyCost"] != 0 else "N/A";
    averages = (bonusMalusAverage, CO2RejectsAverage, energyCostAverage)
    return ",".join(str(a) for a in averages)

def reduceBrands(a, b):
    if a["data"]["bonusMalus"] != "-":
      bufferObject = {
        "bonusMalus": (int(a["data"]["bonusMalus"]) + int(b["data"]["bonusMalus"])) if b["data"]["bonusMalus"] != "-" else int(a["data"]["bonusMalus"]),
        "CO2Rejects": int(a["data"]["CO2Rejects"]) + int(b["data"]["CO2Rejects"]),
        "energyCost": int(a["data"]["energyCost"]) + int(b["data"]["energyCost"]),
      }
      countObject = {
        "bonusMalus": (a["count"]["bonusMalus"] + b["count"]["bonusMalus"]) if b["data"]["bonusMalus"] != "-" else a["count"]["bonusMalus"],
        "CO2Rejects": a["count"]["CO2Rejects"] + b["count"]["CO2Rejects"],
        "energyCost": a["count"]["energyCost"] + b["count"]["energyCost"]
      }
      return {
        "data": bufferObject,
        "count": countObject
      }
    else:
      bufferObject = {
        "bonusMalus": int(b["data"]["bonusMalus"]) if b["data"]["bonusMalus"] != "-" else 0,
        "CO2Rejects": int(a["data"]["CO2Rejects"]) + int(b["data"]["CO2Rejects"]),
        "energyCost": int(a["data"]["energyCost"]) + int(b["data"]["energyCost"]),
      }
      countObject = {
        "bonusMalus": b["count"]["bonusMalus"] if b["data"]["bonusMalus"] != "-" else 0,
        "CO2Rejects": a["count"]["CO2Rejects"] + b["count"]["CO2Rejects"],
        "energyCost": a["count"]["energyCost"] + b["count"]["energyCost"]
      }
      return {
        "data": bufferObject,
        "count": countObject
      }
      

co2 = sc.textFile("hdfs://bigdatalite.localdomain/bigDataProject2020Groupe1/CO2/CO2.csv")
header = co2.first()
co2 = co2.filter(lambda l: l != header)
mappedBrands = co2.map(mapBrands)
reducedBrands = mappedBrands.reduceByKey(reduceBrands)
results = reducedBrands.mapValues(mapWithAverage)
results.saveAsTextFile("hdfs://bigdatalite.localdomain/bigDataProject2020Groupe1/CO2/results")