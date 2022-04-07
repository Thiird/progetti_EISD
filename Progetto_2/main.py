# Stefano Nicolis - 2022
# Università degli Studi di Verona
# Embedded and IoT System Design Project

import os
import json
from copy import deepcopy
from os import listdir
from os.path import isfile, join

timeTick = -1 # time in the simulation
executedLine = False
noMoreInputs = False
RECIPES_FILE = "Recipes.json"
INPUT_FILES_FOLDER = "input"
OUTPUT_FILES_FOLDER = "output"
recipesSpec = {}     # recipeName : recipeJson
recipesToExec = {}   # recipeName : scheduledQuantity
recipesInExec = []   # Recipe() objs references
recipesExecuted = [] # Recipe() objs references
abortedRecipes = []  # Recipe() objs references
machineState = {}    # machineName : isUp
machineUsage = {}    # machineName : recipeObj that is using it
materials = {}       # materialName : quantity in storage

class Recipe:
    def __init__(self, name, operations, startTime):
        self.name = name
        self.opsData = operations # JSON object
        self.opIndex = 0 # which operation is the recipe at

        # adjust some fields
        for op in self.opsData:
            # add fields for output file
            op["startTime"] = startTime
            op["endTime"] = -1
            # cast once now to avoid casting multiple times during execution
            for equipment in op["equipment"]:
                equipment["processingTime"] = int(equipment["processingTime"])

def strToBool(v):
  return v.lower() in ("yes", "true", "t", "1")

def isMachineUp(operation):
    global machineState

    for equipment in operation["equipment"]:
        if not machineState[equipment["equipmentName"]]:
            return False
    return True

def isMachineFree(operation):
    global machineUsage

    for equipment in operation["equipment"]:
        if equipment["equipmentName"] in machineUsage:
            return False # machine is being used by at least a recipie
    return True

def isMaterialAvailable(material):
    # material is expected to be ['LOAD', 'LEGO'] or ['QLTY', 'CTRL', 'LEGO'] or ['MILLING']...
    material = material[len(material) - 1]
    if material in materials and materials[material] < 1:
        return False
    return True

def checkAllResources(operation):
    machineUp = isMachineUp(operation)
    machineFree = isMachineFree(operation)
    materialsAvailable = isMaterialAvailable(operation["operationName"].split("_"))
    return machineFree and machineUp and materialsAvailable

def executeRecipes():
    global recipesInExec
    global timeTick
    global noMoreInputs

    finishedRecipes = []
    nonFinishableRecipes = []
    for r in recipesInExec:
        processingTime = r.opsData[r.opIndex]["equipment"][0]["processingTime"]
        if processingTime != 0:
            if (isMachineUp(r.opsData[r.opIndex]) and isMaterialAvailable(r.opsData[r.opIndex]["operationName"].split("_"))):
                # execute an operation step
                processingTime -= 1
                r.opsData[r.opIndex]["equipment"][0]["processingTime"] = processingTime
            else:
                if noMoreInputs:
                    print("Can't finish recipie because input file is over and no resources are available")
                    nonFinishableRecipes.append(r)
                print("No resources for " + r.name + " opIndex:" + str(r.opIndex) + " @ " + str(timeTick))

        if processingTime == 0: # operation is over
            # recipie owned machine for this operation, free that machine
            machine = r.opsData[r.opIndex]["equipment"][0]["equipmentName"]
            if machine in machineUsage and machineUsage[machine] == r:
                del machineUsage[machine]

            if len(r.opsData) - 1 == r.opIndex: # recipie is over
                print("OVER: " + r.name + " @ " + str(timeTick))
                r.opsData[r.opIndex]["endTime"] = timeTick
                r.opsData[r.opIndex]["processingTime"] = timeTick - r.opsData[r.opIndex]["startTime"]
                finishedRecipes.append(r)
            else:
                # is next operation's machine used by other recipies atm?
                if isMachineUp(r.opsData[r.opIndex + 1]):
                    if isMachineFree(r.opsData[r.opIndex + 1]):
                        r.opIndex += 1
                        setEquipment(r, 0) # choose an equipment, delete the rest
                else:
                    print("Can't finish recipie because input file is over and no resources are available")
                    nonFinishableRecipes.append(r)


    for r in finishedRecipes:
        recipesExecuted.append(r)
        recipesInExec.remove(r)

    for r in nonFinishableRecipes:
        recipesInExec.remove(r)
        abortedRecipes.append(r)

def setEquipment(r, criteria): # TODO, dont simply pick the first one
    # removes all equipment except the choosen one
    # leave as array to avoid problems of diversifying code before-after the equipment choice
    r.opsData[r.opIndex]["equipment"] = [r.opsData[r.opIndex]["equipment"][0]]

def chooseMachine(operation):
    # returns the index of the equipment to choose for the given operation
    if len(operation["equipment"]) > 1:
        # TODO equipment choice logic
        return 0

    return 0

def startRecipes():
    global recipesToExec
    global recipesInExec
    global recipesSpec
    global timeTick

    toRemoveRecipes = []

    # start a new recipie if first operation's machine and resources are available
    for r in recipesToExec.keys():
        if checkAllResources(recipesSpec[r][0]):
            machineIndex = chooseMachine(recipesSpec[r][0])
            choosenMachine = recipesSpec[r][0]["equipment"][machineIndex]["equipmentName"]
            if choosenMachine not in machineUsage: # choose machine is available, can start recipie
                rObj = Recipe(r, deepcopy(recipesSpec[r]), timeTick)
                setEquipment(rObj, machineIndex)
                machineUsage[choosenMachine] = rObj # assign machine to this recipie
                recipesInExec.append(rObj)
                print("STARTED: " + rObj.name + " @ " + str(timeTick))

                # check for recipies to remove from waiting queue
                recipesToExec[r] = recipesToExec[r] - 1
                if recipesToExec[r] == 0:
                    toRemoveRecipes.append(r)

    for r in toRemoveRecipes:
        del recipesToExec[r]

def outputSchedule(file):
    global recipesExecuted
    outJson = {}
    outJson["makespan"] = -1
    outJson["tasks"] = []
    tempR = {} # temporary operation object
    lastEndTime = -1 # endTime of last operation of last recipie to end

    # build output json
    for r in recipesExecuted:
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

        outJson["tasks"].append(deepcopy(tempR))
    print(str(len(recipesExecuted)) + " recipies executed from file " + file)

    if len(recipesExecuted) != 0:
        outJson["makespan"] = lastEndTime - int(recipesExecuted[0].opsData[0]["startTime"])

        if not os.path.exists(OUTPUT_FILES_FOLDER):
            os.mkdir(OUTPUT_FILES_FOLDER)

        with open(OUTPUT_FILES_FOLDER + "/" + "output-scheduling" + file[-5:-4] + ".json", "w") as outfile:
            json.dump(outJson, outfile, indent=4)

def parseLine(splitLine):
    match splitLine[1]:
        case "new-order": # new recipies
            addRecipe(splitLine[2], int(splitLine[3]))
        case "add-materials":
            addMaterial(splitLine[2], int(splitLine[3]))
        case "breakdown":
            machineState[splitLine[2]] = strToBool(splitLine[3])

def generateSchedule(inputFile):
    global timeTick
    global recipesInExec
    global executedLine
    global noMoreInputs

    with open(INPUT_FILES_FOLDER + "/" + inputFile) as a:
        line = a.readline() # skip csv header, expected to be 'type;subtype;key;value;time'
        line = a.readline()

        while line != "": # till EOF
            splitLine = line.split(";")
            if len(splitLine) == 5: # check for wellformed line

                while True:
                    if (timeTick < int(splitLine[4].strip())):
                        timeTick += 1
                        executeRecipes()
                        startRecipes()

                    if (timeTick == int(splitLine[4].strip())):
                        parseLine(splitLine)
                        break

                line = a.readline()
        noMoreInputs = True # input file is over

        # finish to execute the remaining recipes
        while len(recipesToExec.keys()) or len(recipesInExec) != 0:
            timeTick += 1
            executeRecipes()
            startRecipes()


def addRecipe(name, quantity):
    if name not in recipesToExec:
        recipesToExec[name] = quantity
    else:
        recipesToExec[name] = recipesToExec[name] + quantity

def addMaterial(name, quantity):
    if name not in materials:
        materials[name] = quantity
    else:
        materials[name] = materials[name] + quantity

def loadRecipesAndMachines():
    global recipesSpec
    global machineState

    # load recipies specifications
    with open(RECIPES_FILE) as handle:
        recipesRaw = json.loads(handle.read())
    for recipe in recipesRaw:
        recipesSpec[recipe["orderName"]] = recipe["operations"]

    # load machines names
    for recipe in recipesSpec:
        for op in recipesSpec[recipe]:
            for equipment in op["equipment"]:
                machine = equipment["equipmentName"]
                if machine not in machineState:
                    machineState[machine] = True # all machines are up by defualt

def clear():
    global timeTick
    global recipesSpec
    global recipesToExec
    global recipesInExec
    global recipesExecuted
    global machineState
    global machineUsage
    global materials

    timeTick = -1
    recipesSpec = {}
    recipesToExec = {}
    recipesInExec = []
    recipesExecuted = []
    machineState = {}
    machineUsage = {}
    materials = {}

if __name__ == "__main__":

    if not os.path.exists(RECIPES_FILE):
        raise FileNotFoundError("'Recipes.json' file is missing!")
    if not os.path.exists(INPUT_FILES_FOLDER):
        raise FileNotFoundError("local 'input' directory is missing!")

    inputFiles = [f for f in listdir(INPUT_FILES_FOLDER) if isfile(join(INPUT_FILES_FOLDER, f))]
    if len(inputFiles) == 0:
        raise FileNotFoundError("'input' directory is empty!")

    for file in inputFiles:
        loadRecipesAndMachines()
        generateSchedule(file)
        outputSchedule(file)
        clear()
        break
