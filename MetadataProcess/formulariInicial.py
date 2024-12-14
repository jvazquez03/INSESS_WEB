import re
from google.oauth2 import service_account
from googleapiclient.discovery import build

import pandas as pd

import warnings
warnings.filterwarnings("ignore", category=FutureWarning, message="Pyarrow.*")

 
FORM_TITLE = 'AUTOMATIC FORM GENERATION USING GOOGLE FORMS API'

SCOPES = ['https://www.googleapis.com/auth/forms', 'https://www.googleapis.com/auth/drive.file']
DISCOVERY_DOC = "https://forms.googleapis.com/$discovery/rest?version=v1"
 
SERVICE_ACCOUNT_FILE = './MetadataProcess/formularitfg-1a9cc428ef00.json'

creds = service_account.Credentials.from_service_account_file(
    SERVICE_ACCOUNT_FILE,
    scopes=SCOPES
)
 
forms_service = build('forms', 'v1', credentials=creds)
 
form_body = {
    "info": {
        'title': FORM_TITLE
    }
}

created_form = forms_service.forms().create(body=form_body).execute() 
form_id = created_form["formId"] 
  

batch_update_request = {
    "requests": [ 
  ]
}

#######################################################################################################################
#######################################################################################################################
#######################################################################################################################

def create_new_section(blocName):
  batch_update_request["requests"].append({
    "createItem": {
        "item": { 
            "title": blocName,
            "pageBreakItem": {} 
        }
        ,"location": { "index": len(batch_update_request["requests"]), }
    }
  })

def create_new_question(preg, tipus, numericalType, respostes, columnes):

  if (tipus == "Simple Response"):
    questions = [] 
    for i in range(len(respostes)):
      row_question = {"value": respostes[i]} 
      questions.append(row_question)

    batch_update_request["requests"].append({
      "createItem": {
        "item": {
          "title": preg,
          "questionItem": {
            "question": {
              "choiceQuestion": {
                "options": questions,
                "type": "RADIO"
              }
            }
          }
        },
          "location": { "index": len(batch_update_request["requests"]), }
        }
    })
  
  elif (tipus == "Grid"):
    questions = []
    options_array = []

    for i in range(len(respostes)):
      row_question = {"rowQuestion": {"title": respostes[i]}}
      questions.append(row_question)
    
    for i in range(len(columnes)):
      row_question = {"value": columnes[i]}
      options_array.append(row_question)

    batch_update_request["requests"].append({
      "createItem": {
        "item": {
          "title": preg,
          "questionGroupItem": {
            "grid": {
              "columns": {
                "type": "RADIO",
                "options": options_array
              }
            },
            "questions": questions
          }
        },
        "location": { "index": len(batch_update_request["requests"]), }
      }
    })
  
  elif (tipus == "Numerical"): 
    if (numericalType):
      min = respostes[0]
      max = respostes[1]
      batch_update_request["requests"].append({
        "createItem": {
          "item": {
            "title": preg,
            "questionItem": {
              "question": {
                "scaleQuestion": {
                  "high": max,
                  "low": min
                }
              }
            }
          },
          "location": { "index": len(batch_update_request["requests"]), }
        }
      })
    else:
     batch_update_request["requests"].append({
      "createItem": {
        "item": {
          "title": preg,
          "questionItem": {
            "question": {
              "textQuestion": {
                "paragraph": False
              }
            }
          }
        },
        "location": { "index": len(batch_update_request["requests"]), }
      }
    })
  else:
    batch_update_request["requests"].append({
      "createItem": {
        "item": {
          "title": preg,
          "questionItem": {
            "question": {
              "textQuestion": {
                "paragraph": False
              }
            }
          }
        },
        "location": { "index": len(batch_update_request["requests"]), }
      }
    })


 
ruta_excel = './public/csv_files/MetaData_Obtained.csv'
 
data_frame = pd.read_csv(ruta_excel)
respostes = []
columnes = []
add_question = False
numericalType = False 
min = 0
max = 2

files = len(data_frame) 
if (files != 0):
  for indice, fila in data_frame.iterrows():    
      if (fila['Object'] == "Bloc"):  
        if (add_question): 
          if (len(respostes) == 2): numericalType = True
          else: numericalType = False 
          create_new_question(str(preg), str(tipus), numericalType, respostes, columnes)
          add_question = False
        create_new_section(str(fila['Nom_Bloc']))

      elif (fila['Object'] == "Qüestio"):  
        if (add_question): 
          if (len(respostes)==2): numericalType = True
          else: numericalType = False 
          create_new_question(str(preg), str(tipus), numericalType, respostes, columnes)

        preg = fila['Pregunta']
        tipus = fila['Tipus']
        packIni = fila['PackIni']
        packFi = fila['PackFi'] 
        respostes = []
        columnes = []  
        add_question = True

      elif (fila['Object'] == "Modalitat"):
        if (tipus == "Grid"): 
            if (not pd.isna(fila['Columnes'])): columnes.append(fila['Columnes']) 
            if (not pd.isna(fila['NamesCOL']) and fila['NamesCOL'] >= packIni and fila['NamesCOL'] <= packFi and not pd.isna(packIni)): 
              respostes.append(fila['Respostes'])  

        elif (tipus == "Simple Response"): 
          respostes.append(fila['Respostes'])  

        elif (tipus == "Numerical"): 
          respostes.append(fila['Respostes'])  

      if (indice == len(data_frame) - 1): 
        if (len(respostes) ==2): numericalType = True
        else: numericalType = False 
        create_new_question(str(preg), str(tipus), numericalType, respostes, columnes)


  #######################################################################################################################
  ####################################################################################################################### 
          
  forms_service.forms().batchUpdate(formId=form_id, body=batch_update_request).execute()
  form_url = f'https://docs.google.com/forms/d/{form_id}/viewform'
  print(f"Form created successfully with a new question! Form URL: {form_url}")

else:
    print("FORMULARIO VACIO")     