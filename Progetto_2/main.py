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

def isMachineAvailable(recipie):
    for equipment in recipie.ops:
        if not machineState[equipment["equipmentName"]]:
            return False
    return True

def isMaterialAvailable(recipie):
    material = recipie["operations"]["operationName"].split("_")[1]
    if material in material and materials[material] < 1:
        return False
    return True

def executeRecipies():
    for r in recipiesInExec:
        isMachineAvailable(r)
        isMaterialAvailable(r)

        # all checks passed, set startTime
        if r.ops[r.opIndex]["started"] == 0:
            r.ops[r.opIndex]["started"] = 1
            r.ops[r.opIndex]["startTime"] = timeTick

        # execute an operation step
        processingTime = int(r.ops["equipment"][r.opIndex]["processingTime"]) - 1
        r.ops["equipment"][r.opIndex]["processingTime"] = str(processingTime)

        if processingTime == 0:
            r.ops[r.opIndex]["endTime"] = timeTick
            r.ops[r.opIndex]["processingTime"] = timeTick - r.ops[r.opIndex]["startTime"]
            r.opIndex += 1
            if len(r.operations) == r.opIndex: # recipie is over                
                recipiesExecuted.append(r)

        
def startRecipies():
    # start a new recipie if machines and resources are available
    for recipie in recipiesToExec.keys():
        isMachineAvailable(recipie)
        isMaterialAvailable(recipie)
        r = Recipie(recipie, recipiesSpec[recipie]["operations"])
        recipiesInExec.append()

def outputSchedule(file):
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

    outJson["makespan"] = lastEndTime - recipiesExecuted[0].opsData[0]["startTime"]

    with open(OUTPUT_FILES_FOLDER + "/" + "output-scheduling" + 0 + ".json", "w") as outfile:
        json.dump(outJson, outfile)


def generateSchedule(inputFile):
    with open(INPUT_FILES_FOLDER + "/" + inputFile) as a:        
        line = a.readline() # skip csv header, expected to be 'type;subtype;key;value;time'
        line = a.readline()
        splitLine = ""
        while line != "": # till EOF
            splitLine = line.split("")
            if len(splitLine = 5): # check for wellformed line
                while splitLine[4] == timeTick: # read all lines on current timeTick

                    # read current line and update resources/recipies/orders
                    match splitLine[1]:
                        case "new-order": # new recipies
                            addRecipie(splitLine[2], splitLine[3])
                        case "add-materials":
                            addMaterial(splitLine[2], splitLine[3])
                        case "breakdown":
                            machineState[splitLine[2]] = bool(splitLine[3])

                    # execute recipies
                    if len(recipiesInExec.keys()) != 0:
                        executeRecipies()
                    
                    startRecipies()
                    
                    line = a.readline()
                    splitLine = line.split("")

                timeTick += 1
            line = a.readline()
            
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

    with open(RECIPIES_FILE) as handle:
        recipiesSpec = json.loads(handle.read())

    # Load machines names
    for recipie in recipiesSpec:
        # print("Recipie: " + x["orderName"])
        for op in recipie["operations"]:
            for equipment in op["equipment"]:
                machine = equipment["equipmentName"]
                if machine not in machineState:
                    machineState[machine] = True # all machines are up by defualt

def clear():
    timeTick = 0
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
