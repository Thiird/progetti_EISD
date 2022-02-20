# Stefano Nicolis - 2022
# Università degli Studi di Verona
# Embedded and IoT System Design Project

import os
import json
from os import listdir
from os.path import isfile, join
from posixpath import split

timeTick = 0 # time in the simulation
RECIPIES_FILE = "Recipes.json"
INPUT_FILES_FOLDER = "input"
OUTPUT_FILES_FOLDER = "output"
recipiesSpec = {}     # recipieName : recipieJson
recipiesToExec = {}   # recipieName : scheduledQuantity
recipiesInExec = []   # Recipie() objs references
recipiesExecuted = [] # Recipie() objs references
machineState = {}     # machine : isUp
materials = {}        # materialName : quantity in storage

class Recipie:
    def __init__(self, name, operations, startTime):
        self.name = name
        self.opsData = operations # JSON object
        self.opIndex = 0 # which operation is the recipie at

        # add data for final output
        for op in self.opsData:
            op["started"] = 0
            op["startTime"] = startTime
            op["endTime"] = -1

def isMachineAvailable(operation):
    global machineState

    for equipment in operation["equipment"]:
        if not machineState[equipment["equipmentName"]]:
            return False
    return True

def isMaterialAvailable(operation):
    material = operation["operationName"].split("_")
    if( len(material) > 1):
        material = material[1]
    else:
        material = material[0]
    if material in materials and materials[material] < 1:
        return False
    return True

def executeRecipies():
    global recipiesInExec

    finishedRecipies = []
    for r in recipiesInExec:
        isMachineAvailable(r.opsData[r.opIndex])
        isMaterialAvailable(r.opsData[r.opIndex])

        # all checks passed, set startTime
        if r.opsData[r.opIndex]["started"] == 0:
            r.opsData[r.opIndex]["started"] = 1
            r.opsData[r.opIndex]["startTime"] = timeTick

        # execute an operation step
        processingTime = int(r.opsData[r.opIndex]["equipment"][0]["processingTime"]) - 1
        r.opsData[r.opIndex]["equipment"][0]["processingTime"] = str(processingTime)

        if processingTime == 0: # operation is over
            r.opsData[r.opIndex]["equipment"][0]["endTime"] = timeTick
            r.opsData[r.opIndex]["equipment"][0]["processingTime"] = timeTick - r.opsData[r.opIndex]["startTime"]
            r.opIndex += 1
            if len(r.opsData) == r.opIndex: # recipie is over
                finishedRecipies.append(r)
                recipiesToExec[r.name] = recipiesToExec[r.name] - 1
            else: # choose an equipment, delete the rest
                chooseEquipment(r, 0)

    for r in finishedRecipies:
        recipiesExecuted.append(r)
        recipiesInExec.remove(r)
        if recipiesToExec[r.name] == 0:
            del recipiesToExec[r.name]

def chooseEquipment(r, criteria): # TODO, dont simply pick the first one
    r.opsData[r.opIndex]["equipment"] = [r.opsData[r.opIndex]["equipment"][0]]

def startRecipies():
    global recipiesToExec
    global recipiesInExec
    global recipiesSpec
    global timeTick

    # start a new recipie if first operation machines and resources are available
    for recipie in recipiesToExec.keys():
        isMachineAvailable(recipiesSpec[recipie][0])
        isMaterialAvailable(recipiesSpec[recipie][0])
        r = Recipie(recipie, recipiesSpec[recipie], timeTick)
        chooseEquipment(r, 0)
        recipiesInExec.append(r)

def outputSchedule(file):
    global recipiesExecuted
    outJson = {}
    outJson["makespan"] = -1
    outJson["tasks"] = []
    tempR = {} # temporary operation object
    lastEndTime = -1 # endTime of last operation of last recipie to end

    # build outpout json
    for r in recipiesExecuted:
        for op in r.opsData:
            tempR["id"] = op["operationName"]
            tempR["jobId"] = r.name

            # the equipment used as a non-empty name
            for eq in op["equipment"]:
                if eq["equipmentName"] != "":
                    tempR["equipment"] = eq["equipmentName"]
                    break

            tempR["startTime"] = op["startTime"]
            tempR["processingTime"] = op["endTime"] - op["startTime"]
            tempR["endTime"] = op["endTime"]

            lastEndTime = op["endTime"]

        outJson["tasks"].append(tempR)

    outJson["makespan"] = lastEndTime - int(recipiesExecuted[0].opsData[0]["startTime"])

    if not os.path.exists(OUTPUT_FILES_FOLDER):
        os.mkdir(OUTPUT_FILES_FOLDER)

    with open(OUTPUT_FILES_FOLDER + "/" + "output-scheduling" + file[-1] + ".json", "w") as outfile:
        json.dump(outJson, outfile)


def generateSchedule(inputFile):
    global timeTick
    global recipiesInExec

    with open(INPUT_FILES_FOLDER + "/" + inputFile) as a:
        line = a.readline() # skip csv header, expected to be 'type;subtype;key;value;time'
        line = a.readline()
        splitLine = line.split(";")
        while line != "": # till EOF
            while int(splitLine[4].strip()) != timeTick:
                timeTick += 1
                if len(splitLine) == 5: # check for wellformed line
                    # read current line and update resources/recipies/orders
                    match splitLine[1]:
                        case "new-order": # new recipies
                            addRecipie(splitLine[2], splitLine[3])
                        case "add-materials":
                            addMaterial(splitLine[2], splitLine[3])
                        case "breakdown":
                            machineState[splitLine[2]] = bool(splitLine[3])

                    # execute recipies
                    if len(recipiesInExec) != 0:
                        executeRecipies()
                    startRecipies()

                line = a.readline()
                splitLine = line.split(";")

def addRecipie(name, quantity):
    if name not in recipiesToExec:
        recipiesToExec[name] = quantity
    else:
        recipiesToExec[name] = recipiesToExec[name] + quantity

def addMaterial(name, quantity):
    if name not in materials:
        materials[name] = quantity
    else:
        materials[name] = materials[name] + quantity

def loadRecipiesAndMachines():
    global recipiesSpec
    global machineState

    # load recipies specifications
    with open(RECIPIES_FILE) as handle:
        recipiesRaw = json.loads(handle.read())
    for recipie in recipiesRaw:
        recipiesSpec[recipie["orderName"]] = recipie["operations"]

    # load machines names
    for recipie in recipiesSpec:
        for op in recipiesSpec[recipie]:
            for equipment in op["equipment"]:
                machine = equipment["equipmentName"]
                if machine not in machineState:
                    machineState[machine] = True # all machines are up by defualt

def clear():
    global timeTick
    global recipiesSpec
    global recipiesToExec
    global recipiesInExec
    global recipiesExecuted
    global machineState
    global materials

    timeTick = -1
    recipiesSpec = {}
    recipiesToExec = {}
    recipiesInExec = []
    recipiesExecuted = []
    machineState = {}
    materials = {}

if __name__ == "__main__":

    if not os.path.exists(RECIPIES_FILE):
        raise FileNotFoundError("'Recipies.json' file is missing!")
    if not os.path.exists(INPUT_FILES_FOLDER):
        raise FileNotFoundError("local 'input' directory is missing!")

    inputFiles = [f for f in listdir(INPUT_FILES_FOLDER) if isfile(join(INPUT_FILES_FOLDER, f))]
    if len(inputFiles) == 0:
        raise FileNotFoundError("'input' directory is empty!")

    loadRecipiesAndMachines()

    for file in inputFiles:
        generateSchedule(file)
        outputSchedule(file)
        clear()
