# PowerShellModPack

Update.ps1 is a Powershell script to update a modpack from curseforge. This script reads a list of ids of mods and query curseforge for the last version.
No need of another software (curseforge client) to work.

The script assumes that is running in a subfolder of the mods folder.
The new files are downloaded in the folder named "new" , created as subfolder of mods.
The old files are renamed with a underscore, not deleted.

You can add mods to the ids.txt file manually or use another script (Modpack.ps1) to automate the creation of the id.txt file.
This script calculates de hash of mod files to determine the project id to generate ids.txt , if config.json file is found this script also generates a  manifest.json curseforge compatible file.

I have uploaded a ids.txt example. A reduced technical modpack.

Modpack.ps1 creates the ids.txt file and manifest.json file from the mod binarys. The script calculates the hash of each file and querys curseforge for determine the mod id.

CreateZip.ps1 uses 7z to create a zip file with the manifest.json and the other files and folders specified at config.json
You can publish this zip file at curseforge as modpack.

Documentation for Curseforge api.  https://twitchappapi.docs.apiary.io/#
