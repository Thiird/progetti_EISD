# Stefano Nicolis - 2022
# Università degli Studi di Verona
# Embedded and IoT System Design

import os
import json
from os import listdir
from os.path import isfile, join


RECIPIES_FILE = "Recipes.json"
INPUT_FILES_FOLDER = "input"
recipies = {}

def generateSchedule(inputFile):
    with open(INPUT_FILES_FOLDER + "/" + inputFile) as a:
        line = a.readline() # skip csv header, expexted to be 'type;subtype;key;value;time'
        line = a.readline()
        while line != "":
            line = a.readline()
            

def loadRecipies():
    global recipies
    with open(RECIPIES_FILE) as handle:
        recipies = json.loads(handle.read())

    print("Recipies:")
    for i in range(len(recipies)):
        print("\t" + recipies[i]["orderName"])


if __name__ == "__main__":

    if not os.path.exists(RECIPIES_FILE):
        raise FileNotFoundError("'Recipies.json' file is missing!")
    if not os.path.exists(INPUT_FILES_FOLDER):
        raise FileNotFoundError("local 'input' directory is missing!")

    inputFiles = [f for f in listdir(INPUT_FILES_FOLDER) if isfile(join(INPUT_FILES_FOLDER, f))]
    if len(inputFiles) == 0:
        raise FileNotFoundError("'input' directory is empty!")

    loadRecipies()

    for file in inputFiles:
        generateSchedule(file)
