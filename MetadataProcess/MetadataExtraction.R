library(stringr)


##################################################################################################################################
################################################################### IMPORTING DATA ############################################### 
##################################################################################################################################


setwd("../MetadataProcess")

blocs <- read.csv("blocs.csv")
blocs <- data.frame(blocs)
data_extracted <- read.csv("preguntes.csv")
data_extracted <- data.frame(data_extracted)

##################################################################################################################################
################################################################### DATA STRUCTURES ############################################## 
##################################################################################################################################


metadata <- data.frame(NamesCOL = numeric(),
                       Eticol = numeric(),
                       Bloc = numeric(),
                       Nom_Bloc	= character(),
                       Inicial_Pregunta = character(),
                       Pregunta = character(),
                       Respostes = character(),
                       Columnes	= character(),
                       Rephrase	= character(),
                       Colcurt = character(),
                       Object	= character(),
                       PreguntaG= character(),
                       Tipus = character(),
                       PackIni = numeric(),
                       PackFi = numeric(),
                       nCols = numeric(),
                       nBlocs = numeric(),
                       TipusDescriptiva = character())	
                   
                   


diccionario <- list()
 
for (i in 1:nrow(blocs)) { 
  valor_fila <- as.character(blocs[i, ])
  diccionario[[valor_fila]] <- i
}  

tiposDesc <- c("Numerical", 
               "Nominal", "Ordinal", "Likert", 
               "NominalMV", 
               "NomxLikert", "LikertXt", "NominalxNominalXtemps", "NominalxNominal",
               "Open")

tiposNum <- 1
tiposRS <- c(2, 3, 4)
tiposLM <- 5
tiposGrid <- c(6, 7, 8, 9)
tiposOpen <- 10

                
dict_tipos <- list()
 
for (t in tiposDesc) { 
  id <- length(dict_tipos) + 1 
  dict_tipos[[as.character(id)]] <- t
}


##################################################################################################################################
############################################################### FUNCTIONS DEFINITION #############################################
##################################################################################################################################
 
getTipusDesc <- function(tipos, pregunta, respostes, columnes){ 
  respVect <- as.vector(unlist(respostes))
  
  cat("Pregunta: \033[1m", pregunta, "\033[0m\n") 
  cat("Respostes:", "\n")
  
  for (r in respVect) cat("   - \033[1m", r, "\033[0m\n")
  if (!is.null(columnes)) {
      cat("Columnes:", "\n")
      colVect <- as.vector(unlist(columnes))
      for (c in colVect) cat("   - \033[1m", c, "\033[0m\n")
  }
  
  cat("Select the number that represents the descriptive type: ", "\n")
  if (tipos == "Numerical" ) accepted_type <- tiposNum
  else if (tipos == "Simple Response") accepted_type <- tiposRS
  else if (tipos == "Multivalued List") accepted_type <- tiposLM
  else if (tipos == "Grid") accepted_type <- tiposGrid
  else  accepted_type <- tiposOpen
       
  for (num in accepted_type) { 
    if (num %in% names(dict_tipos))  cat(num, "- ", dict_tipos[[as.character(num)]], "\n")
  }
  
  return (accepted_type)
}

new_data_row <- function(dataframe, new_row) { 
  columnas_df <- colnames(dataframe)
  col_new_row <- colnames(new_row)
  col_to_set <- setdiff(columnas_df, col_new_row)
  for (col in col_to_set) new_row[[col]] <- NA
  dataframe <- rbind(dataframe, new_row)
  return(dataframe)
}


create_grid_resp_df <- function(initPreg, pregunta, pregReph, metadata, respVect, colVect, colCurt, respReph, namesCol){
    print(respReph)
    
    numNewRows <- max(length(respVect), length(colVect)) 
    
    for (i in 1:numNewRows) { 
      if (length(colVect) < length(respVect)){ 
          if (i <= length(colVect)){  
            new_row <- data.frame(Inicial_Pregunta = initPreg, Rephrase = respReph[i], Respostes = respVect[i],
                                     Columnes = colVect[i], Colcurt = colCurt[i], 
                                     Pregunta = paste0(pregunta, ' [', respVect[i] ,']'), 
                                     Object = "Modalitat", NamesCOL = namesCol)
          }
          else new_row <- data.frame(Inicial_Pregunta = initPreg, Rephrase = respReph[i], Respostes = respVect[i], 
                                      Pregunta = paste0(pregunta, ' [', respVect[i] ,']'), 
                                      Object = "Modalitat", NamesCOL = namesCol)
          namesCol <- namesCol + 1
      }
      else { 
        if (i <= length(respVect)){ 
          new_row <- data.frame(Inicial_Pregunta = initPreg, Rephrase = respReph[i], Respostes = respVect[i],
                                   Columnes = colVect[i], Colcurt = colCurt[i], 
                                   Pregunta = paste0(pregunta, ' [', respVect[i] ,']'), 
                                   Object = "Modalitat", NamesCOL = namesCol)
          namesCol <- namesCol + 1
        }
        else new_row <- data.frame(Columnes = colVect[i], Colcurt = colCurt[i], Object = "Modalitat")
      }
      metadata <- new_data_row(metadata, new_row) 
    }
    
  namesCol <<- namesCol
  return(metadata)
}

create_nogrid_resp_df <- function(pregunta, pregReph, metadata, respVect, respReph, namesCol){  
  numNewRows <- length(respVect)  
  
  for (i in 1:numNewRows) { 
    new_row <- data.frame(Rephrase = respReph[i], Respostes = respVect[i],   
                             Object = "Modalitat", Eticol = namesCol)
    metadata <- new_data_row(metadata, new_row) 
  } 
  
  namesCol <<- namesCol + 1
  return(metadata)
}

calculate_param <- function(tipos, modalitats){
    nCols <- "NA"
    if (tipos == "Numerical" ) nCols <- length(modalitats)
    else if (tipos == "Simple Response") nCols <- length(modalitats)
    else if (tipos == "Multivalued List") nCols <- length(modalitats)
    else if (tipos == "Grid") nCols <- length(modalitats)
    else nCols <- length(modalitats)
    return (nCols)
}


##################################################################################################################################
################################################################### MAIN CODE ####################################################
##################################################################################################################################


initial_order <- colnames(metadata)
actBloc <- -1
namesCol <- 2
k0 <- -1
kf <- -1

print(nrow(data_extracted))

if (nrow(data_extracted) != 0){
  for (i in 1:nrow(data_extracted)) {
        blocName <- data_extracted[i, "Numero.del.bloc"]
        numBloc <- diccionario[[blocName]]
        
        # blocName <- diccionario[[numBloc]]
        blocName <- data_extracted[i, "Numero.del.bloc"]
        
        
        if (numBloc != actBloc){
            new_row <- data.frame(Bloc = numBloc, Nom_Bloc = blocName, Object = "Bloc")
            metadata <- new_data_row(metadata, new_row)
            actBloc <- numBloc
        }
        
        initPreg <- data_extracted[i, "Numero.de.pregunta"]
        pregunta <- data_extracted[i, "Pregunta"] 
        pregReph <- data_extracted[i, "Pregunta.abreujada"]  
        tipos <- data_extracted[i, "Tipo.de.pregunta"] 
         
        
        if (tipos == "Grid") {
              respostes <-data_extracted[i, "Valores"] 
              columnes <- data_extracted[i, "Puntuaciones"] 
              respReph <- data_extracted[i, "Abreviación.de.valores"] 
              colCurt <- data_extracted[i, "Abreviación.de.puntuaciones"] 
              
              vector <- gsub("\\[|\\]", "", respostes)
              vector <- gsub("'", "", vector)
              respVect <- unlist(strsplit(vector, ", "))  
      
              vector2 <- gsub("\\[|\\]", "", columnes)
              vector2 <- gsub("'", "", vector2)
              colVect <- unlist(strsplit(vector2, ", ")) 
               
              vector3 <- gsub("\\[|\\]", "", respReph)
              vector3 <- gsub("'", "", vector3)
              respReph <- unlist(strsplit(vector3, ", ")) 
              
              vector4 <- gsub("\\[|\\]", "", colCurt)
              vector4 <- gsub("'", "", vector4)
              colCurt <- unlist(strsplit(vector4, ", ")) 
              
              tiposDescriptiva <- "a "
          
              nCols <- calculate_param(tipos, colVect) 
              k0 <- namesCol
              kf <- k0 + max(length(respVect), length(colVect))  
              
              new_row <- data.frame(Inicial_Pregunta = initPreg, Rephrase = paste0(initPreg, ' .', pregReph), 
                                       Pregunta = pregunta, Tipus = tipos, Object = "Qüestio", 
                                       PreguntaG = pregunta, nCols = nCols, TipusDescriptiva = tiposDescriptiva, PackIni = k0,
                                       PackFi = kf)
              
              metadata <- new_data_row(metadata, new_row) 
              new_row <- data.frame(Respostes = "Files", Columnes = "Columnes", Object = "Separador") 
              metadata <- new_data_row(metadata, new_row)
       
              metadata <- create_grid_resp_df(initPreg, pregunta, pregReph, metadata, respVect, colVect, colCurt, respReph, namesCol)
        }
        else if (tipos == "Numerical") { 
              respostes <-data_extracted[i, "Valores"]  
              respReph <- data_extracted[i, "Abreviación.de.valores"]  
              
              respVect <- paste(as.character(respostes), "-", as.character(respReph))
              
              tiposDescriptiva <- "b"
              
              new_row <- data.frame(Inicial_Pregunta = initPreg,  Rephrase = paste0(initPreg, '.', pregReph), 
                                    Pregunta = pregunta, Tipus = tipos, Object = "Qüestio", TipusDescriptiva = tiposDescriptiva,
                                    NamesCOL = namesCol)
              metadata <- new_data_row(metadata, new_row)
              
              metadata <- create_nogrid_resp_df(pregunta, pregReph, metadata, respVect, respReph, namesCol)
          
        }
        else if (tipos == "Open") {
              tiposDescriptiva <- "a " 
              
              new_row <- data.frame(Inicial_Pregunta = initPreg, Rephrase = paste0(initPreg, ' .', pregReph), 
                                    Pregunta = pregunta, Tipus = tipos, Object = "Qüestio", 
                                    PreguntaG = pregunta, TipusDescriptiva = tiposDescriptiva)
              
              metadata <- new_data_row(metadata, new_row)
        }
        else {
              new_row <- data.frame(Object="Separador")
              metadata <- new_data_row(metadata, new_row)
              
              respostes <-data_extracted[i, "Valores"]  
              respReph <- data_extracted[i, "Abreviación.de.valores"]  
              
              vector <- gsub("\\[|\\]", "", respostes)
              vector <- gsub("'", "", vector)
              respVect <- unlist(strsplit(vector, ", ")) 
              
              vector2 <- gsub("\\[|\\]", "", respReph)
              vector2 <- gsub("'", "", vector2)
              respReph <- unlist(strsplit(vector2, ", ")) 
              
              tiposDescriptiva <- "b"
          
              new_row <- data.frame(Inicial_Pregunta = initPreg,  Rephrase = paste0(initPreg, '.', pregReph), 
                                       Pregunta = pregunta, Tipus = tipos, Object = "Qüestio", TipusDescriptiva = tiposDescriptiva,
                                       NamesCOL = namesCol)
              metadata <- new_data_row(metadata, new_row)
               
              metadata <- create_nogrid_resp_df(pregunta, pregReph, metadata, respVect, respReph, namesCol)
        }
        
        
      }

}
metadata <- metadata[, initial_order] 

setwd("../csv_files")
nombre_archivo <- "MetaData_Obtained.csv" 
write.csv(metadata, file = nombre_archivo, row.names = FALSE)


