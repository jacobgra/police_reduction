from groq import Groq
import json
import base64
import pandas as pd
from pathlib import Path
import re

client = Groq(api_key = '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')

def transfer_extraction(file_path):
    model = 'meta-llama/llama-4-maverick-17b-128e-instruct'

    system_prompt = 'You are a proficient Swedish reader with "text from image"-extracting capabilities.'

    instruction = """ 
    
    # Please extract the relevant information from the following text. Namely,
    Från - Region from which the resource is requested for example "LPO Linköping", "PO Jönköping" or "PO Östergötland" often preceded by the preposition "från". Never code this variable to for example IFK Värnamo since this denotes a football team. Sometimes even "PO S" or "PO Ö". However PO-chef is never correct.
    Till - Region that is requesting the resource for example "LPO Linköping", "PO Jönköping" or "PO Östergötland".  Never code this variable to for example IFK Värnamo since this denotes a football team. Sometimes even "PO S" or "PO Ö". However PO-chef is never correct.
    Antal - number of a resource. Type can be for example "UAS", "IGV", "PIC" or "RLC"
    Resurstyp - type of resource. Type can be for example "UAS", "IGV", "PIC" or "RLC"
    A-nr - case number. Often the name of the PNG file that is feeded to the model.
    Begärd start - from date. Often reported in the box "Uppskattning av tid för biträde from"	
    Begärt slut - until date. Often reported in the box "Uppskattning av tid för biträde tom"
    Bakgrund - Some context to why the resource is requested. Often found in the box "Beskrivning av/bakgrund till ärendet" Make it very short and summarize content.
    Koppling till NSH - "Operation Ture", "EMPACT" or "Operation Frigg" or similar capital letter names of operations
    Tidsutdräkt veckor - To the right of the box "Antal veckor" - if not crossed - set to .
    Tidsutdräkt dagar	To the right of the box "Antal dagar" - if not crossed - set to .
    Beslutsdatum - Date of decision. Often found in the box "Beslut" and subbox "Datum"
    Beviljad start - In the box "beviljad biträdesperiod"
    Beviljat slut -	In the box "beviljad biträdesperiod"
    Beviljad resurs - Never anything else than an integer should be outputed here. In the box "Beslut om biträde" is detailed what was actually sent. It should always be only a number so that one can compare to "Antal". A formulation as 1+7 should be interpreted as 8.
    Biträde godkänt - Trinary variable "Yes", "No" or "Partly". "No" is coded if for example mentioned "Beslut om ej biträde". Partly if "Beviljad resurs" != "Antal"
    Inkl fordon	- If it says that the resource should also contain vehicle specified as "Inkl. fordon"
    Inkl ledning - If there it is not "0+x" when the resource is specified
    Kompetens - Could be "Alpha" "Delta" or something like that. Often only specified if normal police is sent.

    # An example of a perfect output line would be as the following:
    Från: PO Östergötland, Till: PO Jönköping, Antal: 2, Resurstyp: UAS, A-nr: ., Begärd start: 2024-11-04, Begärd slut: 2024-11-04, Bakgrund: Match mellan IFK Norrköping - AIK, Tidsutdräkt veckor: ., Tidsutdräkt dagar: 1,	Beslutsdatum: 2024-11-04,  Beviljad start: 2024-11-04, Beviljar slut: 2024-11-04 Beviljad resurs: 2, Biträde godkänt: Yes
    
    # If there is data missing, just set that entry to empty.

    # Output a JSON row with each of the keys above as keys.

    # If there are multiple resources requested and sent in the same image. Please create a separate row for each. 
    """

    with open(file_path, "rb") as f:
        img_bytes = f.read()
    img_b64 = base64.b64encode(img_bytes).decode()
    
    messages = [
        {"role": "system", "content": system_prompt},
        {
            "role": "user",
            "content": [
                {"type": "text", "text": instruction},
                {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{img_b64}"}}
            ],
        },
    ]

    outputs = client.chat.completions.create(
        model=model,
        messages=messages,
        temperature=0,
        top_p=1,
        seed=42,
        response_format={"type": "json_object"},
    )

    response = outputs.choices[0].message.content
    return json.loads(response)

def insert_in_dataframe(df, file_path, file_name):
    extracted_data = transfer_extraction(file_path)
    if isinstance(extracted_data, dict):
        extracted_data = [extracted_data]
    for row in extracted_data:
      row["A-nr"] = file_name
      df = pd.concat([df, pd.DataFrame([row])], ignore_index=True)
    return df

def digitize_images(path):
    df = pd.DataFrame()
    folder = Path(path)
    for file in folder.glob("*.png"):
        try:
            match = re.search(r"(A[0-9]+.[0-9]+(-[0-9]+)?)", str(file))
            file_name = match.group(1)
        except:
            "Generate unique name if no A-number found"
            file_name = file.stem
        print(f"Processing file: {file_name}")
        df = insert_in_dataframe(df, file, file_name)
    return df

def main():
    "Set pwd to the folder containing the year folders"
    folder = "Data/Utanför Regionen/Från Region Öst/"
    #folder = "Data/Utanför Regionen/Till Region Öst/"
    #folder = "Data/Inom Regionen/"
    year = "2024"
    folder_path = folder + year
    df = digitize_images(folder_path)
    #outfile = folder+"Sammanställning_inom.xlsx"
    outfile = folder+"Sammanställning_utom_från.xlsx"
    #outfile = folder+"Sammanställning_utom_till.xlsx"
    with pd.ExcelWriter(outfile, mode='a', engine="openpyxl") as writer:  
        df.to_excel(writer,index =False, sheet_name=year)

if __name__ == "__main__": 
    main()